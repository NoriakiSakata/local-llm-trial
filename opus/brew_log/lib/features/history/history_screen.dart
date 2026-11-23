import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../../data/models/brew_record.dart';
import '../../state/app_providers.dart';
import '../../ui/format.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/rating.dart';
import '../../ui/widgets/settings_action.dart';
import 'record_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsProvider);
    final filter = ref.watch(historyFilterProvider);
    final beans = ref.watch(beansProvider);

    // 絞り込み候補は「記録に登場する豆」。削除済みの豆も記録時の名前で出す。
    final options = <String, String>{};
    for (final r in records) {
      final id = r.beanId;
      if (id == null) continue;
      options[id] = beans
          .where((b) => b.id == id)
          .map((b) => b.name)
          .firstWhere((_) => true, orElse: () => r.beanName);
    }
    // フィルタ対象の豆の記録がすべて消えたら「すべて」に戻す
    final activeFilter = options.containsKey(filter) ? filter : null;
    final visible = activeFilter == null
        ? records
        : records.where((r) => r.beanId == activeFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('記録'),
        actions: const [SettingsAction()],
      ),
      body: records.isEmpty
          ? EmptyState(
              title: 'まだ抽出の記録がありません',
              message: 'タイマーで淹れ終えたら、味を記録しましょう。\n記録がたまると振り返りに反映されます。',
              actionLabel: '抽出をはじめる',
              actionIcon: Icons.coffee_maker_outlined,
              onAction: () =>
                  ref.read(homeTabProvider.notifier).select(HomeTab.brew),
            )
          : Column(
              children: [
                if (options.isNotEmpty)
                  _FilterBar(
                    options: options,
                    selected: activeFilter,
                    onSelected: (id) =>
                        ref.read(historyFilterProvider.notifier).select(id),
                  ),
                Expanded(
                  child: ContentWidth(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.screen,
                        AppSpace.sm,
                        AppSpace.screen,
                        AppSpace.xl,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpace.sm),
                      itemBuilder: (context, i) {
                        final record = visible[i];
                        return EntranceAnimation(
                          key: ValueKey(record.id),
                          delay: (i * 0.05).clamp(0, 0.4),
                          child: _RecordTile(
                            record: record,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    RecordDetailScreen(recordId: record.id),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final Map<String, String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.screen,
          vertical: AppSpace.sm,
        ),
        children: [
          FilterChip(
            label: const Text('すべて'),
            selected: selected == null,
            showCheckmark: false,
            onSelected: (_) => onSelected(null),
          ),
          for (final entry in options.entries) ...[
            const SizedBox(width: AppSpace.sm),
            FilterChip(
              label: Text(entry.value),
              selected: selected == entry.key,
              showCheckmark: false,
              onSelected: (on) => onSelected(on ? entry.key : null),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.onTap});

  final BrewRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.beanName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  StarRatingView(rating: record.rating.toDouble()),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                '${Fmt.dateTime(record.brewedAt)} ・ '
                '${record.recipe.doseG}g / ${record.recipe.waterMl}ml',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              for (final axis in TasteAxis.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.xs),
                  child: TasteBar(label: axis.label, value: record.taste(axis)),
                ),
              if (record.note.isNotEmpty) ...[
                const SizedBox(height: AppSpace.xs),
                Text(
                  record.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
