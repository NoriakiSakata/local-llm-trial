import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/brew_schedule.dart';

enum TimerStatus { ready, running, paused, finished }

/// 抽出タイマーの状態。
///
/// 経過時間は「一時停止までに溜まった時間 + 再開してからの時計の差分」で求める。
/// 周期タイマーは画面更新のきっかけにすぎないため、アプリがバックグラウンドで
/// タイマーが止まっても、戻ってきたときに正しい経過時間に追いつく。
class BrewTimerController extends ChangeNotifier {
  BrewTimerController({
    required this.schedule,
    required this._clock,
    this.onStepChanged,
    this.onFinished,
    this.tickInterval = const Duration(milliseconds: 100),
  });

  final BrewSchedule schedule;
  final Duration Function() _clock;
  final VoidCallback? onStepChanged;
  final VoidCallback? onFinished;
  final Duration tickInterval;

  TimerStatus _status = TimerStatus.ready;
  Duration _accumulated = Duration.zero;
  Duration? _runningSince;
  Timer? _ticker;
  late BrewPosition _position = schedule.positionAt(Duration.zero);

  TimerStatus get status => _status;
  BrewPosition get position => _position;
  BrewStep get currentStep => schedule.steps[_position.stepIndex];
  BrewStep? get nextStep => _position.stepIndex + 1 < schedule.steps.length
      ? schedule.steps[_position.stepIndex + 1]
      : null;

  Duration get elapsed {
    final since = _runningSince;
    final running = since == null ? Duration.zero : _clock() - since;
    final value = _accumulated + running;
    return value > schedule.total ? schedule.total : value;
  }

  /// 抽出全体の進捗（0.0〜1.0）
  double get overallProgress =>
      elapsed.inMicroseconds / schedule.total.inMicroseconds;

  void start() {
    if (_status == TimerStatus.running || _status == TimerStatus.finished) {
      return;
    }
    _runningSince = _clock();
    _status = TimerStatus.running;
    _ticker?.cancel();
    _ticker = Timer.periodic(tickInterval, (_) => tick());
    notifyListeners();
  }

  void pause() {
    if (_status != TimerStatus.running) return;
    _accumulated = elapsed;
    _runningSince = null;
    _ticker?.cancel();
    _status = TimerStatus.paused;
    tick();
    notifyListeners();
  }

  void toggle() => _status == TimerStatus.running ? pause() : start();

  void reset() {
    _ticker?.cancel();
    _accumulated = Duration.zero;
    _runningSince = null;
    _status = TimerStatus.ready;
    _position = schedule.positionAt(Duration.zero);
    notifyListeners();
  }

  /// 経過時間から位置を再計算する。周期タイマーから呼ばれる（テストからも直接呼べる）。
  @visibleForTesting
  void tick() {
    final previous = _position;
    final next = schedule.positionAt(elapsed);
    _position = next;

    if (next.isFinished && _status == TimerStatus.running) {
      _accumulated = schedule.total;
      _runningSince = null;
      _ticker?.cancel();
      _status = TimerStatus.finished;
      onFinished?.call();
    } else if (next.stepIndex != previous.stepIndex) {
      onStepChanged?.call();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
