import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 「削除しました」+ Undo のスナックバー共通形。
SnackBar undoSnackBar({
  required String message,
  required String actionLabel,
  required VoidCallback onUndo,
}) {
  return SnackBar(
    content: Text(message),
    action: SnackBarAction(label: actionLabel, onPressed: onUndo),
    duration: const Duration(seconds: 5),
  );
}

/// 確認ダイアログ。true が返ったときだけ実行する。
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '削除する',
  bool destructive = false,
}) async {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('やめる'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
