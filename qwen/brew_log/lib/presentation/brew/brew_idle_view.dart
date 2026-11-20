import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/app_data.dart';
import '../../application/brew_plan.dart';
import '../../application/providers.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../widgets/common.dart';
import '../widgets/empty_state.dart';
import 'brew_screen.dart';
import 'recipe_editor_screen.dart';

/// レシピを選んでタイマーを開始する待機画面。
class BrewIdleView extends ConsumerWidget {
  const BrewIdleView({required this.onGoToTab, super.key});

  final void Function(int index) onGoToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppState data = ref.watch(appDataProvider);
    final List<Recipe> recipes = data.recipes;

    if (recipes.isEmpty) {
      final bool hasBeans = data.beans.isNotEmpty;
      return EmptyState(
        title: hasBeans ? 'レシピがまだ作られていません' : 'まずは豆を登録しましょう',
        description: hasBeans
            ? '豆と湯量、蒸らし時間を決めておくと、タイマーが\n自動でステップを組み立てます。'
            : '淹れた豆を記録するには、まず豆の登録が必要です。\nレシピは登録後にも作れます。',
        action: FilledButton.icon(
          onPressed: () => hasBeans ? _openEditor(context, null) : onGoToTab(2),
          icon: Icon(hasBeans ? Icons.add_rounded : Icons.eco_outlined),
          label: Text(hasBeans ? 'レシピを作る' : '豆を登録する'),
        ),
        secondaryAction: hasBeans
            ? TextButton(
                onPressed: () => onGoToTab(2),
                child: const Text('豆の一覧へ'),
              )
            : TextButton(
                onPressed: () => _openEditor(context, null),
                child: const Text('豆なしでレシピを作る'),
              ),
      );
    }

    final TextTheme text = Theme.of(context).textTheme;
    final Recipe? selected = ref.watch(selectedRecipeProvider);
    final Bean? bean = ref.watch(selectedRecipeBeanProvider);
    final BrewPlan? plan = selected == null ? null : BrewPlan.from(selected);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        AppSpacing.xxxl,
      ),
      children: <Widget>[
        _RecipePicker(recipes: recipes, selectedId: selected?.id),
        if (selected != null && plan != null) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(selected.name, style: text.titleLarge),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            bean == null
                                ? '豆は指定されていません'
                                : '${bean.name} · ${bean.roast.label}',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openEditor(context, selected),
                      tooltip: 'レシピを編集',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    InfoPill(
                      label: '豆量',
                      value: '${_grams(selected.beanAmountG)} g',
                    ),
                    InfoPill(label: '湯量', value: '${selected.waterMl} ml'),
                    InfoPill(label: '湯温', value: '${selected.tempC} ℃'),
                    InfoPill(
                      label: '蒸らし',
                      value: formatDurationJa(
                        Duration(seconds: selected.bloomSeconds),
                      ),
                    ),
                    InfoPill(label: '注湯', value: '${selected.pours}回'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(
                  title: 'ステップ',
                  trailing: '合計 ${formatDurationJa(plan.totalDuration)}',
                ),
                StepStrip(plan: plan),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '蒸らし ${plan.steps.first.pourMl} ml から、'
                  '${plan.steps.length - 1}回の注湯で ${plan.waterMl} ml まで。',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        FilledButton.icon(
          onPressed: selected == null
              ? null
              : () => ref.read(brewSessionProvider.notifier).start(selected),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('タイマーをスタート'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => _openEditor(context, null),
          child: const Text('新しいレシピを作る'),
        ),
      ],
    );
  }

  /// 15.0 → "15"、15.5 → "15.5" のように末尾ゼロを落として見せる。
  static String _grams(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  void _openEditor(BuildContext context, Recipe? recipe) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeEditorScreen(recipe: recipe),
      ),
    );
  }
}

class _RecipePicker extends ConsumerWidget {
  const _RecipePicker({required this.recipes, required this.selectedId});

  final List<Recipe> recipes;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (recipes.length < 2) return const SizedBox.shrink();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final Recipe recipe = recipes[index];
          final bool selected = recipe.id == selectedId;
          return AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.secondaryContainer
                  : scheme.surfaceContainerLow,
              borderRadius: AppRadius.chipRadius,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    ref.read(appDataProvider.notifier).selectRecipe(recipe.id),
                child: Center(
                  child: Text(
                    recipe.name,
                    style: text.labelLarge?.copyWith(
                      color: selected
                          ? scheme.onSecondaryContainer
                          : scheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
