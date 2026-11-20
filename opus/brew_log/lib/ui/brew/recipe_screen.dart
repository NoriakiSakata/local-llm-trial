import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../domain/brew_plan.dart';
import '../../state/app_store.dart';
import '../beans/beans_screen.dart';
import '../format.dart';
import '../home_shell.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'timer_screen.dart';

/// 淹れる：豆とレシピを決めてタイマーを始める
class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  late Recipe _recipe = AppScope.read(context).data.lastRecipe;
  String? _beanId;

  @override
  void initState() {
    super.initState();
    final records = AppScope.read(context).records;
    // 前回淹れた豆を初期選択にする
    _beanId = records.isEmpty ? null : records.first.beanId;
  }

  void _start(Bean? bean) {
    final store = AppScope.read(context);
    store.setLastRecipe(_recipe);
    final shell = context;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TimerScreen(
          plan: BrewPlan.fromRecipe(_recipe),
          bean: bean,
          onRecorded: () => HomeShell.selectTab(shell, HomeShell.historyTab),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final theme = Theme.of(context);
    final bean = store.beanById(_beanId);
    final plan = BrewPlan.fromRecipe(_recipe);

    return Scaffold(
      appBar: AppBar(title: const Text('淹れる'), actions: const [SettingsButton()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
        children: [
          const SectionLabel('豆'),
          _BeanPicker(beans: store.beans, selectedId: bean?.id, onSelected: (id) => setState(() => _beanId = id)),
          const SectionLabel('レシピ'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Column(
                children: [
                  _Stepper(
                    label: '豆の量',
                    value: _recipe.beanGrams,
                    unit: 'g',
                    min: 5,
                    max: 60,
                    onChanged: (v) => setState(() => _recipe = _recipe.copyWith(beanGrams: v)),
                  ),
                  _Stepper(
                    label: '湯量',
                    value: _recipe.waterMl,
                    unit: 'ml',
                    min: 60,
                    max: 1000,
                    step: 10,
                    onChanged: (v) => setState(() => _recipe = _recipe.copyWith(waterMl: v)),
                  ),
                  _Stepper(
                    label: '湯温',
                    value: _recipe.waterTempC,
                    unit: '℃',
                    min: 70,
                    max: 100,
                    onChanged: (v) => setState(() => _recipe = _recipe.copyWith(waterTempC: v)),
                  ),
                  _Stepper(
                    label: '蒸らし',
                    value: _recipe.bloomSeconds,
                    unit: '秒',
                    min: 0,
                    max: 90,
                    step: 5,
                    onChanged: (v) => setState(() => _recipe = _recipe.copyWith(bloomSeconds: v)),
                  ),
                  _Stepper(
                    label: '注湯回数',
                    value: _recipe.pours,
                    unit: '回',
                    min: 1,
                    max: 6,
                    onChanged: (v) => setState(() => _recipe = _recipe.copyWith(pours: v)),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: Space.sm),
            child: Text(
              '比率 1:${_recipe.ratio.toStringAsFixed(1)} ・ 所要 ${formatClock(plan.total)}',
              style: theme.textTheme.labelMedium?.tabular.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SectionLabel('ステップ'),
          _StepPreview(plan: plan),
          const SizedBox(height: Space.lg),
          FilledButton.icon(
            onPressed: () => _start(bean),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('抽出を始める'),
          ),
        ],
      ),
    );
  }
}

class _BeanPicker extends StatelessWidget {
  const _BeanPicker({required this.beans, required this.selectedId, required this.onSelected});

  final List<Bean> beans;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (beans.isEmpty) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: const Icon(Icons.grain),
          title: const Text('豆が未登録です'),
          subtitle: const Text('登録しなくても淹れられます。記録を豆ごとに見返すなら登録を。'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => BeansScreen.openEditor(context),
        ),
      );
    }
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        for (final b in beans)
          ChoiceChip(
            label: Text(b.name),
            selected: b.id == selectedId,
            onSelected: (on) => onSelected(on ? b.id : null),
          ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          IconButton.filledTonal(
            tooltip: '$labelを減らす',
            onPressed: value - step >= min ? () => onChanged(value - step) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 84,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$value', style: theme.textTheme.titleLarge?.tabular),
                  TextSpan(text: ' $unit', style: theme.textTheme.labelMedium),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton.filledTonal(
            tooltip: '$labelを増やす',
            onPressed: value + step <= max ? () => onChanged(value + step) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _StepPreview extends StatelessWidget {
  const _StepPreview({required this.plan});
  final BrewPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.tabular.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          children: [
            for (final s in plan.steps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(formatClock(Duration(seconds: s.startSecond)), style: muted),
                    ),
                    Expanded(child: Text(s.label, style: theme.textTheme.bodyLarge)),
                    Text(
                      s.kind == BrewStepKind.drain ? '待つ' : '累計 ${s.targetTotalMl} ml',
                      style: theme.textTheme.bodyMedium?.tabular,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
