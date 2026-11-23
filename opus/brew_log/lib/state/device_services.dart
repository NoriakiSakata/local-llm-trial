import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// 端末機能へのアクセスをまとめた抽象。テストでは記録用の実装に差し替える。
abstract interface class DeviceServices {
  /// 単調増加する時計。抽出タイマーの経過時間計測に使う。
  Duration now();

  /// ステップが切り替わったとき
  void stepChanged();

  /// 抽出が終わったとき
  void finished();

  /// 画面スリープを抑止する／解除する
  Future<void> keepScreenOn(bool enabled);
}

class PlatformDeviceServices implements DeviceServices {
  const PlatformDeviceServices();

  static final Stopwatch _clock = Stopwatch()..start();

  @override
  Duration now() => _clock.elapsed;

  @override
  void stepChanged() => HapticFeedback.mediumImpact();

  @override
  void finished() => HapticFeedback.heavyImpact();

  @override
  Future<void> keepScreenOn(bool enabled) async {
    try {
      await WakelockPlus.toggle(enable: enabled);
    } on Object {
      // スリープ抑止はベストエフォート。失敗してもタイマーは動かし続ける。
    }
  }
}
