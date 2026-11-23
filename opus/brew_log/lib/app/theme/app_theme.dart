import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// アプリ全体のテーマ定義。
///
/// 画面側では色・文字・角丸を直接指定せず、ここで決めたルールを
/// `Theme.of(context)` と `tokens.dart` の定数経由で参照する。
abstract final class AppTheme {
  /// シードカラー「Coffee」(#6F4E37)。中深煎りの豆の色。
  ///
  /// `DynamicSchemeVariant.content` で展開すると、シード色そのものが
  /// primaryContainer に入り、primary はエスプレッソ色（ライト）／
  /// ラテ色（ダーク）になる。tonalSpot よりオレンジ味が抑えられ、落ち着く。
  static const Color seed = Color(0xFF6F4E37);

  /// アクセント「Crema」(#C9A063)。エスプレッソのクレマの金色。
  /// 自動生成の tertiary はオリーブ寄りで珈琲らしくないため、
  /// 評価の星や「今日」の強調に使う tertiary をこの色で置き換える。
  static const Color crema = Color(0xFFC9A063);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ColorScheme scheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.content,
    );
    final accent = ColorScheme.fromSeed(
      seedColor: crema,
      brightness: brightness,
    );
    return base.copyWith(
      tertiary: accent.primary,
      onTertiary: accent.onPrimary,
      tertiaryContainer: accent.primaryContainer,
      onTertiaryContainer: accent.onPrimaryContainer,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final scheme = AppTheme.scheme(brightness);
    final textTheme = _textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      // Android は控えめなフェード＋スライド。iOS は指定しないことで
      // スワイプで戻れる Cupertino 標準の遷移になる。
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.flat,
        scrolledUnderElevation: AppElevation.raised,
        centerTitle: false,
        titleSpacing: AppSpace.screen,
      ),
      cardTheme: CardThemeData(
        elevation: AppElevation.flat,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: AppElevation.flat,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        surfaceTintColor: Colors.transparent,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSize.buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSize.buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: AppElevation.raised,
        focusElevation: AppElevation.raised,
        hoverElevation: AppElevation.overlay,
        highlightElevation: AppElevation.overlay,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      // ボタン・チップの文字は既定で textTheme.labelLarge（このテーマの太さ）を使う。
      // 色を持たない TextStyle をテーマに渡すと配色が崩れるため、ここでは指定しない。
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        side: BorderSide(color: scheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      ),
      // ボタン・チップの文字は既定で labelLarge（このテーマの太さ）を使うため、
      // ここでは色の付かない TextStyle を渡さない（渡すと配色が崩れる）。
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        titleTextStyle: textTheme.titleMedium!.copyWith(
          color: scheme.onSurface,
        ),
        subtitleTextStyle: textTheme.bodyMedium!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: AppElevation.overlay,
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        titleTextStyle: textTheme.headlineSmall!.copyWith(
          color: scheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium!.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: AppSpace.xl,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// サイズは M3 既定（日本語ロケールでは tall ジオメトリ）に任せ、
  /// 太さ・字間・行間だけで階層を付ける。
  static const TextTheme _textTheme = TextTheme(
    // タイマーの数字専用。細く大きく、等幅数字で桁が揺れない。
    displayLarge: TextStyle(
      fontWeight: FontWeight.w300,
      fontFeatures: _tabular,
      letterSpacing: -1.0,
    ),
    // 振り返りの主要な数値
    displayMedium: TextStyle(
      fontWeight: FontWeight.w400,
      fontFeatures: _tabular,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      fontWeight: FontWeight.w400,
      fontFeatures: _tabular,
    ),
    // タイマーの目標湯量・空状態の見出し
    headlineLarge: TextStyle(
      fontWeight: FontWeight.w500,
      fontFeatures: _tabular,
    ),
    headlineMedium: TextStyle(fontWeight: FontWeight.w500),
    headlineSmall: TextStyle(fontWeight: FontWeight.w500),
    // 画面タイトル
    titleLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
    // カード・リスト項目の見出し
    titleMedium: TextStyle(fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontWeight: FontWeight.w600),
    // 本文。日本語は行間を広めに。
    bodyLarge: TextStyle(height: 1.6),
    bodyMedium: TextStyle(height: 1.55),
    bodySmall: TextStyle(height: 1.5),
    // ボタン・数値ラベル
    labelLarge: TextStyle(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      fontFeatures: _tabular,
    ),
    labelMedium: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.4),
    // セクション見出しのオーバーライン
    labelSmall: TextStyle(
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      fontFeatures: _tabular,
    ),
  );
}
