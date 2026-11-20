import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/app_data.dart';
import '../../application/providers.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../widgets/common.dart';
import '../widgets/empty_state.dart';
import '../widgets/feedback.dart';
import 'bean_editor_screen.dart';

/// 豆の一覧。焙煎日からの経過日数を常に表示する。
class BeansScreen extends ConsumerWidget {
  const BeansScreen({required this.onGoToTab, super.key});

  /// 空状態から他のタブへ飛ぶためのコールバック。
  final void Function(int index) onGoToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Bean> beans = ref.watch(appDataProvider).beans;
    final DateTime now = ref.watch(clockProvider).now();

    return Scaffold(
      floatingActionButton: beans.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(context, null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('豆を追加'),
            ),
      body: beans.isEmpty
          ? EmptyState(
              title: 'まだ豆が登録されていません',
              description: '豆を登録すると、焙煎からの経過日数を数えながら\nレシピを作れるようになります。',
              action: FilledButton.icon(
                onPressed: () => _openEditor(context, null),
                icon: const Icon(Icons.add_rounded),
                label: const Text('最初の豆を登録'),
              ),
              secondaryAction: TextButton(
                onPressed: () => onGoToTab(1),
                child: const Text('まずは淹れてみる'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.lg,
                AppSpacing.screen,
                AppSpacing.xxxl * 2,
              ),
              itemCount: beans.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int index) {
                final Bean bean = beans[index];
                return FadeSlideIn(
                  delayMs: (index * 24).clamp(0, 240),
                  child: _BeanCard(
                    bean: bean,
                    now: now,
                    onTap: () => _openEditor(context, bean),
                    onDeleted: () => _delete(context, ref, bean),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openEditor(BuildContext context, Bean? bean) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BeanEditorScreen(bean: bean)),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Bean bean) async {
    final bool ok = await confirmAction(
      context,
      title: '豆を削除しますか？',
      message: '「${bean.name}」を一覧から削除します。\nこの豆で淹れた記録は残りますが、豆名は記録時点のものが使われます。',
    );
    if (!ok || !context.mounted) return;

    final RemovedBean? removed = ref
        .read(appDataProvider.notifier)
        .removeBean(bean.id);
    if (removed == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        undoSnackBar(
          message: '${bean.name} を削除しました',
          actionLabel: '戻す',
          onUndo: () => ref.read(appDataProvider.notifier).restoreBean(removed),
        ),
      );
  }
}

class _BeanCard extends StatelessWidget {
  const _BeanCard({
    required this.bean,
    required this.now,
    required this.onTap,
    required this.onDeleted,
  });

  final Bean bean;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int days = bean.daysSinceRoast(now);

    return Dismissible(
      key: ValueKey<String>('bean-${bean.id}'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(bean.name, style: text.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _subtitle(),
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _AgeBadge(days: days),
                  ],
                ),
                if (bean.note.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    bean.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final List<String> parts = <String>[bean.roast.label];
    if (bean.origin.isNotEmpty) parts.insert(0, bean.origin);
    parts.add('焙煎 ${formatDateJa(bean.roastDate)}');
    return parts.join(' · ');
  }
}

/// 焙煎からの経過日数。鮮度の目安に色を変える。
class _AgeBadge extends StatelessWidget {
  const _AgeBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, String label) = switch (days) {
      < 3 => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        '焙煎 $days 日目',
      ),
      <= 21 => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        '焙煎 $days 日目',
      ),
      _ => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        '焙煎 $days 日目',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.chipRadius),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium!.copyWith(color: fg),
      ),
    );
  }
}
