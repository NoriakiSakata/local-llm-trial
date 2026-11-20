import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_info.dart';
import '../../application/app_data.dart';
import '../../application/providers.dart';
import '../../data/state_store.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/feedback.dart';

/// 設定。テーマ切替と、全データの削除、保存状態の確認ができる。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppState data = ref.watch(appDataProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          children: <Widget>[
            SectionHeader(title: '外観'),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('テーマ', style: text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const <ButtonSegment<ThemeMode>>[
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text('システム'),
                          icon: Icon(Icons.brightness_auto_outlined),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          label: Text('ライト'),
                          icon: Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          label: Text('ダーク'),
                          icon: Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: <ThemeMode>{data.settings.themeMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (Set<ThemeMode> value) => ref
                          .read(appDataProvider.notifier)
                          .setThemeMode(value.first),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '「システム」を選ぶと、端末のライト／ダーク設定に追従します。',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ThemePreviewRow(current: data.settings.themeMode),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            SectionHeader(title: 'データ'),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _InfoRow(
                    icon: Icons.eco_outlined,
                    label: '登録済みの豆',
                    value: '${data.beans.length} 件',
                  ),
                  _InfoRow(
                    icon: Icons.menu_book_outlined,
                    label: 'レシピ',
                    value: '${data.recipes.length} 件',
                  ),
                  _InfoRow(
                    icon: Icons.receipt_long_outlined,
                    label: '抽出記録',
                    value: '${data.extractions.length} 件',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '記録はこの端末の中にだけ保存されます。通信やアカウント認証は一切使いません。',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (data.failure != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _StoreFailureCard(failure: data.failure!),
            ],
            if (data.persistenceSuspended) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                '自動保存は停止中です。このまま変更すると、アプリ終了後に失われます。',
                style: text.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),

            SectionHeader(title: 'リセット'),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '豆・レシピ・抽出記録をすべて削除します。この操作は取り消せません。',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: () => _clearAll(context, ref, data),
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('全データを削除'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(
                        color: scheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            SectionHeader(title: 'このアプリについて'),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Brew Log — ハンドドリップ珈琲の抽出タイマー＆記録',
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'バージョン $kAppVersionLabel · 保存は端末内のみ（Offline only）',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearAll(
    BuildContext context,
    WidgetRef ref,
    AppState data,
  ) async {
    if (!data.hasData) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('削除対象のデータはありません')));
      return;
    }
    final bool ok = await confirmAction(
      context,
      title: '全データを削除しますか？',
      message:
          '豆 ${data.beans.length} 件・レシピ ${data.recipes.length} 件・'
          '記録 ${data.extractions.length} 件を削除します。\n取り消しはできません。',
      confirmLabel: 'すべて削除',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(appDataProvider.notifier).clearAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('全データを削除しました')));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Icon(icon, size: AppSize.iconMedium, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: text.bodyMedium)),
          Text(
            value,
            style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 保存データに起きた問題の設定画面での詳細表示。
class _StoreFailureCard extends StatelessWidget {
  const _StoreFailureCard({required this.failure});

  final StoreFailure failure;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.report_problem_outlined, color: scheme.error),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  '保存データの状態：${failure.headline}',
                  style: text.titleSmall?.copyWith(color: scheme.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(failure.message, style: text.bodyMedium),
          if (failure.backupKey != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '退避キー: ${failure.backupKey}',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (failure.detail != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              failure.detail!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// ライト／ダークの見本を並べて、選びながら確認できるようにする。
class _ThemePreviewRow extends StatelessWidget {
  const _ThemePreviewRow({required this.current});

  final ThemeMode current;

  @override
  Widget build(BuildContext context) {
    // 「システム」のときは、実際に効いている方の見本を強調する。
    final Brightness platform = MediaQuery.platformBrightnessOf(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: _PreviewTile(
            theme: AppTheme.light(),
            mode: ThemeMode.light,
            active: _isActive(ThemeMode.light, platform),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _PreviewTile(
            theme: AppTheme.dark(),
            mode: ThemeMode.dark,
            active: _isActive(ThemeMode.dark, platform),
          ),
        ),
      ],
    );
  }

  bool _isActive(ThemeMode mode, Brightness platform) {
    if (current == mode) return true;
    if (current != ThemeMode.system) return false;
    return mode ==
        switch (platform) {
          Brightness.dark => ThemeMode.dark,
          _ => ThemeMode.light,
        };
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.theme,
    required this.mode,
    required this.active,
  });

  final ThemeData theme;
  final ThemeMode mode;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = theme.colorScheme;
    return AnimatedContainer(
      duration: AppMotion.normal,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: active ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: AppRadius.chipRadius,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: AppRadius.chipRadius,
                ),
              ),
              const Spacer(),
              Icon(
                mode == ThemeMode.light
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                size: AppSize.iconSmall,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            mode == ThemeMode.light ? 'ライト' : 'ダーク',
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurface,
            ),
          ),
          Text(
            '04:20 · 240 ml',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
