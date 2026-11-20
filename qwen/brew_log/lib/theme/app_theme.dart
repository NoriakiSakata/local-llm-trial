import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

/// Brew Log のテーマ。
///
/// 基本方針は「M3 のシードカラーから調色し、表面はトーン（濃度）で階層化する」。
/// 影をほとんど使わず、surfaceContainer の濃淡で立体を出すことで、
/// サンプルアプリ風の“浮いたカード”感を消している。
abstract final class AppTheme {
  /// シードカラー：中煎り豆の表面色。
  /// 珈琲そのものを連想させる彩度の低い茶色を選び、
  /// 派手さを抑えて常時表示しても疲れないUIを狙った（詳細は README）。
  static const Color seedColor = Color(0xFF6F4E37);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = _scheme(brightness);
    final TextTheme text = AppTypography.textTheme(brightness);

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: AppElevation.flat,
        scrolledUnderElevation: AppElevation.flat,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),

      cardTheme: CardThemeData(
        elevation: AppElevation.flat,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        clipBehavior: Clip.antiAlias,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: AppSize.navBarHeight,
        elevation: AppElevation.flat,
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: AppSize.iconMedium,
            color: selected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return text.labelMedium!.copyWith(
            color: selected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppElevation.flat,
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.chipRadius),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: AppElevation.flat,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetRadius),
        clipBehavior: Clip.antiAlias,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        actionTextColor: scheme.inversePrimary,
        elevation: AppElevation.flat,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.chipRadius),
        contentTextStyle: text.bodyMedium!.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        hintStyle: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: text.bodySmall,
        counterStyle: text.bodySmall,
        prefixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle?>(text.labelLarge),
          iconSize: const WidgetStatePropertyAll<double>(AppSize.iconSmall),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.secondaryContainer,
        labelStyle: text.labelLarge!.copyWith(color: scheme.onSurfaceVariant),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.chipRadius),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 6,
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
        valueIndicatorColor: scheme.inverseSurface,
        valueIndicatorTextStyle: text.labelMedium!.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 6,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),

      navigationDrawerTheme: NavigationDrawerThemeData(
        elevation: AppElevation.flat,
        backgroundColor: scheme.surfaceContainer,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface.withValues(alpha: 0.92),
          borderRadius: AppRadius.chipRadius,
        ),
        textStyle: text.bodySmall!.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }

  /// シードから生成した scheme に、ウォームニュートラルの階層を明示的に当てはめる。
  ///
  /// 既定の neutral は無彩色に近いため、そのままだと「珈琲」の温度感が落ちる。
  /// 表面だけ意図的にベージュ寄りのランプへ差し替えている。
  ///
  /// tertiary も差し替えている理由: シードが茶色だと M3 の調色は三次的特徴色を
  /// オリーブ寄りに作る。評価の★や「今日」の棒グラフに使うと抹茶のような印象に
  /// なってしまうため、焙煎した砂糖を連想させる琥珀色に固定した。
  static ColorScheme _scheme(Brightness brightness) {
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    if (brightness == Brightness.light) {
      return base.copyWith(
        surface: const Color(0xFFFBF7F1),
        onSurface: const Color(0xFF1E1611),
        surfaceDim: const Color(0xFFE9E1D7),
        surfaceBright: const Color(0xFFFDF9F3),
        surfaceContainerLowest: const Color(0xFFFFFDFA),
        surfaceContainerLow: const Color(0xFFF6F0E8),
        surfaceContainer: const Color(0xFFF1EAE1),
        surfaceContainerHigh: const Color(0xFFEBE2D7),
        surfaceContainerHighest: const Color(0xFFE4DBCE),
        onSurfaceVariant: const Color(0xFF4F443A),
        outline: const Color(0xFF82756A),
        outlineVariant: const Color(0xFFD8CBBC),
        tertiary: const Color(0xFF7A4E14),
        tertiaryContainer: const Color(0xFFF7DFB8),
        onTertiaryContainer: const Color(0xFF3A2600),
      );
    }

    return base.copyWith(
      surface: const Color(0xFF17110D),
      onSurface: const Color(0xFFEFE3D6),
      surfaceDim: const Color(0xFF110C09),
      surfaceBright: const Color(0xFF3E352D),
      surfaceContainerLowest: const Color(0xFF0D0805),
      surfaceContainerLow: const Color(0xFF1F1813),
      surfaceContainer: const Color(0xFF241C17),
      surfaceContainerHigh: const Color(0xFF2F2720),
      surfaceContainerHighest: const Color(0xFF3A312A),
      onSurfaceVariant: const Color(0xFFCBB9A6),
      outline: const Color(0xFF9B8B7B),
      outlineVariant: const Color(0xFF4D423A),
      tertiary: const Color(0xFFE9B96B),
      tertiaryContainer: const Color(0xFF5C4112),
      onTertiaryContainer: const Color(0xFFFADFBB),
    );
  }
}
