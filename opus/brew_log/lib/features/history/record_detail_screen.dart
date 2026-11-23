import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../../data/models/brew_record.dart';
import '../../domain/brew_schedule.dart';
import '../../state/app_providers.dart';
import '../../ui/format.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/rating.dart';

class RecordDetailScreen extends ConsumerWidget {
  const RecordDetailScreen({super.key, required this.recordId});

  final String recordId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    BrewRecord record,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('この記録を削除しますか？'),
        content: const Text('振り返りの集計からも外れます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final notifier = ref.read(recordsProvider.notifier);
    await notifier.remove(record.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    showUndoSnackBar(
      context,
      message: '記録を削除しました',
      onUndo: () => notifier.restore(record),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsProvider);
    final index = records.indexWhere((r) => r.id == recordId);
    if (index < 0) {
      // 削除直後の 1 フレームなど
      return Scaffold(appBar: AppBar());
    }
    final record = records[index];
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = record.recipe;
    final schedule = BrewSchedule.fromRecipe(r);

    return Scaffold(
      appBar: AppBar(
        title: const Text('記録の詳細'),
        actions: [
          IconButton(
            tooltip: '削除',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _delete(context, ref, record),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.sm,
            AppSpace.screen,
            AppSpace.xxl,
          ),
          children: [
            Text(
              Fmt.fullDateTime(record.brewedAt),
              style: theme.textTheme.labelLarge!.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(record.beanName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                StarRatingView(rating: record.rating.toDouble(), size: 28),
                const SizedBox(width: AppSpace.sm),
                Text(
                  '${record.rating} / 5',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SectionLabel('味のバランス'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  children: [
                    for (final axis in TasteAxis.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.xs,
                        ),
                        child: TasteBar(
                          label: axis.label,
                          value: record.taste(axis),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (record.note.isNotEmpty) ...[
              const SectionLabel('メモ'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Text(record.note, style: theme.textTheme.bodyLarge),
                ),
              ),
            ],
            const SectionLabel('レシピ'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                child: Column(
                  children: [
                    _Row(label: '豆の量', value: '${r.doseG} g'),
                    _Row(label: '湯量', value: '${r.waterMl} ml'),
                    _Row(label: '比率', value: '1:${r.ratio.toStringAsFixed(1)}'),
                    _Row(label: '湯温', value: '${r.tempC} ℃'),
                    _Row(label: '蒸らし', value: '${r.bloomSec} 秒'),
                    _Row(
                      label: '注湯',
                      value: '${r.pours} 回（${r.pourIntervalSec} 秒間隔）',
                    ),
                    _Row(
                      label: '抽出時間',
                      value:
                          '${Fmt.mmss(Duration(seconds: record.elapsedSec))}'
                          '（予定 ${Fmt.mmss(schedule.total)}）',
                    ),
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

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
