import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../domain/brew_plan.dart';
import '../../state/app_store.dart';
import '../format.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/rating.dart';

/// 抽出が終わった後の評価入力
class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({super.key, required this.plan, required this.bean, required this.elapsed, this.onSaved});

  final BrewPlan plan;
  final Bean? bean;
  final Duration elapsed;
  final VoidCallback? onSaved;

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  int _rating = 0;
  int _acidity = 3;
  int _bitterness = 3;
  int _sweetness = 3;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final store = AppScope.read(context);
    store.addRecord(
      BrewRecord(
        id: store.newId(),
        brewedAt: store.clock(),
        beanId: widget.bean?.id,
        beanName: widget.bean?.name ?? '豆の指定なし',
        recipe: widget.plan.recipe,
        elapsedSeconds: widget.elapsed.inSeconds,
        rating: _rating,
        acidity: _acidity,
        bitterness: _bitterness,
        sweetness: _sweetness,
        note: _note.text.trim(),
      ),
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    widget.onSaved?.call();
    messenger.showSnackBar(const SnackBar(content: Text('記録しました')));
  }

  Future<void> _discard() async {
    final ok = await confirm(
      context,
      title: '記録せずに終えますか？',
      message: '今回の抽出は保存されません。',
      okLabel: '記録しない',
      destructive: true,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.plan.recipe;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _discard();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('今回の一杯')),
        body: ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            Text(widget.bean?.name ?? '豆の指定なし', style: theme.textTheme.headlineSmall),
            const SizedBox(height: Space.xs),
            Text(
              '${r.beanGrams} g ・ ${r.waterMl} ml ・ ${r.waterTempC} ℃ ・ ${formatClock(widget.elapsed)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SectionLabel('評価'),
            StarRatingInput(value: _rating, onChanged: (v) => setState(() => _rating = v)),
            if (_rating == 0) Text('★をタップして評価してください', style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
            const SectionLabel('味'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.sm),
                child: Column(
                  children: [
                    _TasteSlider(label: '酸味', value: _acidity, onChanged: (v) => setState(() => _acidity = v)),
                    _TasteSlider(label: '苦味', value: _bitterness, onChanged: (v) => setState(() => _bitterness = v)),
                    _TasteSlider(label: '甘み', value: _sweetness, onChanged: (v) => setState(() => _sweetness = v)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _note,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'メモ',
                hintText: '例：後味にベリー感。次は湯温を2℃下げる',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(onPressed: _rating == 0 ? null : _save, child: const Text('記録する')),
            const SizedBox(height: Space.sm),
            TextButton(onPressed: _discard, child: const Text('記録せずに終える')),
          ],
        ),
      ),
    );
  }
}

class _TasteSlider extends StatelessWidget {
  const _TasteSlider({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  static const _words = ['', 'とても弱い', '弱い', 'ふつう', '強い', 'とても強い'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(label, style: theme.textTheme.bodyLarge)),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _words[value],
              semanticFormatterCallback: (v) => '$label ${_words[v.round()]}',
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(_words[value], style: theme.textTheme.labelMedium, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
