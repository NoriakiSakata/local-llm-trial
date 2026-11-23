import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';

/// セクション見出し（オーバーライン）。labelSmall を大文字的に使う。
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.labelSmall!.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// 初回表示時に、少し下からフェードインさせる。リストの追加アニメーション用。
class EntranceAnimation extends StatelessWidget {
  const EntranceAnimation({super.key, required this.child, this.delay = 0});

  final Widget child;

  /// 0〜1。リスト内の順番に応じて少しずつ遅らせる。
  final double delay;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.long,
      curve: Interval(delay.clamp(0, 0.5), 1, curve: AppMotion.standard),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * AppSpace.lg),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// アイコン付きの小さなメタ情報（例: 🌡 92℃）
class MetaChip extends StatelessWidget {
  const MetaChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpace.xs),
        Text(label, style: theme.textTheme.labelMedium!.copyWith(color: color)),
      ],
    );
  }
}

/// 中身の最大幅を制限して中央に寄せる（タブレット・横向き対策）。
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    // 高さは子に合わせる（下部バーなどで縦いっぱいに広がらないように）
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSize.contentMaxWidth),
      child: child,
    ),
  );
}

/// 削除などの取り消し可能な操作の SnackBar。
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: '元に戻す', onPressed: onUndo),
      ),
    );
}

void showMessageSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
