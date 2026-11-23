import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../../state/app_providers.dart';

/// データの読み込み・保存で問題があったときに画面上部に出すバナー。
class StorageIssueBanner extends ConsumerWidget {
  const StorageIssueBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(storageIssuesProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: issues.isEmpty
          ? const SizedBox(width: double.infinity)
          : Material(
              color: scheme.errorContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    AppSpace.md,
                    AppSpace.sm,
                    AppSpace.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.xs),
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final issue in issues)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpace.xs,
                                ),
                                child: Text(
                                  issue.message,
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color: scheme.onErrorContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(storageIssuesProvider.notifier)
                            .dismissAll(),
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.onErrorContainer,
                        ),
                        child: const Text('閉じる'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
