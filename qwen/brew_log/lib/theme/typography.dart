import 'package:flutter/material.dart';

/// タイポグラフィの階層を明示的に定義する。
///
/// M3 の規格サイズを基準にしつつ、日本語本文は行送りを広めに取って可読性を確保した。
/// フォントファミリーは指定しない（=各プラットフォームのシステムフォントを使用）。
/// CJK フォントを同梱するとアプリが数MB重くなるため、ここでは同梱を見送り、
/// 数字のみ tabular figures を要求して桁位置を固定している。
abstract final class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final Color primary = brightness == Brightness.dark
        ? const Color(0xFFF3E7DA)
        : const Color(0xFF1E1611);
    final Color secondary = brightness == Brightness.dark
        ? const Color(0xFFCBB9A6)
        : const Color(0xFF4F443A);

    TextStyle ts(
      double size,
      FontWeight weight, {
      double? spacing,
      double height = 1.5,
      Color? color,
    }) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: spacing,
        height: height,
        color: color ?? primary,
      );
    }

    // 見出し系は文字詰め、本文は詰めない（日本語では詰めすぎると読みにくい）。
    return TextTheme(
          displayLarge: ts(57, FontWeight.w400, spacing: -0.25, height: 1.12),
          displayMedium: ts(45, FontWeight.w400, spacing: -0.2, height: 1.16),
          displaySmall: ts(36, FontWeight.w400, spacing: 0, height: 1.2),
          headlineLarge: ts(32, FontWeight.w400, spacing: -0.15, height: 1.25),
          headlineMedium: ts(28, FontWeight.w400, spacing: 0, height: 1.29),
          headlineSmall: ts(24, FontWeight.w400, spacing: 0, height: 1.33),
          titleLarge: ts(21, FontWeight.w500, spacing: 0.1, height: 1.3),
          titleMedium: ts(16, FontWeight.w500, spacing: 0.15, height: 1.4),
          titleSmall: ts(14, FontWeight.w500, spacing: 0.1, height: 1.45),
          bodyLarge: ts(16, FontWeight.w400, spacing: 0.15, height: 1.6),
          bodyMedium: ts(14, FontWeight.w400, spacing: 0.2, height: 1.65),
          bodySmall: ts(12.5, FontWeight.w400, spacing: 0.25, height: 1.55),
          labelLarge: ts(14, FontWeight.w500, spacing: 0.1, height: 1.2),
          labelMedium: ts(12, FontWeight.w500, spacing: 0.4, height: 1.25),
          labelSmall: ts(11, FontWeight.w500, spacing: 0.5, height: 1.25),
        )
        .apply(bodyColor: primary, displayColor: primary)
        .copyWith(
          // 補助文言はミューテッドカラーに落とす（コントラストは WCAG AA を満たす値选用）。
          bodySmall: ts(
            12.5,
            FontWeight.w400,
            spacing: 0.25,
            height: 1.55,
            color: secondary,
          ),
          labelMedium: ts(
            12,
            FontWeight.w500,
            spacing: 0.4,
            height: 1.25,
            color: secondary,
          ),
        );
  }

  /// 数字を等幅に揃える。タイマーや計量値で桁が揺れないようにする。
  static TextStyle numeric(TextStyle base) {
    return base.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: (base.letterSpacing ?? 0) - 0.01,
    );
  }

  /// 数値本体（タイマーの残り時間など）。
  static TextStyle timer(TextTheme text) {
    return numeric(
      text.displayLarge!.copyWith(fontSize: 68, fontWeight: FontWeight.w300),
    );
  }

  /// 画面が小さいとき用のタイマー数値。
  static TextStyle timerCompact(TextTheme text) {
    return numeric(
      text.displayMedium!.copyWith(fontSize: 52, fontWeight: FontWeight.w300),
    );
  }

  /// 計量値（g / ml / ℃）。
  static TextStyle metric(TextTheme text) {
    return numeric(text.headlineMedium!.copyWith(fontWeight: FontWeight.w400));
  }
}

/// 画面幅に応じてタイマーの数字サイズ切り替えに使う閾値。
abstract final class AppLayout {
  /// この幅未満ならタイマー数字を縮める。
  static const double compactTimerBreakpoint = 380;
}
