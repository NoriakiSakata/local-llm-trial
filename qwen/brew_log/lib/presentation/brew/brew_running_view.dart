import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/brew_plan.dart';
import '../../application/brew_session.dart';
import '../../application/providers.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../widgets/common.dart';
import 'brew_screen.dart';
import 'rating_sheet.dart';
import 'step_dial.dart';

/// タイマー実行中ビュー。
class BrewRunningView extends ConsumerStatefulWidget {
  const BrewRunningView({super.key});

  @override
  ConsumerState<BrewRunningView> createState() => _BrewRunningViewState();
}

class _BrewRunningViewState extends ConsumerState<BrewRunningView> {
  bool _sheetShown = false;

  @override
  Widget build(BuildContext context) {
    final BrewSession? session = ref.watch(brewSessionProvider);

    // 完了したら1回だけ評価シートを出す（閉じて後からでも開き直せる）。
    ref.listen<BrewSession?>(brewSessionProvider, (
      BrewSession? previous,
      BrewSession? next,
    ) {
      final bool justFinished =
          (next?.isFinished ?? false) && !(previous?.isFinished ?? false);
      if (justFinished && !_sheetShown) {
        _sheetShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
      }
      if (next == null) _sheetShown = false;
    });

    if (session == null) return const SizedBox.shrink();

    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BrewStep step = session.currentStep;
    final bool paused = session.phase == BrewPhase.paused;
    final List<double> boundaries = session.plan.steps
        .skip(1)
        .map((BrewStep s) => s.startMs / session.plan.totalMs)
        .toList(growable: false);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.lg,
              AppSpacing.screen,
              0,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    session.recipe.name,
                    style: text.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (paused)
                  _StatusChip(
                    label: '一時停止中',
                    color: scheme.tertiaryContainer,
                    foreground: scheme.onTertiaryContainer,
                  )
                else if (session.isFinished)
                  _StatusChip(
                    label: '完了',
                    color: scheme.primaryContainer,
                    foreground: scheme.onPrimaryContainer,
                  )
                else
                  _StatusChip(
                    label: '淹れています',
                    color: scheme.secondaryContainer,
                    foreground: scheme.onSecondaryContainer,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: StepDial(
                  progress: session.progress,
                  boundaries: boundaries,
                  paused: paused,
                  // リングの中にはみ出さないよう、縮小は FittedBox に任せる
                  // （小さな画面でも overflow しないための担保）。
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(step.label, style: text.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          session.isFinished
                              ? '00:00'
                              : formatClock(session.remaining),
                          style: AppTypography.timer(text).copyWith(
                            color: session.isFinished
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text('このステップの残り', style: text.labelMedium),
                        const SizedBox(height: AppSpacing.lg),
                        NumericValue(
                          value: '${step.targetCumMl}',
                          unit: 'ml',
                          style: text.headlineSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text('目標の累計湯量', style: text.labelMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              children: <Widget>[
                BrewStatRow(
                  children: <Widget>[
                    _MiniStat(
                      label: '経過',
                      value: formatClock(
                        Duration(milliseconds: session.elapsedMs),
                      ),
                    ),
                    _MiniStat(
                      label: '残り合計',
                      value: formatClock(session.remainingTotal),
                    ),
                    _MiniStat(
                      label: '総湯量',
                      value: '${session.plan.waterMl} ml',
                    ),
                    _MiniStat(label: '湯温', value: '${session.plan.tempC} ℃'),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 56,
                  child: StepStrip(
                    plan: session.plan,
                    activeIndex: session.currentIndex,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xl,
              AppSpacing.screen,
              AppSpacing.lg,
            ),
            child: session.isFinished
                ? FilledButton.icon(
                    onPressed: () {
                      _sheetShown = true;
                      _openSheet();
                    },
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('評価をつけて保存'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
                    ),
                  )
                : Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              ref.read(brewSessionProvider.notifier).restart(),
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('リセット'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xl,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () {
                            final BrewSessionNotifier notifier = ref.read(
                              brewSessionProvider.notifier,
                            );
                            if (paused) {
                              notifier.resume();
                            } else {
                              notifier.pause();
                            }
                          },
                          icon: Icon(
                            paused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                          ),
                          label: Text(paused ? '再開' : '一時停止'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xl,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      IconButton.filledTonal(
                        onPressed: () {
                          ref
                              .read(brewSessionProvider.notifier)
                              .finishManually();
                        },
                        tooltip: 'ここで完了',
                        icon: const Icon(Icons.done_all_rounded),
                      ),
                    ],
                  ),
          ),
          if (!session.isFinished)
            TextButton(
              onPressed: () => ref.read(brewSessionProvider.notifier).discard(),
              child: const Text('中断して終了'),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Future<void> _openSheet() async {
    final BrewSession? session = ref.read(brewSessionProvider);
    if (session == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) => RatingSheet(session: session),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.foreground,
  });

  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.chipRadius,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: foreground),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          style: AppTypography.numeric(text.titleMedium!),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
