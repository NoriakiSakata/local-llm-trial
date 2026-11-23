import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../../data/models/app_settings.dart';
import '../../state/app_providers.dart';
import '../../ui/widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final beans = ref.read(beansProvider).length;
    final records = ref.read(recordsProvider).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
          title: const Text('すべてのデータを削除しますか？'),
          content: Text(
            '豆 $beans 件と抽出記録 $records 件を削除します。'
            'この操作は取り消せません。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              key: const ValueKey('confirm-delete-all'),
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
                minimumSize: const Size(64, 40),
              ),
              child: const Text('削除する'),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    await clearAllData(ref);
    if (!context.mounted) return;
    showMessageSnackBar(context, 'すべてのデータを削除しました');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preference = ref.watch(settingsProvider.select((s) => s.theme));
    final hasData =
        ref.watch(beansProvider).isNotEmpty ||
        ref.watch(recordsProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            0,
            AppSpace.screen,
            AppSpace.xl,
          ),
          children: [
            const SectionLabel('テーマ'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemePreference>(
                segments: const [
                  ButtonSegment(
                    value: ThemePreference.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('ライト'),
                  ),
                  ButtonSegment(
                    value: ThemePreference.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('ダーク'),
                  ),
                  ButtonSegment(
                    value: ThemePreference.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('システム'),
                  ),
                ],
                selected: {preference},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    ref.read(settingsProvider.notifier).setTheme(s.first),
              ),
            ),
            const SectionLabel('データ'),
            Card(
              child: ListTile(
                key: const ValueKey('delete-all'),
                enabled: hasData,
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: hasData ? scheme.error : null,
                ),
                title: Text(
                  'すべてのデータを削除',
                  style: hasData
                      ? theme.textTheme.titleMedium!.copyWith(
                          color: scheme.error,
                        )
                      : null,
                ),
                subtitle: Text(
                  hasData ? '豆と抽出記録を削除します（テーマ設定は残ります）' : '削除するデータはありません',
                ),
                onTap: () => _confirmDeleteAll(context, ref),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
              child: Text(
                'Brew Log は通信を行いません。データはすべてこの端末の中に保存されます。',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
