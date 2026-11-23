import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../../data/models/bean.dart';
import '../../data/models/recipe.dart';
import '../../domain/brew_schedule.dart';
import '../../state/app_providers.dart';
import '../../ui/format.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/settings_action.dart';
import 'timer_screen.dart';
import 'value_stepper.dart';

/// 抽出タブ。豆とレシピを決めてタイマーを始める。
class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key});

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  late Recipe _recipe = ref.read(settingsProvider).lastRecipe;
  String? _beanId;

  void _update(Recipe recipe) => setState(() => _recipe = recipe);

  void _start(Bean? bean) {
    ref.read(settingsProvider.notifier).setLastRecipe(_recipe);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => TimerScreen(recipe: _recipe, bean: bean),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final beans = ref.watch(beansProvider);
    // 選択中の豆が削除された場合は未選択に戻す
    Bean? bean;
    for (final b in beans) {
      if (b.id == _beanId) bean = b;
    }
    final schedule = BrewSchedule.fromRecipe(_recipe);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('抽出'),
        actions: const [SettingsAction()],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            0,
            AppSpace.screen,
            AppSpace.lg,
          ),
          children: [
            const SectionLabel('豆'),
            if (beans.isEmpty)
              _NoBeanHint(
                onRegister: () =>
                    ref.read(homeTabProvider.notifier).select(HomeTab.beans),
              )
            else
              _BeanPicker(
                beans: beans,
                selectedId: bean?.id,
                onSelected: (id) => setState(() => _beanId = id),
              ),
            SectionLabel(
              'レシピ',
              trailing: Text(
                '比率 1:${_recipe.ratio.toStringAsFixed(1)}',
                style: theme.textTheme.labelMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.sm,
                ),
                child: Column(
                  children: [
                    ValueStepper(
                      label: '豆の量',
                      icon: Icons.scale_outlined,
                      value: _recipe.doseG,
                      unit: 'g',
                      min: Recipe.doseRange.min,
                      max: Recipe.doseRange.max,
                      step: 1,
                      onChanged: (v) => _update(_recipe.copyWith(doseG: v)),
                    ),
                    ValueStepper(
                      label: '湯量',
                      icon: Icons.water_drop_outlined,
                      value: _recipe.waterMl,
                      unit: 'ml',
                      min: Recipe.waterRange.min,
                      max: Recipe.waterRange.max,
                      step: 10,
                      onChanged: (v) => _update(_recipe.copyWith(waterMl: v)),
                    ),
                    ValueStepper(
                      label: '湯温',
                      icon: Icons.thermostat_outlined,
                      value: _recipe.tempC,
                      unit: '℃',
                      min: Recipe.tempRange.min,
                      max: Recipe.tempRange.max,
                      step: 1,
                      onChanged: (v) => _update(_recipe.copyWith(tempC: v)),
                    ),
                    const Divider(height: AppSpace.lg),
                    ValueStepper(
                      label: '蒸らし',
                      icon: Icons.hourglass_bottom_rounded,
                      value: _recipe.bloomSec,
                      unit: '秒',
                      min: Recipe.bloomRange.min,
                      max: Recipe.bloomRange.max,
                      step: 5,
                      onChanged: (v) => _update(_recipe.copyWith(bloomSec: v)),
                    ),
                    ValueStepper(
                      label: '注湯回数',
                      icon: Icons.repeat_rounded,
                      value: _recipe.pours,
                      unit: '回',
                      min: Recipe.poursRange.min,
                      max: Recipe.poursRange.max,
                      step: 1,
                      onChanged: (v) => _update(_recipe.copyWith(pours: v)),
                    ),
                    ValueStepper(
                      label: '投の間隔',
                      icon: Icons.timer_outlined,
                      value: _recipe.pourIntervalSec,
                      unit: '秒',
                      min: Recipe.intervalRange.min,
                      max: Recipe.intervalRange.max,
                      step: 5,
                      onChanged: (v) =>
                          _update(_recipe.copyWith(pourIntervalSec: v)),
                    ),
                  ],
                ),
              ),
            ),
            SectionLabel(
              '流れ',
              trailing: Text(
                '合計 ${Fmt.mmss(schedule.total)}',
                style: theme.textTheme.labelMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            _SchedulePreview(schedule: schedule),
          ],
        ),
      ),
      // 開始ボタンはスクロールしても常に見える位置に固定する
      bottomNavigationBar: _StartBar(
        summary:
            '${_recipe.doseG}g ・ ${_recipe.waterMl}ml ・ '
            '${Fmt.mmss(schedule.total)}',
        onStart: () => _start(bean),
      ),
    );
  }
}

class _BeanPicker extends StatelessWidget {
  const _BeanPicker({
    required this.beans,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Bean> beans;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        ChoiceChip(
          label: const Text('指定しない'),
          selected: selectedId == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final b in beans)
          ChoiceChip(
            label: Text(b.name, overflow: TextOverflow.ellipsis),
            selected: selectedId == b.id,
            onSelected: (_) => onSelected(b.id),
          ),
      ],
    );
  }
}

class _NoBeanHint extends StatelessWidget {
  const _NoBeanHint({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '豆を登録すると、豆ごとに味を振り返れます。',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRegister,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('豆を登録する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ステップの流れを縦のタイムラインで見せる。
class _SchedulePreview extends StatelessWidget {
  const _SchedulePreview({required this.schedule});

  final BrewSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final steps = schedule.steps;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Column(
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.sm,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        Fmt.mmss(steps[i].start),
                        style: theme.textTheme.labelLarge!.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: steps[i].kind == BrewStepKind.drawdown
                            ? scheme.outline
                            : scheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        steps[i].label,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      steps[i].kind == BrewStepKind.drawdown
                          ? '待つ'
                          : '〜${steps[i].targetTotalMl} ml',
                      style: theme.textTheme.labelLarge,
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

class _StartBar extends StatelessWidget {
  const _StartBar({required this.summary, required this.onStart});

  final String summary;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.md,
            AppSpace.screen,
            AppSpace.md,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('start-brew'),
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('抽出をはじめる（$summary）'),
            ),
          ),
        ),
      ),
    );
  }
}
