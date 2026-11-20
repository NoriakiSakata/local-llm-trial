import 'dart:math' as math;

import 'package:brew_log/theme/app_theme.dart';
import 'package:brew_log/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// コントラスト比（WCAG 2.1 の相対輝度ベース）。
double contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('ライトテーマのコントラスト', () {
    final scheme = AppTheme.light().colorScheme;

    test('本文・見出し文字は surface 上で 7:1 以上', () {
      expect(contrast(scheme.onSurface, scheme.surface), greaterThan(7));
      expect(
        contrast(scheme.onSurface, scheme.surfaceContainerLow),
        greaterThan(7),
      );
      expect(
        contrast(scheme.onSurface, scheme.surfaceContainerHighest),
        greaterThan(7),
      );
    });

    test('補助文字は 4.5:1 以上', () {
      expect(
        contrast(scheme.onSurfaceVariant, scheme.surface),
        greaterThan(4.5),
      );
      expect(
        contrast(scheme.onSurfaceVariant, scheme.surfaceContainer),
        greaterThan(4.5),
      );
    });

    test('ボタン類の前景色は 4.5:1 以上', () {
      expect(contrast(scheme.onPrimary, scheme.primary), greaterThan(4.5));
      expect(
        contrast(scheme.onPrimaryContainer, scheme.primaryContainer),
        greaterThan(4.5),
      );
      expect(
        contrast(scheme.onSecondaryContainer, scheme.secondaryContainer),
        greaterThan(4.5),
      );
      expect(
        contrast(scheme.onErrorContainer, scheme.errorContainer),
        greaterThan(4.5),
      );
    });

    test('琥珀色の tertiary（★と今日のバー）も読める', () {
      expect(contrast(scheme.tertiary, scheme.surface), greaterThan(4.5));
      expect(
        contrast(scheme.onTertiaryContainer, scheme.tertiaryContainer),
        greaterThan(4.5),
      );
      // M3 の既定調色は茶シードだとオリーブ寄りの tertiary になる。
      // 意図的に琥珀へ差し替えていることの証跡として固定値で見る。
      expect(scheme.tertiary, isNot(const Color(0xFF5F6135)));
    });
  });

  group('ダークテーマのコントラスト', () {
    final scheme = AppTheme.dark().colorScheme;

    test('本文・見出し文字は surface 上で 7:1 以上', () {
      expect(contrast(scheme.onSurface, scheme.surface), greaterThan(7));
      expect(
        contrast(scheme.onSurface, scheme.surfaceContainerHigh),
        greaterThan(7),
      );
    });

    test('補助文字は 4.5:1 以上', () {
      expect(
        contrast(scheme.onSurfaceVariant, scheme.surface),
        greaterThan(4.5),
      );
      expect(
        contrast(scheme.onSurfaceVariant, scheme.surfaceContainerLow),
        greaterThan(4.5),
      );
    });

    test('ボタン類の前景色は 4.5:1 以上', () {
      expect(contrast(scheme.onPrimary, scheme.primary), greaterThan(4.5));
      expect(
        contrast(scheme.onSecondaryContainer, scheme.secondaryContainer),
        greaterThan(4.5),
      );
    });

    test('ダークでも tertiary は琥珀（オリーブの既定値ではない）', () {
      expect(contrast(scheme.tertiary, scheme.surface), greaterThan(4.5));
      expect(
        contrast(scheme.onTertiaryContainer, scheme.tertiaryContainer),
        greaterThan(4.5),
      );
      expect(scheme.tertiary, isNot(const Color(0xFFC8CA94)));
    });
  });

  test('タイマーの数字は tabular figures を要求する', () {
    final ThemeData theme = AppTheme.light();
    expect(
      AppTypography.timer(theme.textTheme).fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expect(
      AppTypography.numeric(theme.textTheme.titleMedium!).fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('シードカラーは珈琲の中煎り色', () {
    expect(AppTheme.seedColor, const Color(0xFF6F4E37));
  });
}
