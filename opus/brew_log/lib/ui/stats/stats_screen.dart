import 'package:material_ui/material_ui.dart';

import '../../domain/stats.dart';
import '../../state/app_store.dart';
import '../format.dart';
import '../home_shell.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/empty_state.dart';
import 'daily_chart.dart';

/// 振り返り：直近30日の集計
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final stats = BrewStats.compute(store.records, store.clock());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('振り返り'), actions: const [SettingsButton()]),
      body: stats.count == 0
          ? EmptyState(
              title: '直近30日の記録がありません',
              message: '記録が増えると、抽出の回数や\n豆ごとの評価の傾向がここに出ます。',
              actionLabel: '淹れにいく',
              onAction: () => HomeShell.selectTab(context, HomeShell.brewTab),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
              children: [
                const SectionLabel('直近30日'),
                Row(
                  spacing: Space.sm,
                  children: [
                    Expanded(
                      child: _Metric(label: '抽出回数', value: '${stats.count}', unit: '杯'),
                    ),
                    Expanded(
                      child: _Metric(label: '平均評価', value: formatRating(stats.averageRating), unit: '/ 5'),
                    ),
                  ],
                ),
                const SizedBox(height: Space.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('日別の抽出回数', style: theme.textTheme.titleSmall),
                        const SizedBox(height: Space.md),
                        SizedBox(height: 140, child: DailyChart(daily: stats.daily)),
                      ],
                    ),
                  ),
                ),
                const SectionLabel('豆ごとの平均評価（直近30日）'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.sm),
                    child: Column(
                      children: [for (final (i, s) in stats.ranking.indexed) _RankRow(rank: i + 1, score: s)],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.unit});
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: Space.xs),
            FittedBox(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: value, style: theme.textTheme.displaySmall?.tabular),
                    TextSpan(text: ' $unit', style: theme.textTheme.labelLarge),
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

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.score});
  final int rank;
  final BeanScore score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (bg, fg) = rank == 1
        ? (scheme.primary, scheme.onPrimary)
        : (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: bg,
        child: Text('$rank', style: theme.textTheme.labelLarge?.copyWith(color: fg)),
      ),
      title: Text(score.beanName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${score.count} 杯'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: Space.xs),
          Text(formatRating(score.averageRating), style: theme.textTheme.titleMedium?.tabular),
        ],
      ),
    );
  }
}
