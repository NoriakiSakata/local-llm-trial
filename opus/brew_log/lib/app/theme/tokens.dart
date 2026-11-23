import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// 余白のスケール。4dp グリッドを基準に、画面ごとの場当たり的な値を禁止する。
abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// 画面の左右余白。360dp 幅でも本文幅を 328dp 確保できる値。
  static const double screen = lg;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screen,
  );
}

/// 角丸のスケール。小さい部品ほど小さく、面が大きいほど丸くする。
abstract final class AppRadius {
  /// 入力欄・チップ・小さなバッジ
  static const double sm = 8;

  /// カード・リスト項目
  static const double md = 16;

  /// ダイアログ・ボトムシート・大きな面
  static const double lg = 28;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

/// elevation のルール。影ではなく surfaceContainer のトーン差で面を区別する。
abstract final class AppElevation {
  /// 通常の面（カード・AppBar・ナビゲーション）
  static const double flat = 0;

  /// スクロール時の AppBar・浮いている FAB
  static const double raised = 2;

  /// ダイアログ・メニュー
  static const double overlay = 3;
}

/// アニメーションの長さとカーブ。「控えめ」を担保するため長くても 400ms。
abstract final class AppMotion {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration long = Duration(milliseconds: 400);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}

/// 部品サイズ
abstract final class AppSize {
  static const double buttonHeight = 52;
  static const double iconBadge = 40;
  static const double timerRing = 260;
  static const double timerRingStroke = 10;
  static const double contentMaxWidth = 560;
}
