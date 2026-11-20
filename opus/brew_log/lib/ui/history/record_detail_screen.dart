import 'package:material_ui/material_ui.dart';

import '../../state/app_store.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/rating.dart';
import 'history_screen.dart';

class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.recordId});
  final String recordId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final record = store.records.where((r) => r.id == recordId).firstOrNull;
    if (record == null) {
      // 削除された直後など
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('この記録は削除されました')),
      );
    }
    final theme = Theme.of(context);
    final r = record.recipe;
    return Scaffold(
      appBar: AppBar(
        title: Text(formatDate(record.brewedAt)),
        actions: [
          IconButton(
            tooltip: '削除',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              Navigator.pop(context);
              deleteRecordWithUndo(context, record);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          Text(record.beanName, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Space.xs),
          Text(formatDateTime(record.brewedAt), style: theme.textTheme.bodyMedium),
          const SizedBox(height: Space.md),
          StarRatingView(value: record.rating, size: 28),
          const SectionLabel('味'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                spacing: Space.md,
                children: [
                  _TasteMeter(label: '酸味', value: record.acidity),
                  _TasteMeter(label: '苦味', value: record.bitterness),
                  _TasteMeter(label: '甘み', value: record.sweetness),
                ],
              ),
            ),
          ),
          if (record.note.isNotEmpty) ...[
            const SectionLabel('メモ'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Text(record.note, style: theme.textTheme.bodyLarge),
              ),
            ),
          ],
          const SectionLabel('レシピ'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                spacing: Space.sm,
                children: [
                  _Row('豆の量', '${r.beanGrams} g'),
                  _Row('湯量', '${r.waterMl} ml（1:${r.ratio.toStringAsFixed(1)}）'),
                  _Row('湯温', '${r.waterTempC} ℃'),
                  _Row('蒸らし', '${r.bloomSeconds} 秒'),
                  _Row('注湯回数', '${r.pours} 回'),
                  _Row('抽出時間', formatClock(Duration(seconds: record.elapsedSeconds))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        Text(value, style: theme.textTheme.bodyLarge?.tabular),
      ],
    );
  }
}

/// 1〜5 を5つのマスで表す
class _TasteMeter extends StatelessWidget {
  const _TasteMeter({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '$label $value / 5',
      child: ExcludeSemantics(
        child: Row(
          children: [
            SizedBox(width: 48, child: Text(label, style: theme.textTheme.bodyMedium)),
            for (var i = 1; i <= 5; i++)
              Expanded(
                child: Container(
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i <= value ? scheme.primary : scheme.surfaceContainerHighest,
                    borderRadius: Corner.all(Corner.sm),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
