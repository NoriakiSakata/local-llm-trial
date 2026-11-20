import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../state/app_store.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/empty_state.dart';
import 'bean_edit_screen.dart';

class BeansScreen extends StatelessWidget {
  const BeansScreen({super.key});

  static Future<void> openEditor(BuildContext context, [Bean? bean]) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BeanEditScreen(bean: bean),
      fullscreenDialog: bean == null,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final beans = store.beans;
    return Scaffold(
      appBar: AppBar(title: const Text('豆'), actions: const [SettingsButton()]),
      floatingActionButton: beans.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => openEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('豆を追加'),
            ),
      body: beans.isEmpty
          ? EmptyState(
              title: 'まだ豆が登録されていません',
              message: '手元の豆を登録すると、焙煎からの日数や\n豆ごとの評価を記録できます。',
              actionLabel: '最初の豆を登録する',
              onAction: () => openEditor(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 96),
              itemCount: beans.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
              itemBuilder: (context, i) => FadeIn(
                key: ValueKey(beans[i].id),
                child: _BeanTile(bean: beans[i], today: store.clock()),
              ),
            ),
    );
  }
}

class _BeanTile extends StatelessWidget {
  const _BeanTile({required this.bean, required this.today});

  final Bean bean;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = bean.daysSinceRoast(today);
    final subtitle = [if (bean.origin.isNotEmpty) bean.origin, bean.roast.label].join(' · ');
    return Dismissible(
      key: ValueKey('dismiss-${bean.id}'),
      direction: DismissDirection.endToStart,
      background: const DeleteBackground(),
      onDismissed: (_) {
        final store = AppScope.read(context);
        final removed = store.deleteBean(bean.id);
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('「${bean.name}」を削除しました'),
            action: removed == null
                ? null
                : SnackBarAction(label: '元に戻す', onPressed: () => store.restoreBean(removed.$1, removed.$2)),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => BeansScreen.openEditor(context, bean),
          title: Text(bean.name, style: theme.textTheme.titleMedium),
          subtitle: Text(subtitle),
          trailing: days == null ? null : _RoastAge(days: days),
        ),
      ),
    );
  }
}

/// 焙煎からの経過日数。飲み頃（3〜30日）を外れたら色を変える
class _RoastAge extends StatelessWidget {
  const _RoastAge({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inWindow = days >= 3 && days <= 30;
    final label = days < 0 ? '焙煎前' : '焙煎から';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${days.abs()}', style: theme.textTheme.titleLarge),
              TextSpan(text: ' 日', style: theme.textTheme.labelMedium),
            ],
          ),
          style: TextStyle(color: inWindow ? scheme.primary : scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
