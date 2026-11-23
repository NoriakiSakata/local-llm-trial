import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../../data/models/bean.dart';

/// 焙煎度を 3 つの点で示すバッジ（浅 ●○○ / 中 ●●○ / 深 ●●●）。
/// 色だけに頼らず、点の数とラベルでも区別できるようにする。
class RoastBadge extends StatelessWidget {
  const RoastBadge({super.key, required this.roast});

  final RoastLevel roast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final level = roast.index + 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 3; i++)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= level ? scheme.primary : scheme.outlineVariant,
            ),
          ),
        const SizedBox(width: AppSpace.xs),
        Text(
          roast.label,
          style: theme.textTheme.labelMedium!.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
