import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// ★で評価を示す（読み取り専用）。
class RatingStars extends StatelessWidget {
  const RatingStars({required this.rating, this.size = 18, super.key});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i <= rating ? scheme.tertiary : scheme.outline,
          ),
      ],
    );
  }
}

/// ★をタップして評価を入力する。
class RatingInput extends StatelessWidget {
  const RatingInput({required this.value, required this.onChanged, super.key});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '評価',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          for (int i = 1; i <= 5; i++)
            IconButton.filledTonal(
              onPressed: () => onChanged(i),
              isSelected: i <= value,
              style: IconButton.styleFrom(
                backgroundColor: i <= value
                    ? scheme.tertiaryContainer
                    : scheme.surfaceContainerHighest,
                foregroundColor: i <= value
                    ? scheme.onTertiaryContainer
                    : scheme.onSurfaceVariant,
              ),
              tooltip: '$i つ星',
              icon: Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              ),
            ),
        ],
      ),
    );
  }
}

/// 味覚の3軸スライダー。
class TasteSlider extends StatelessWidget {
  const TasteSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  static String lowLabel(String label) => switch (label) {
    '酸味' => 'やさしい',
    '苦味' => '控えめ',
    '甘み' => 'あっさり',
    _ => '弱い',
  };

  static String highLabel(String label) => switch (label) {
    '酸味' => 'はっきり',
    '苦味' => '力強い',
    '甘み' => '濃厚',
    _ => '強い',
  };

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: text.titleSmall)),
            Text(
              '${(value * 100).round()}',
              style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        Slider(
          value: value,
          max: 1,
          divisions: 20,
          label: '${(value * 100).round()}',
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              lowLabel(label),
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              highLabel(label),
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// 味の3軸を棒で表示する（詳細画面用、読み取り専用）。
class TasteReadout extends StatelessWidget {
  const TasteReadout({required this.taste, super.key});

  final TasteProfile taste;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<(String, double)> rows = <(String, double)>[
      ('酸味', taste.acidity),
      ('苦味', taste.bitterness),
      ('甘み', taste.sweetness),
    ];
    return Column(
      children: <Widget>[
        for (final (String label, double value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 48,
                  child: Text(
                    label,
                    style: text.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppRadius.chipRadius,
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 34,
                  child: Text(
                    '${(value * 100).round()}',
                    textAlign: TextAlign.right,
                    style: AppTypography.numeric(text.labelLarge!)
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
