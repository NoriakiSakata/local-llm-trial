import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// 焙煎の進んだ豆の表面に近い、赤みのある焦げ茶。
/// 彩度を抑えた茶系は M3 のトーン計算でも濁りにくく、ライト／ダークの両方で落ち着いた面の色になる。
const seedColor = Color(0xFF7B4B2A);

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.content,
    );
    final base = ThemeData(colorScheme: scheme, brightness: brightness);
    final text = _textTheme(base.textTheme, scheme);

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: Elevation.flat,
        scrolledUnderElevation: Elevation.flat,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        elevation: Elevation.flat,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: Elevation.flat,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: Corner.all(Corner.md)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
        shape: RoundedRectangleBorder(borderRadius: Corner.all(Corner.md)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: Corner.all(Corner.sm), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: Corner.all(Corner.sm),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: Corner.all(Corner.md)),
          textStyle: text.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: Corner.all(Corner.md)),
          textStyle: text.titleMedium,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: Elevation.raised,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: Corner.all(Corner.md)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: Corner.all(Corner.sm)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: Corner.all(Corner.lg)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: Corner.all(Corner.sm)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }

  /// 文字の階層。システムフォントのまま、太さと字間で差をつける。
  ///  - display*: タイマーの数字・大きな集計値
  ///  - headline*: 画面内の主役になる値（目標湯量など）
  ///  - title*: 画面タイトル・カード見出し
  ///  - body*: 本文・説明
  ///  - label*: ボタン・補足・単位
  static TextTheme _textTheme(TextTheme t, ColorScheme scheme) => t.copyWith(
    displayLarge: t.displayLarge?.copyWith(fontWeight: FontWeight.w300, letterSpacing: -1.5),
    displayMedium: t.displayMedium?.copyWith(fontWeight: FontWeight.w300, letterSpacing: -0.5),
    displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w400),
    headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
    headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
    titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    labelSmall: t.labelSmall?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0.4),
  );
}

/// 数字の幅をそろえる（タイマー・湯量が動いても横にぶれない）
const tabularFigures = [FontFeature.tabularFigures()];

extension NumericStyle on TextStyle {
  TextStyle get tabular => copyWith(fontFeatures: tabularFigures);
}
