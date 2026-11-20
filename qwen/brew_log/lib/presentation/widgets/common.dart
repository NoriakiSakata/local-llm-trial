import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// 見出し + カードのまとまり。画面の基本ブロック。
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.title,
    this.trailing,
    this.padding,
    super.key,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final TextStyle? body = Theme.of(context).textTheme.bodyMedium;
    return Card(
      child: Padding(
        padding:
            padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (title != null) ...[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title!,
                      style: body?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// カードの上につける小さな見出し。
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.trailing,
    this.action,
    super.key,
  });

  final String title;
  final String? trailing;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ?action,
        ],
      ),
    );
  }
}

/// 数値 + 単位。`240 ml` のように桁を揃えて見せる。
class NumericValue extends StatelessWidget {
  const NumericValue({
    required this.value,
    this.unit = '',
    this.style,
    this.color,
    super.key,
  });

  final String value;
  final String unit;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle base = style ?? text.headlineSmall!;
    // 半分の幅のカードなどでも数値が詰まらないよう、
    // はみ出すなら縮める（overflow エラーを出さない）。
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Text(
            value,
            style: AppTypography.numeric(base.copyWith(color: color)),
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              unit,
              style: text.bodySmall?.copyWith(
                color:
                    (color ?? Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 計量値をまとめたピル（レシピ概要などで行を圧縮するため）。
class InfoPill extends StatelessWidget {
  const InfoPill({
    required this.label,
    required this.value,
    this.isFirst = false,
    super.key,
  });

  final String label;
  final String value;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: AppRadius.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.numeric(
              text.labelLarge!.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// 出現時のフェード + slight slide。リスト追加・画面切替用。
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    required this.child,
    this.delayMs = 0,
    this.distance = 12,
    super.key,
  });

  final Widget child;
  final int delayMs;
  final double distance;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.slow + Duration(milliseconds: delayMs),
      curve: AppMotion.standardCurve,
      builder: (BuildContext context, double t, Widget? child) {
        return Transform.translate(
          offset: Offset(0, distance * (1 - t)),
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: child,
    );
  }
}

/// 画面全体の等間隔パディング。
class ScreenPadding extends StatelessWidget {
  const ScreenPadding({required this.child, super.key});

  final Widget child;

  static const EdgeInsets edge = EdgeInsets.symmetric(
    horizontal: AppSpacing.screen,
    vertical: AppSpacing.lg,
  );

  @override
  Widget build(BuildContext context) => Padding(padding: edge, child: child);
}
