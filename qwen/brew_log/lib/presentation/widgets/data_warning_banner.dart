import 'package:flutter/material.dart';

import '../../data/state_store.dart';
import '../../theme/tokens.dart';

/// 保存データに問題があったことを全画面の上部に出す警告。
///
/// データが読めなくてもアプリは使えるので、モーダルで塞がず、
/// 閉じられるバナーにしている。
class DataWarningBanner extends StatelessWidget {
  const DataWarningBanner({
    required this.failure,
    required this.onDismiss,
    required this.onOpenDetails,
    super.key,
  });

  final StoreFailure failure;
  final VoidCallback onDismiss;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: AppRadius.cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.report_problem_outlined,
                  size: AppSize.iconMedium,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        failure.headline,
                        style: text.titleSmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        failure.message,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  tooltip: 'この警告を閉じる',
                  icon: const Icon(Icons.close_rounded),
                  color: scheme.onErrorContainer,
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenDetails,
                child: const Text('詳しく見る'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
