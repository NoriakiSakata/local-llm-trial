import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../state/app_store.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _deleteAll(BuildContext context) async {
    final store = AppScope.read(context);
    final ok = await confirm(
      context,
      title: 'すべてのデータを削除しますか？',
      message: '豆 ${store.beans.length} 件と記録 ${store.records.length} 件を削除します。元に戻せません。',
      okLabel: 'すべて削除',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await store.deleteAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('すべてのデータを削除しました')));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Space.md),
        children: [
          const SectionLabel('テーマ'),
          SegmentedButton<AppThemePreference>(
            segments: const [
              ButtonSegment(value: AppThemePreference.light, label: Text('ライト'), icon: Icon(Icons.light_mode_outlined)),
              ButtonSegment(value: AppThemePreference.dark, label: Text('ダーク'), icon: Icon(Icons.dark_mode_outlined)),
              ButtonSegment(
                value: AppThemePreference.system,
                label: Text('システム'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
            ],
            selected: {store.data.theme},
            showSelectedIcon: false,
            onSelectionChanged: (s) => store.setTheme(s.first),
          ),
          const SectionLabel('データ'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
              title: Text('すべてのデータを削除', style: TextStyle(color: scheme.error)),
              subtitle: const Text('豆・記録・前回のレシピを消します'),
              onTap: () => _deleteAll(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Text(
              'データはこの端末の中だけに保存され、外部には送信されません。',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
