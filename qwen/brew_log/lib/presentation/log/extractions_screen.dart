import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../widgets/common.dart';
import '../widgets/empty_state.dart';
import '../widgets/feedback.dart';
import '../widgets/rating_stars.dart';
import 'extraction_detail_screen.dart';

/// 抽出記録の一覧。豆で絞り込める。
class ExtractionsScreen extends ConsumerWidget {
  const ExtractionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Extraction> items = ref.watch(filteredExtractionsProvider);
    final List<Bean> beans = ref.watch(appDataProvider).beans;
    final String? filter = ref.watch(beanFilterProvider);
    final bool totallyEmpty = ref.watch(appDataProvider).extractions.isEmpty;

    if (totallyEmpty) {
      return EmptyState(
        title: 'まだ記録がありません',
        description: 'タイマーを最後まで淹れると、評価とメモを\nこの画面に積んでいきます。',
        action: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const _BrewHintPage()),
          ),
          icon: const Icon(Icons.timer_outlined),
          label: const Text('淹れ方を見る'),
        ),
      );
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (beans.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.sm,
                ),
                children: <Widget>[
                  FilterChip(
                    label: const Text('すべての豆'),
                    selected: filter == null,
                    onSelected: (_) =>
                        ref.read(beanFilterProvider.notifier).select(null),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  for (final Bean bean in beans) ...[
                    FilterChip(
                      label: Text(bean.name, overflow: TextOverflow.ellipsis),
                      selected: filter == bean.id,
                      onSelected: (_) => ref
                          .read(beanFilterProvider.notifier)
                          .select(filter == bean.id ? null : bean.id),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? const _EmptyFilterResult()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.lg,
                      AppSpacing.screen,
                      AppSpacing.xxxl,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (BuildContext context, int index) {
                      final bool newDay =
                          index == 0 ||
                          !_sameDay(
                            items[index - 1].brewedAt,
                            items[index].brewedAt,
                          );
                      return SizedBox(
                        height: newDay ? AppSpacing.xl : AppSpacing.md,
                      );
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final Extraction item = items[index];
                      final bool showHeader =
                          index == 0 ||
                          !_sameDay(items[index - 1].brewedAt, item.brewedAt);
                      return FadeSlideIn(
                        delayMs: (index * 24).clamp(0, 240),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (showHeader)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                  left: AppSpacing.xs,
                                ),
                                child: Text(
                                  formatDateJa(item.brewedAt),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                            _ExtractionTile(
                              item: item,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ExtractionDetailScreen(extraction: item),
                                ),
                              ),
                              onDeleted: () => _delete(context, ref, item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Extraction item,
  ) async {
    final bool ok = await confirmAction(
      context,
      title: 'この記録を削除しますか？',
      message: '${formatFullDateTimeJa(item.brewedAt)} の記録を削除します。',
    );
    if (!ok || !context.mounted) return;

    final int index = ref
        .read(appDataProvider)
        .extractions
        .indexWhere((Extraction e) => e.id == item.id);
    final Extraction? removed = ref
        .read(appDataProvider.notifier)
        .removeExtraction(item.id);
    if (removed == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        undoSnackBar(
          message: '記録を削除しました',
          actionLabel: '戻す',
          onUndo: () => ref
              .read(appDataProvider.notifier)
              .restoreExtraction(removed, index),
        ),
      );
  }
}

class _ExtractionTile extends StatelessWidget {
  const _ExtractionTile({
    required this.item,
    required this.onTap,
    required this.onDeleted,
  });

  final Extraction item;
  final VoidCallback onTap;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey<String>('extraction-${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDeleted(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: AppRadius.cardRadius,
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: scheme.onErrorContainer,
        ),
      ),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.beanName,
                        style: text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${formatTimeJa(item.brewedAt)} · ${item.waterMl} ml · '
                        '${formatDurationJa(Duration(seconds: item.totalSeconds))}',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (item.note.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          item.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                RatingStars(rating: item.rating),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFilterResult extends ConsumerWidget {
  const _EmptyFilterResult();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmptyState(
      title: 'この豆の記録は見つかりません',
      description: '別の豆を選ぶか、「すべての豆」を表示してください。',
      action: FilledButton(
        onPressed: () => ref.read(beanFilterProvider.notifier).select(null),
        child: const Text('すべての豆を表示'),
      ),
    );
  }
}

/// 記録が0件のときに見る、淹れ方の簡単な案内。
class _BrewHintPage extends StatelessWidget {
  const _BrewHintPage();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    const List<(String, String)> steps = <(String, String)>[
      ('豆を登録する', '名前・産地・焙煎度・焙煎日を入力すると、経過日数を数え始めます。'),
      ('レシピを作る', '豆量・湯量・湯温・蒸らし時間・注湯回数を決めます。ステップは自動計算です。'),
      ('タイマーで淹れる', '蒸らし→1投目→2投目…の順に、残り時間と目標の累計湯量を表示します。'),
      ('評価をつける', '★と酸味・苦味・甘み、メモを残します。すべて端末の中にだけ保存されます。'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('淹れ方のはじめ方')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: <Widget>[
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    foregroundColor: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer,
                    child: Text('${i + 1}', style: text.labelLarge),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(steps[i].$1, style: text.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(steps[i].$2, style: text.bodyMedium),
                      ],
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
