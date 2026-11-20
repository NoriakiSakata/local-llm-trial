import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/brew_plan.dart';
import '../../application/providers.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../format.dart';
import '../widgets/common.dart';
import '../widgets/feedback.dart';
import '../widgets/rating_stars.dart';

/// 1件の抽出記録の詳細。条件・味・注湯タイムラインを並べる。
class ExtractionDetailScreen extends ConsumerWidget {
  const ExtractionDetailScreen({required this.extraction, super.key});

  final Extraction extraction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Extraction current = ref
        .watch(appDataProvider)
        .extractions
        .firstWhere(
          (Extraction e) => e.id == extraction.id,
          orElse: () => extraction,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('記録の詳細'),
        actions: <Widget>[
          IconButton(
            tooltip: '削除',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _delete(context, ref, current),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          children: <Widget>[
            Text(current.beanName, style: text.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatFullDateTimeJa(current.brewedAt) +
                  (current.recipeName == null
                      ? ''
                      : ' · ${current.recipeName}'),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                RatingStars(rating: current.rating, size: 26),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${current.rating}.0',
                  style: AppTypography.numeric(
                    text.titleMedium!.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            SectionHeader(title: '抽出条件'),
            SectionCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      InfoPill(
                        label: '豆量',
                        value: '${_grams(current.beanAmountG)} g',
                      ),
                      InfoPill(label: '湯量', value: '${current.waterMl} ml'),
                      InfoPill(label: '湯温', value: '${current.tempC} ℃'),
                      InfoPill(
                        label: '所要',
                        value: formatDurationJa(
                          Duration(seconds: current.totalSeconds),
                        ),
                      ),
                    ],
                  ),
                  if (current.pours.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text('注湯タイムライン', style: text.titleSmall),
                    const SizedBox(height: AppSpacing.md),
                    _PourTimeline(pours: current.pours),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            SectionHeader(title: '味'),
            SectionCard(child: TasteReadout(taste: current.taste)),
            const SizedBox(height: AppSpacing.xxl),

            SectionHeader(title: 'メモ'),
            SectionCard(
              child: Text(
                current.note.isEmpty ? 'メモはありません' : current.note,
                style: text.bodyMedium?.copyWith(
                  color: current.note.isEmpty
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _grams(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Extraction item,
  ) async {
    final bool ok = await confirmAction(
      context,
      title: 'この記録を削除しますか？',
      message: '${formatFullDateTimeJa(item.brewedAt)} の記録を削除します。',
    );
    if (!ok) return;
    final int index = ref
        .read(appDataProvider)
        .extractions
        .indexWhere((Extraction e) => e.id == item.id);
    final Extraction? removed = ref
        .read(appDataProvider.notifier)
        .removeExtraction(item.id);
    if (!context.mounted) return;
    if (removed == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        undoSnackBar(
          message: '記録を削除しました',
          actionLabel: '戻す',
          onUndo: () => ref
              .read(appDataProvider.notifier)
              .restoreExtraction(removed, index),
        ),
      );
  }
}

class _PourTimeline extends StatelessWidget {
  const _PourTimeline({required this.pours});

  final List<PourLog> pours;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        for (int i = 0; i < pours.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // 時間軸のレール
              SizedBox(
                width: 52,
                child: Text(
                  formatClock(Duration(milliseconds: pours[i].elapsedMs)),
                  textAlign: TextAlign.right,
                  style: AppTypography.numeric(
                    text.labelMedium!.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 0
                          ? scheme.primary
                          : scheme.secondaryContainer,
                      border: Border.all(color: scheme.primary, width: 1.5),
                    ),
                  ),
                  if (i != pours.length - 1)
                    Container(
                      width: 1.5,
                      height: 34,
                      color: scheme.outlineVariant,
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(pours[i].label, style: text.titleSmall),
                      ),
                      Text(
                        '${pours[i].targetCumMl} ml',
                        style: AppTypography.numeric(
                          text.bodyMedium!.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
