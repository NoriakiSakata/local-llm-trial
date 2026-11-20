import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/models.dart';
import 'brew_plan.dart';
import 'clock.dart';
import 'providers.dart';

enum BrewPhase { running, paused, finished }

/// 実行中の抽出セッション。
final class BrewSession {
  const BrewSession({
    required this.recipe,
    required this.plan,
    required this.phase,
    required this.elapsedMs,
    required this.marks,
    required this.startedAt,
  });

  final Recipe recipe;
  final BrewPlan plan;
  final BrewPhase phase;

  /// 停止時間を除いた経過ミリ秒。
  final int elapsedMs;

  /// ステップが切り替わった時点で積んだ実測ログ。
  final List<PourLog> marks;

  final DateTime startedAt;

  bool get isFinished => phase == BrewPhase.finished;

  int get currentIndex => plan.indexAt(elapsedMs);

  BrewStep get currentStep => plan.steps[currentIndex];

  int get remainingMs => plan.remainingMs(currentIndex, elapsedMs);

  Duration get remaining => Duration(milliseconds: remainingMs);

  Duration get remainingTotal =>
      Duration(milliseconds: isFinished ? 0 : plan.totalMs - elapsedMs);

  /// 目標累計湯量（現在のステップの終わり時点）。
  int get targetCumMl => currentStep.targetCumMl;

  /// 現時点で注ぐべき下限の湯量（前ステップまでの累計）。
  int get pouredSoFarTarget =>
      currentIndex == 0 ? 0 : plan.steps[currentIndex - 1].targetCumMl;

  /// 全体の進行度 0〜1。
  double get progress =>
      plan.totalMs == 0 ? 1 : (elapsedMs / plan.totalMs).clamp(0.0, 1.0);

  BrewSession copyWith({
    BrewPhase? phase,
    int? elapsedMs,
    List<PourLog>? marks,
  }) {
    return BrewSession(
      recipe: recipe,
      plan: plan,
      phase: phase ?? this.phase,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      marks: marks ?? this.marks,
      startedAt: startedAt,
    );
  }
}

/// タイマーの進行を管理する。`null` は「淹れていない」状態。
///
/// 進め方はシンプルで、[Timer.periodic] が [BrewClock] を読みに行って
/// 経過時間を再計算するだけ。ステップ番号は常に経過時間から決まる
/// 純粋関数なので、リビルドや再起動でズレない。
class BrewSessionNotifier extends Notifier<BrewSession?> {
  static const Duration tickInterval = Duration(milliseconds: 200);

  Timer? _timer;
  int _anchorMs = 0;
  int _accumulatedMs = 0;

  BrewClock get _clock => ref.read(clockProvider);

  @override
  BrewSession? build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
      _setWakeLock(false);
    });
    return null;
  }

  void start(Recipe recipe) {
    _stopTicking();
    _accumulatedMs = 0;
    _anchorMs = _clock.nowMs();
    final BrewPlan plan = BrewPlan.from(recipe);
    state = BrewSession(
      recipe: recipe,
      plan: plan,
      phase: BrewPhase.running,
      elapsedMs: 0,
      marks: <PourLog>[
        PourLog(
          label: plan.steps.first.label,
          targetCumMl: plan.steps.first.targetCumMl,
          elapsedMs: 0,
        ),
      ],
      startedAt: _clock.now(),
    );
    _setWakeLock(true);
    _startTicking();
  }

  void pause() {
    final BrewSession? current = state;
    if (current == null || current.phase != BrewPhase.running) return;
    _accumulate();
    _stopTicking();
    state = current.copyWith(
      phase: BrewPhase.paused,
      elapsedMs: _accumulatedMs,
    );
  }

  void resume() {
    final BrewSession? current = state;
    if (current == null || current.phase != BrewPhase.paused) return;
    _anchorMs = _clock.nowMs();
    state = current.copyWith(phase: BrewPhase.running);
    _setWakeLock(true);
    _startTicking();
  }

  /// 同じレシピで最初からやり直す。
  void restart() {
    final BrewSession? current = state;
    if (current == null) return;
    start(current.recipe);
  }

  /// 取り消してidleに戻す。
  void discard() {
    _stopTicking();
    _setWakeLock(false);
    state = null;
  }

  /// 手動で完了。残りステップを全部マークして終了扱う。
  void finishManually() {
    final BrewSession? current = state;
    if (current == null || current.isFinished) return;
    _accumulate();
    _stopTicking();
    _setWakeLock(false);
    state = current.copyWith(
      phase: BrewPhase.finished,
      elapsedMs: current.plan.totalMs,
      marks: _marksFor(current.plan, current.plan.totalMs, base: current.marks),
    );
  }

  /// 評価保存後に呼び、セッションを閉じる。
  void completeAndClear() {
    _stopTicking();
    _setWakeLock(false);
    state = null;
  }

  void _startTicking() {
    _timer ??= Timer.periodic(tickInterval, (_) => tick());
  }

  void _stopTicking() {
    _timer?.cancel();
    _timer = null;
  }

  void _accumulate() {
    _accumulatedMs += _clock.nowMs() - _anchorMs;
    _anchorMs = _clock.nowMs();
  }

  /// テストから直接叩ける1ティック。
  void tick() {
    final BrewSession? current = state;
    if (current == null || current.phase != BrewPhase.running) return;

    final int elapsed = _accumulatedMs + (_clock.nowMs() - _anchorMs);
    if (elapsed >= current.plan.totalMs) {
      _stopTicking();
      _setWakeLock(false);
      state = current.copyWith(
        phase: BrewPhase.finished,
        elapsedMs: current.plan.totalMs,
        marks: _marksFor(
          current.plan,
          current.plan.totalMs,
          base: current.marks,
        ),
      );
      _chime(strong: true);
      return;
    }

    final int index = current.plan.indexAt(elapsed);
    final int known = current.marks.length;
    if (index + 1 > known) {
      state = current.copyWith(
        elapsedMs: elapsed,
        marks: _marksFor(current.plan, elapsed, base: current.marks),
      );
      _chime(strong: current.plan.steps[index].isBloom == false);
    } else {
      state = current.copyWith(elapsedMs: elapsed);
    }
  }

  List<PourLog> _marksFor(
    BrewPlan plan,
    int elapsedMs, {
    required List<PourLog> base,
  }) {
    final int index = plan.indexAt(elapsedMs);
    if (base.length > index) return base;
    final List<PourLog> marks = List<PourLog>.of(base);
    for (int i = marks.length; i <= index; i++) {
      final BrewStep step = plan.steps[i];
      marks.add(
        PourLog(
          label: step.label,
          targetCumMl: step.targetCumMl,
          elapsedMs: i == 0 ? 0 : elapsedMs,
        ),
      );
    }
    return marks;
  }

  void _chime({required bool strong}) {
    // ハプティクス非対応（デスクトップ実行・テスト）でも失敗を表面化させない。
    unawaited(
      (strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick())
          .catchError((Object _) {}),
    );
  }

  void _setWakeLock(bool enable) {
    unawaited(WakelockPlus.toggle(enable: enable).catchError((Object _) {}));
  }
}
