import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';

/// 「− 値 +」で数値を調整する行。長押しで連続変更できる。
class ValueStepper extends StatelessWidget {
  const ValueStepper({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.icon,
  });

  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final int step;
  final IconData? icon;
  final ValueChanged<int> onChanged;

  void _change(int delta) {
    final next = (value + delta).clamp(min, max);
    if (next != value) {
      HapticFeedback.selectionClick();
      onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpace.md),
          ],
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _RepeatButton(
            key: ValueKey('$label-minus'),
            icon: Icons.remove_rounded,
            tooltip: '$labelを減らす',
            enabled: value > min,
            onStep: () => _change(-step),
          ),
          SizedBox(
            width: 76,
            child: Semantics(
              label: '$label $value$unit',
              child: ExcludeSemantics(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$value',
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: theme.textTheme.labelMedium!.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          _RepeatButton(
            key: ValueKey('$label-plus'),
            icon: Icons.add_rounded,
            tooltip: '$labelを増やす',
            enabled: value < max,
            onStep: () => _change(step),
          ),
        ],
      ),
    );
  }
}

class _RepeatButton extends StatefulWidget {
  const _RepeatButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onStep,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onStep;

  @override
  State<_RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<_RepeatButton> {
  Timer? _repeat;

  void _stop() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: widget.enabled
          ? (_) => _repeat = Timer.periodic(
              const Duration(milliseconds: 90),
              (_) => widget.onStep(),
            )
          : null,
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      child: IconButton.filledTonal(
        tooltip: widget.tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: widget.enabled ? widget.onStep : null,
        icon: Icon(widget.icon, size: 20),
      ),
    );
  }
}
