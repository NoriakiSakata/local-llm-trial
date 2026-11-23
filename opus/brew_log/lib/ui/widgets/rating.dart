import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';

/// 評価の表示（読み取り専用）。小数の平均値は四捨五入した数の星で示す。
class StarRatingView extends StatelessWidget {
  const StarRatingView({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = rating.round();
    return Semantics(
      label: '評価 ${rating.toStringAsFixed(1)}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                i <= filled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i <= filled ? scheme.tertiary : scheme.outlineVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// 評価の入力（★1〜5）。
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            key: ValueKey('star-$i'),
            tooltip: '★$i',
            iconSize: 40,
            padding: const EdgeInsets.all(AppSpace.xs),
            onPressed: () => onChanged(i),
            icon: AnimatedSwitcher(
              duration: AppMotion.short,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                key: ValueKey(i <= value),
                color: i <= value ? scheme.tertiary : scheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}

/// 味の強さ（1〜5）を細い横棒で表示する。
class TasteBar extends StatelessWidget {
  const TasteBar({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '$label $value / 5',
      child: ExcludeSemantics(
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                label,
                style: theme.textTheme.labelMedium!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.pill,
                child: LinearProgressIndicator(
                  value: value / 5,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: scheme.secondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            SizedBox(
              width: 16,
              child: Text(
                '$value',
                textAlign: TextAlign.end,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
