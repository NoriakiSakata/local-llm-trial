import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../../domain/brew_stats.dart';
import '../../state/app_providers.dart';
import '../../ui/widgets/coffee_illustration.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/rating.dart';
import '../../ui/widgets/settings_action.dart';
import 'daily_bar_chart.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsProvider);
    final beans = ref.watch(beansProvider);
    final summary = BrewStats.recent(records, DateTime.now());
    final ranking = BrewStats.beanRanking(records, beans);

    return Scaffold(
      appBar: AppBar(
        title: const Text('振り返り'),
        actions: const [SettingsAction()],
      ),
      body: records.isEmpty
          ? EmptyState(
              illustration: CoffeeIllustrationKind.chart,
              title: '振り返るデータがまだありません',
              message: '抽出を記録すると、30日間の抽出回数や\n豆ごとの評価ランキングがここに表示されます。',
              actionLabel: '抽出をはじめる',
              actionIcon: Icons.coffee_maker_outlined,
              onAction: () =>
                  ref.read(homeTabProvider.notifier).select(HomeTab.brew),
            )
          : ContentWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  0,
                  AppSpace.screen,
                  AppSpace.xl,
                ),
                children: [
                  const SectionLabel('直近30日'),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          key: const ValueKey('stat-count'),
                          label: '抽出回数',
                          value: '${summary.count}',
                          unit: '回',
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _StatCard(
                          key: const ValueKey('stat-average'),
                          label: '平均評価',
                          value:
                              summary.averageRating?.toStringAsFixed(1) ?? '—',
                          unit: summary.averageRating == null ? '' : '/ 5',
                          footer: summary.averageRating == null
                              ? null
                              : StarRatingView(
                                  rating: summary.averageRating!,
                                  size: 14,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.lg,
                        AppSpace.lg,
                        AppSpace.lg,
                        AppSpace.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '日ごとの抽出回数',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpace.lg),
                          DailyBarChart(
                            counts: summary.dailyCounts,
                            firstDay: summary.firstDay,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SectionLabel('豆ごとの平均評価'),
                  if (ranking.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.lg),
                        child: Text(
                          '豆を選んで抽出すると、ランキングが表示されます。',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.sm,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < ranking.length; i++)
                              _RankingRow(rank: i + 1, item: ranking[i]),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.footer,
  });

  final String label;
  final String value;
  final String unit;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge!.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: theme.textTheme.displaySmall!.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpace.lg, child: footer),
          ],
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.rank, required this.item});

  final int rank;
  final BeanRanking item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final top = rank == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: top
                  ? scheme.tertiaryContainer
                  : scheme.surfaceContainerHigh,
            ),
            child: Text(
              '$rank',
              style: theme.textTheme.labelLarge!.copyWith(
                color: top
                    ? scheme.onTertiaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.beanName,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpace.xs),
                ClipRRect(
                  borderRadius: AppRadius.pill,
                  child: LinearProgressIndicator(
                    value: item.averageRating / 5,
                    minHeight: 6,
                    color: top ? scheme.tertiary : scheme.primary,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.averageRating.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '${item.count}杯',
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
