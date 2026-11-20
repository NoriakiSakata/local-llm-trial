import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/brew_plan.dart';
import '../../application/brew_session.dart';
import '../../application/providers.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import 'brew_idle_view.dart';
import 'brew_running_view.dart';

/// 淹れる画面。セッションが無ければ待機ビュー、あれば実行中ビューを出す。
class BrewScreen extends ConsumerWidget {
  const BrewScreen({required this.onGoToTab, super.key});

  final void Function(int index) onGoToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrewSession? session = ref.watch(brewSessionProvider);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppMotion.slow,
        switchInCurve: AppMotion.emphasizedCurve,
        switchOutCurve: AppMotion.standardCurve,
        transitionBuilder: (Widget child, Animation<double> animation) =>
            FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
        child: session == null
            ? BrewIdleView(
                key: const ValueKey<String>('idle'),
                onGoToTab: onGoToTab,
              )
            : BrewRunningView(key: const ValueKey<String>('running')),
      ),
    );
  }
}

/// 進行中のステップ情報をまとめて画面下部に出す行。
class BrewStatRow extends StatelessWidget {
  const BrewStatRow({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: children,
    );
  }
}

/// `蒸らし → 1投目 → 2投目` のプレビュー。
class StepStrip extends StatelessWidget {
  const StepStrip({required this.plan, this.activeIndex, super.key});

  final BrewPlan plan;

  /// 実行中なら現在位置を強調する。
  final int? activeIndex;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        itemCount: plan.steps.length,
        separatorBuilder: (_, _) => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Icon(Icons.chevron_right_rounded, size: 16),
        ),
        itemBuilder: (BuildContext context, int index) {
          final BrewStep step = plan.steps[index];
          final bool active = activeIndex == index;
          final bool passed = activeIndex != null && index < activeIndex!;
          return AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.standardCurve,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: active
                  ? scheme.primaryContainer
                  : passed
                  ? scheme.surfaceContainerHigh
                  : scheme.surfaceContainerLow,
              borderRadius: AppRadius.chipRadius,
              border: Border.all(
                color: active ? scheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  step.label,
                  style: text.labelLarge?.copyWith(
                    color: active
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                Text(
                  '${step.targetCumMl} ml',
                  style: AppTypography.numeric(text.labelMedium!).copyWith(
                    color: active
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
