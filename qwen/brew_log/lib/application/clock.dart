/// 時間を測るための薄い抽象。
///
/// テストで fake な時刻を差し込めるようにするためだけで、
/// 実行時は [DateTime.now] を使う。
abstract interface class BrewClock {
  DateTime now();

  int nowMs();
}

final class SystemBrewClock implements BrewClock {
  const SystemBrewClock();

  @override
  DateTime now() => DateTime.now();

  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}

/// 手動で進められる時計。unit test とスクリーンショット生成用のエントリポイントで使う。
final class ManualBrewClock implements BrewClock {
  ManualBrewClock([DateTime? start]) : _now = start ?? DateTime(2026, 1, 1, 9);

  DateTime _now;

  void advance(Duration delta) => _now = _now.add(delta);

  void setTo(DateTime value) => _now = value;

  @override
  DateTime now() => _now;

  @override
  int nowMs() => _now.millisecondsSinceEpoch;
}
