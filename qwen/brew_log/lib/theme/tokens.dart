/// デザイントークン（余白・角丸・時間・サイズ）。
///
/// 画面側で直値を書かないための集約場所。ここで統一することで、
/// 画面ごとの場当たり的なspacing/radiusのバラつきを防ぐ。
library;

import 'package:flutter/widgets.dart';

/// 間隔は 4dp ベースのスケールのみを許容する。
abstract final class AppSpacing {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// 画面左右の既定マージン。幅360dpでも詰まらない値にしてある。
  static const double screen = 20;

  /// リスト内の行間。
  static const double listGap = 12;
}

/// 角丸のスケール。
abstract final class AppRadius {
  static const double chip = 12;
  static const double field = 14;
  static const double button = 16;
  static const double card = 20;
  static const double sheet = 28;

  static final BorderRadius chipRadius = BorderRadius.circular(chip);
  static final BorderRadius fieldRadius = BorderRadius.circular(field);
  static final BorderRadius buttonRadius = BorderRadius.circular(button);
  static final BorderRadius cardRadius = BorderRadius.circular(card);
  static final BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// モーションの時間スケール。
///
/// 「控えめなアニメーション」を意図するため、最長でも360msまでに留める。
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 360);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeOutQuint;
}

/// アイコン・アバターなどのサイズ規定。
abstract final class AppSize {
  static const double iconSmall = 18;
  static const double iconMedium = 24;
  static const double iconLarge = 32;

  /// タイマーの数字。幅360dpで5文字（`00:00`）が収まる上限寄りの値。
  static const double timerDigits = 68;

  /// 空状態のイラスト。
  static const double emptyArt = 132;

  /// NavigationBar の高さ（M3の推奨値）。
  static const double navBarHeight = 72;
}

/// elevation は影ではなくトーン（surfaceContainer の濃度）で表現する方針なので、
/// 実値は 0 と 1 の2段階だけを使う。
abstract final class AppElevation {
  static const double flat = 0;
  static const double raised = 1;
}
