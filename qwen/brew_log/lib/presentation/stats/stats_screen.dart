import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../application/stats.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../format.dart';
import '../widgets/common.dart';
import '../widgets/empty_state.dart';
import '../widgets/rating_stars.dart';
import 'daily_bar_chart.dart';

/// 振り返り画面。30日の推移と豆別ランキングを自作描画で見せる。
class StatsScreen extends ConsumerWidget {
  const StatsScreen({required this.onGoToTab, super.key});

  final void Function(int index) onGoToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrewStats stats = ref.watch(statsProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String averageLabel = stats.totalAverage?.toStringAsFixed(1) ?? '—';

    if (stats.totalCount == 0) {
      return EmptyState(
        title: '振り返る記録がありません',
        description: 'タイマーで1杯淹れると、ここに回数と平均評価が\n積まれ始めます。',
        action: FilledButton.icon(
          onPressed: () => onGoToTab(0),
          icon: const Icon(Icons.timer_outlined),
          label: const Text('淹れる画面へ'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        AppSpacing.xxxl,
      ),
      children: <Widget>[
        // 2枚のカード高さを揃えたいが、ListView 内なので stretch は使えない。
        // IntrinsicHeight で1行の高さを合わせてから伸ばす。
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _SummaryCard(
                  label: '直近${stats.windowDays}日の抽出',
                  value: '${stats.windowCount}',
                  unit: '杯',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SummaryCard(
                  label: '直近${stats.windowDays}日の平均評価',
                  value: stats.windowAverage?.toStringAsFixed(1) ?? '—',
                  unit: '/ 5.0',
                  stars: stats.windowAverage?.round(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        SectionHeader(
          title: '日別の抽出回数',
          trailing:
              '${formatMonthDay(stats.daily.first.day)} — ${formatMonthDay(stats.daily.last.day)}',
        ),
        SectionCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DailyBarChart(daily: stats.daily, max: stats.dailyMax),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _Legend(color: scheme.primary, label: 'いつもの日'),
                  _Legend(color: scheme.tertiary, label: '今日'),
                  Text(
                    'トータル ${stats.totalCount} 杯 · 平均 $averageLabel',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        SectionHeader(title: '豆ごとの平均評価', trailing: '全${stats.beanCount}種の豆'),
        if (stats.ranking.isEmpty)
          const SectionCard(child: Text('まだ記録に豆が紐付いていません'))
        else
          SectionCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < stats.ranking.length; i++)
                  _RankRow(
                    rank: i + 1,
                    item: stats.ranking[i],
                    isLast: i == stats.ranking.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.unit,
    this.stars,
  });

  final String label;
  final String value;
  final String unit;
  final int? stars;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: text.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            NumericValue(
              value: value,
              unit: unit,
              style: AppTypography.numeric(text.displaySmall!),
            ),
            if (stars != null) ...[
              const SizedBox(height: AppSpacing.sm),
              RatingStars(rating: stars!, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.item,
    required this.isLast,
  });

  final int rank;
  final BeanRanking item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : AppSpacing.lg,
        top: isLast ? 0 : AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: AppTypography.numeric(
                text.titleSmall!.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.beanName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: AppRadius.chipRadius,
                  child: LinearProgressIndicator(
                    value: item.averageRating / 5,
                    minHeight: 6,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                item.averageRating.toStringAsFixed(1),
                style: AppTypography.numeric(text.titleMedium!),
              ),
              Text(
                '${item.count}杯',
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
