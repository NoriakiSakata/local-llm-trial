import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../state/app_store.dart';
import '../format.dart';
import '../home_shell.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/empty_state.dart';
import '../widgets/rating.dart';
import 'record_detail_screen.dart';

/// 記録：履歴一覧。豆で絞り込める
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// 絞り込み中の豆（記録に控えた名前で絞る。削除済みの豆でも絞れるように）
  String? _beanName;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final all = store.records;
    final names = {for (final r in all) r.beanName}.toList();
    final filter = names.contains(_beanName) ? _beanName : null;
    final records = filter == null
        ? all
        : [
            for (final r in all)
              if (r.beanName == filter) r,
          ];

    return Scaffold(
      appBar: AppBar(title: const Text('記録'), actions: const [SettingsButton()]),
      body: all.isEmpty
          ? EmptyState(
              title: 'まだ記録がありません',
              message: '「淹れる」でタイマーを使って抽出すると、\n終わったあとに評価を記録できます。',
              actionLabel: '淹れにいく',
              onAction: () => HomeShell.selectTab(context, HomeShell.brewTab),
            )
          : CustomScrollView(
              slivers: [
                if (names.length > 1)
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, Space.sm),
                      child: Row(
                        spacing: Space.sm,
                        children: [
                          ChoiceChip(
                            label: const Text('すべて'),
                            selected: filter == null,
                            onSelected: (_) => setState(() => _beanName = null),
                          ),
                          for (final n in names)
                            ChoiceChip(
                              label: Text(n),
                              selected: n == filter,
                              onSelected: (on) => setState(() => _beanName = on ? n : null),
                            ),
                        ],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
                  sliver: SliverList.separated(
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                    itemBuilder: (context, i) => FadeIn(
                      key: ValueKey(records[i].id),
                      child: _RecordTile(record: records[i]),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final BrewRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = record.recipe;
    return Dismissible(
      key: ValueKey('dismiss-${record.id}'),
      direction: DismissDirection.endToStart,
      background: const DeleteBackground(),
      onDismissed: (_) => deleteRecordWithUndo(context, record),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => RecordDetailScreen(recordId: record.id))),
          title: Text(record.beanName, style: theme.textTheme.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Text('${formatDateTime(record.brewedAt)} ・ ${r.beanGrams} g / ${r.waterMl} ml'),
          ),
          trailing: StarRatingView(value: record.rating),
        ),
      ),
    );
  }
}

/// 記録を削除し、元に戻せるスナックバーを出す
void deleteRecordWithUndo(BuildContext context, BrewRecord record) {
  final store = AppScope.read(context);
  final removed = store.deleteRecord(record.id);
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: const Text('記録を削除しました'),
      action: removed == null
          ? null
          : SnackBarAction(label: '元に戻す', onPressed: () => store.restoreRecord(removed.$1, removed.$2)),
    ),
  );
}
