import 'package:material_ui/material_ui.dart';

/// 余白。4 の倍数だけを使う。
abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// 画面の左右の余白
  static const page = EdgeInsets.symmetric(horizontal: md);
}

/// 角丸。部品の大きさで3段階に分ける。
abstract final class Corner {
  /// チップ・入力欄など小さい部品
  static const sm = 8.0;

  /// カード・リストのまとまり
  static const md = 16.0;

  /// シート・ダイアログ・タイマーの円盤
  static const lg = 28.0;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

/// 影は基本使わず、面の色の差（surfaceContainer*）で階層を出す。
abstract final class Elevation {
  static const flat = 0.0;

  /// 浮いている操作（FAB など）だけ
  static const raised = 3.0;
}

abstract final class Motion {
  static const short = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 280);
  static const curve = Curves.easeOutCubic;
}
