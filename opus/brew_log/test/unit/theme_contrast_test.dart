import 'dart:math' as math;

import 'package:brew_log/app/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// WCAG 2.x のコントラスト比
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    group('${brightness.name} テーマのコントラスト', () {
      final s = AppTheme.scheme(brightness);

      // 本文テキスト: AA（4.5:1）以上
      final textPairs = <String, (Color, Color)>{
        '本文 / 背景': (s.onSurface, s.surface),
        '補足文 / 背景': (s.onSurfaceVariant, s.surface),
        '補足文 / カード': (s.onSurfaceVariant, s.surfaceContainerLow),
        'primary 文字 / 背景': (s.primary, s.surface),
        'ボタン文字 / primary': (s.onPrimary, s.primary),
        'バッジ文字 / secondaryContainer': (
          s.onSecondaryContainer,
          s.secondaryContainer,
        ),
        'FAB 文字 / primaryContainer': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        'エラーバナー': (s.onErrorContainer, s.errorContainer),
        'ランキング1位 / tertiaryContainer': (
          s.onTertiaryContainer,
          s.tertiaryContainer,
        ),
      };
      for (final e in textPairs.entries) {
        test(e.key, () {
          expect(contrast(e.value.$1, e.value.$2), greaterThanOrEqualTo(4.5));
        });
      }

      // 星・グラフなど非テキスト要素: 3:1 以上
      test('評価の星 / カード', () {
        expect(
          contrast(s.tertiary, s.surfaceContainerLow),
          greaterThanOrEqualTo(3),
        );
      });
      test('グラフの棒 / カード', () {
        expect(
          contrast(s.primary, s.surfaceContainerLow),
          greaterThanOrEqualTo(3),
        );
      });
    });
  }
}
