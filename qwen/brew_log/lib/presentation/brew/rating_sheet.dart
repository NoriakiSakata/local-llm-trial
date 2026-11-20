import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/app_data.dart';
import '../../application/brew_record.dart';
import '../../application/brew_session.dart';
import '../../application/providers.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../widgets/rating_stars.dart';

/// 抽出が終わった直後に開く、評価と味のメモの入力シート。
class RatingSheet extends ConsumerStatefulWidget {
  const RatingSheet({required this.session, super.key});

  final BrewSession session;

  @override
  ConsumerState<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<RatingSheet> {
  int _rating = 3;
  double _acidity = 0.5;
  double _bitterness = 0.5;
  double _sweetness = 0.5;
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final AppDataNotifier data = ref.read(appDataProvider.notifier);
    final Bean? bean = data.beanById(widget.session.recipe.beanId);
    final Extraction extraction = buildExtraction(
      session: widget.session,
      bean: bean,
      rating: _rating,
      taste: TasteProfile(
        acidity: _acidity,
        bitterness: _bitterness,
        sweetness: _sweetness,
      ),
      note: _note.text,
      brewedAt: ref.read(clockProvider).now(),
    );
    data.addExtraction(extraction);
    ref.read(brewSessionProvider.notifier).completeAndClear();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('記録を保存しました')));
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BrewSession session = widget.session;
    final Duration spent = Duration(
      milliseconds: session.marks.isEmpty
          ? session.plan.totalMs
          : session.marks.last.elapsedMs,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('淹れました', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${session.recipe.name} · 所要 ${formatDurationJa(spent)}',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('評価', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            RatingInput(
              value: _rating,
              onChanged: (int value) => setState(() => _rating = value),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('味の特徴', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TasteSlider(
              label: '酸味',
              value: _acidity,
              onChanged: (double v) => setState(() => _acidity = v),
            ),
            TasteSlider(
              label: '苦味',
              value: _bitterness,
              onChanged: (double v) => setState(() => _bitterness = v),
            ),
            TasteSlider(
              label: '甘み',
              value: _sweetness,
              onChanged: (double v) => setState(() => _sweetness = v),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('メモ', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '香りの印象、挽目、次回の変えたい点など',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              ),
              child: const Text('保存して完了'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {
                ref.read(brewSessionProvider.notifier).completeAndClear();
                Navigator.of(context).pop();
              },
              child: const Text('記録せず終了'),
            ),
          ],
        ),
      ),
    );
  }
}
