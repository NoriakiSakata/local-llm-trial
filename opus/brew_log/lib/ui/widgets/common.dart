import 'package:material_ui/material_ui.dart';

import '../settings/settings_screen.dart';
import '../theme/tokens.dart';

/// 各タブの AppBar 右上に置く設定ボタン
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: '設定',
    icon: const Icon(Icons.settings_outlined),
    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
  );
}

/// 小見出し
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xs, Space.lg, Space.xs, Space.sm),
      child: Text(text, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
    );
  }
}

/// リストの各行を、表示時にふわっと出す
class FadeIn extends StatelessWidget {
  const FadeIn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Motion.medium,
    curve: Motion.curve,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
    ),
    child: child,
  );
}

/// スワイプ削除の背景
class DeleteBackground extends StatelessWidget {
  const DeleteBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: Corner.all(Corner.md)),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
    );
  }
}

/// 確認ダイアログ。OK なら true
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String okLabel,
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive ? TextButton.styleFrom(foregroundColor: scheme.error) : null,
          child: Text(okLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}
