import 'package:material_ui/material_ui.dart';

/// ★1〜5 を選ぶ
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: '★$i',
            iconSize: 36,
            onPressed: () => onChanged(i),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
              child: Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                key: ValueKey(i <= value),
                color: color,
              ),
            ),
          ),
      ],
    );
  }
}

/// ★の表示だけ
class StarRatingView extends StatelessWidget {
  const StarRatingView({super.key, required this.value, this.size = 16});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '評価 $value',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i <= value ? scheme.primary : scheme.outlineVariant,
              ),
          ],
        ),
      ),
    );
  }
}
