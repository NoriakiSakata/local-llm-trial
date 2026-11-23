import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../../data/models/bean.dart';
import '../../state/app_providers.dart';
import '../../ui/widgets/coffee_illustration.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/settings_action.dart';
import 'bean_edit_screen.dart';
import 'roast_badge.dart';

class BeanListScreen extends ConsumerWidget {
  const BeanListScreen({super.key});

  void _openEditor(BuildContext context, [Bean? bean]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: bean == null,
        builder: (_) => BeanEditScreen(initial: bean),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beans = ref.watch(beansProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('豆'), actions: const [SettingsAction()]),
      floatingActionButton: beans.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('豆を登録'),
            ),
      body: beans.isEmpty
          ? EmptyState(
              illustration: CoffeeIllustrationKind.bean,
              title: 'まだ豆が登録されていません',
              message: '手元の豆を登録すると、焙煎からの日数や\n豆ごとの評価が分かるようになります。',
              actionLabel: '最初の豆を登録',
              onAction: () => _openEditor(context),
            )
          : ContentWidth(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.sm,
                  AppSpace.screen,
                  AppSpace.xxxl + AppSpace.xxl,
                ),
                itemCount: beans.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
                itemBuilder: (context, i) {
                  final bean = beans[i];
                  return EntranceAnimation(
                    key: ValueKey(bean.id),
                    delay: (i * 0.06).clamp(0, 0.4),
                    child: Dismissible(
                      key: ValueKey('dismiss-${bean.id}'),
                      direction: DismissDirection.endToStart,
                      background: const _DeleteBackground(),
                      onDismissed: (_) async {
                        final index = await ref
                            .read(beansProvider.notifier)
                            .remove(bean.id);
                        if (!context.mounted) return;
                        showUndoSnackBar(
                          context,
                          message: '「${bean.name}」を削除しました',
                          onUndo: () => ref
                              .read(beansProvider.notifier)
                              .restore(bean, index),
                        );
                      },
                      child: _BeanCard(
                        bean: bean,
                        now: now,
                        onTap: () => _openEditor(context, bean),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _BeanCard extends StatelessWidget {
  const _BeanCard({required this.bean, required this.now, required this.onTap});

  final Bean bean;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final days = bean.daysSinceRoast(now);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bean.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Wrap(
                      spacing: AppSpace.md,
                      runSpacing: AppSpace.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RoastBadge(roast: bean.roast),
                        if (bean.origin.isNotEmpty)
                          MetaChip(
                            icon: Icons.place_outlined,
                            label: bean.origin,
                          ),
                      ],
                    ),
                    if (bean.memo.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        bean.memo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              _DaysBadge(days: days),
            ],
          ),
        ),
      ),
    );
  }
}

/// 焙煎からの経過日数。数字を主役にして一覧で比較しやすくする。
class _DaysBadge extends StatelessWidget {
  const _DaysBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final future = days < 0;
    return Semantics(
      label: future ? '焙煎日が未来です' : '焙煎から$days日',
      child: ExcludeSemantics(
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: AppRadius.smAll,
          ),
          child: Column(
            children: [
              Text(
                '焙煎から',
                style: theme.textTheme.labelSmall!.copyWith(
                  color: scheme.onSecondaryContainer,
                  letterSpacing: 0,
                ),
              ),
              Text(
                future ? '—' : '$days',
                style: theme.textTheme.headlineSmall!.copyWith(
                  color: scheme.onSecondaryContainer,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '日',
                style: theme.textTheme.labelSmall!.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppRadius.mdAll,
      ),
      child: Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
    );
  }
}
