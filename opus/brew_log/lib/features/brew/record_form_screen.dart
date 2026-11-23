import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../../data/models/bean.dart';
import '../../data/models/brew_record.dart';
import '../../data/models/recipe.dart';
import '../../state/app_providers.dart';
import '../../ui/format.dart';
import '../../ui/id.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/rating.dart';

/// タイマー終了後の記録入力。評価・味のスライダー・自由記述を保存する。
class RecordFormScreen extends ConsumerStatefulWidget {
  const RecordFormScreen({
    super.key,
    required this.recipe,
    required this.bean,
    required this.elapsedSec,
  });

  final Recipe recipe;
  final Bean? bean;
  final int elapsedSec;

  @override
  ConsumerState<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends ConsumerState<RecordFormScreen> {
  final _note = TextEditingController();
  int _rating = 0;
  final Map<TasteAxis, int> _taste = {
    for (final axis in TasteAxis.values) axis: 3,
  };

  static const _levelLabels = ['とても弱い', '弱い', 'ふつう', '強い', 'とても強い'];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final record = BrewRecord(
      id: newId(),
      beanId: widget.bean?.id,
      beanName: widget.bean?.name ?? '豆の指定なし',
      recipe: widget.recipe,
      brewedAt: DateTime.now(),
      elapsedSec: widget.elapsedSec,
      rating: _rating,
      acidity: _taste[TasteAxis.acidity]!,
      bitterness: _taste[TasteAxis.bitterness]!,
      sweetness: _taste[TasteAxis.sweetness]!,
      note: _note.text.trim(),
    );
    await ref.read(recordsProvider.notifier).add(record);
    if (!mounted) return;
    ref.read(homeTabProvider.notifier).select(HomeTab.history);
    Navigator.of(context).pop();
    showMessageSnackBar(context, '記録を保存しました');
  }

  Future<void> _discard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('記録せずに閉じますか？'),
        content: const Text('入力した内容は保存されません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('戻る'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = widget.recipe;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _discard();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: '閉じる',
            icon: const Icon(Icons.close_rounded),
            onPressed: _discard,
          ),
          title: const Text('味を記録'),
        ),
        body: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.sm,
              AppSpace.screen,
              AppSpace.xxl,
            ),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.bean?.name ?? '豆の指定なし',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Wrap(
                        spacing: AppSpace.lg,
                        runSpacing: AppSpace.xs,
                        children: [
                          MetaChip(
                            icon: Icons.scale_outlined,
                            label: '${r.doseG}g',
                          ),
                          MetaChip(
                            icon: Icons.water_drop_outlined,
                            label: '${r.waterMl}ml',
                          ),
                          MetaChip(
                            icon: Icons.thermostat_outlined,
                            label: '${r.tempC}℃',
                          ),
                          MetaChip(
                            icon: Icons.timer_outlined,
                            label: Fmt.mmss(
                              Duration(seconds: widget.elapsedSec),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SectionLabel('評価'),
              StarRatingInput(
                value: _rating,
                onChanged: (v) => setState(() => _rating = v),
              ),
              AnimatedOpacity(
                opacity: _rating == 0 ? 1 : 0,
                duration: AppMotion.short,
                child: Text(
                  '星をタップして評価してください',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SectionLabel('味のバランス'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    AppSpace.md,
                    AppSpace.lg,
                    AppSpace.sm,
                  ),
                  child: Column(
                    children: [
                      for (final axis in TasteAxis.values)
                        _TasteSlider(
                          axis: axis,
                          value: _taste[axis]!,
                          levelLabel: _levelLabels[_taste[axis]! - 1],
                          onChanged: (v) => setState(() => _taste[axis] = v),
                        ),
                    ],
                  ),
                ),
              ),
              const SectionLabel('メモ'),
              TextField(
                controller: _note,
                minLines: 3,
                maxLines: 8,
                maxLength: 600,
                decoration: const InputDecoration(hintText: '香り、後味、次に変えたいことなど'),
              ),
              const SizedBox(height: AppSpace.xl),
              FilledButton(
                key: const ValueKey('save-record'),
                onPressed: _rating == 0 ? null : _save,
                child: const Text('記録を保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TasteSlider extends StatelessWidget {
  const _TasteSlider({
    required this.axis,
    required this.value,
    required this.levelLabel,
    required this.onChanged,
  });

  final TasteAxis axis;
  final int value;
  final String levelLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(axis.label, style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(
              levelLabel,
              style: theme.textTheme.labelMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Slider(
          key: ValueKey('taste-${axis.name}'),
          value: value.toDouble(),
          min: TasteAxis.min.toDouble(),
          max: TasteAxis.max.toDouble(),
          divisions: TasteAxis.max - TasteAxis.min,
          label: '$value',
          semanticFormatterCallback: (v) => '${axis.label} ${v.round()}',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
