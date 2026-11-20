import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/brew_plan.dart';
import 'app_store.dart';

enum TimerStatus { ready, running, paused, finished }

/// 抽出タイマー。経過時間は時計の差分で数えるので、描画が遅れてもずれない。
class BrewTimer extends ChangeNotifier {
  BrewTimer(this.plan, {Clock? clock, this.onStepChanged, this.tickInterval = const Duration(milliseconds: 100)})
    : _clock = clock ?? DateTime.now;

  final BrewPlan plan;
  final Clock _clock;
  final Duration tickInterval;

  /// ステップが切り替わったとき（完了を含む）に呼ばれる。ハプティクス用
  final void Function(BrewProgress progress)? onStepChanged;

  TimerStatus _status = TimerStatus.ready;
  Duration _accumulated = Duration.zero;
  DateTime? _resumedAt;
  Timer? _ticker;
  int _lastStepIndex = 0;

  TimerStatus get status => _status;

  Duration get elapsed {
    final resumed = _resumedAt;
    final e = resumed == null ? _accumulated : _accumulated + _clock().difference(resumed);
    return e > plan.total ? plan.total : e;
  }

  BrewProgress get progress => plan.progressAt(elapsed);

  void start() {
    if (_status == TimerStatus.running || _status == TimerStatus.finished) return;
    _resumedAt = _clock();
    _status = TimerStatus.running;
    _ticker = Timer.periodic(tickInterval, (_) => tick());
    notifyListeners();
  }

  void pause() {
    if (_status != TimerStatus.running) return;
    _accumulated = elapsed;
    _resumedAt = null;
    _status = TimerStatus.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _accumulated = Duration.zero;
    _resumedAt = null;
    _lastStepIndex = 0;
    _status = TimerStatus.ready;
    notifyListeners();
  }

  /// 時間を進めて状態を更新する。通常は内部のタイマーから呼ばれる。
  @visibleForTesting
  void tick() {
    if (_status != TimerStatus.running) return;
    final p = progress;
    if (p.finished) {
      _accumulated = plan.total;
      _resumedAt = null;
      _ticker?.cancel();
      _status = TimerStatus.finished;
      onStepChanged?.call(p);
    } else if (p.stepIndex != _lastStepIndex) {
      onStepChanged?.call(p);
    }
    _lastStepIndex = p.stepIndex;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
