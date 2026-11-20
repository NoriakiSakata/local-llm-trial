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
import 'brew_screen.dart';

/// レシピの作成・編集画面。
///
/// 数値はスライダーで inputs し、変更に合わせてステップ構成をその場でプレビューする。
class RecipeEditorScreen extends ConsumerStatefulWidget {
  const RecipeEditorScreen({required this.recipe, super.key});

  final Recipe? recipe;

  @override
  ConsumerState<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends ConsumerState<RecipeEditorScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.recipe?.name ?? 'いつものレシピ',
  );
  late String? _beanId = widget.recipe?.beanId;
  late double _beanAmount = (widget.recipe?.beanAmountG ?? 15).toDouble();
  late double _water = (widget.recipe?.waterMl ?? 240).toDouble();
  late double _temp = (widget.recipe?.tempC ?? 90).toDouble();
  late double _bloom = (widget.recipe?.bloomSeconds ?? 40).toDouble();
  late int _pours = widget.recipe?.pours ?? 3;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _isNew => widget.recipe == null;

  Recipe get _draft => Recipe(
    id: widget.recipe?.id ?? '',
    name: _name.text.trim().isEmpty ? '名称未設定のレシピ' : _name.text.trim(),
    beanAmountG: _beanAmount,
    waterMl: _water.round(),
    tempC: _temp.round(),
    bloomSeconds: _bloom.round(),
    pours: _pours,
    beanId: _beanId,
    updatedAt: widget.recipe?.updatedAt,
  );

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(appDataProvider.notifier).saveRecipe(_draft);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final Recipe? recipe = widget.recipe;
    if (recipe == null) return;
    final bool ok = await confirmAction(
      context,
      title: 'レシピを削除しますか？',
      message: '「${recipe.name}」を削除します。\nこのレシピで作った抽出記録は残ります。',
      confirmLabel: '削除する',
    );
    if (!ok) return;
    ref.read(appDataProvider.notifier).removeRecipe(recipe.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Bean> beans = ref.watch(appDataProvider).beans;
    final BrewPlan plan = BrewPlan.from(_draft);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '新しいレシピ' : 'レシピを編集'),
        actions: <Widget>[
          if (!_isNew)
            IconButton(
              onPressed: _delete,
              tooltip: '削除',
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          TextButton(onPressed: _save, child: const Text('保存')),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.lg,
              AppSpacing.screen,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'レシピ名',
                  hintText: '例：朝の一杯',
                ),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                    ? 'レシピ名を入力してください'
                    : null,
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('豆', style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (beans.isEmpty)
                _HintCard(
                  icon: Icons.eco_outlined,
                  text: '豆がまだ登録されていません。豆を指定しなくてもレシピは作れます。',
                )
              else
                DropdownButtonFormField<String?>(
                  initialValue: beans.any((Bean b) => b.id == _beanId)
                      ? _beanId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '使う豆（任意）',
                    prefixIcon: Icon(Icons.eco_outlined),
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('指定しない'),
                    ),
                    for (final Bean bean in beans)
                      DropdownMenuItem<String?>(
                        value: bean.id,
                        child: Text(bean.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (String? value) => setState(() => _beanId = value),
                ),
              const SizedBox(height: AppSpacing.xl),

              _SliderField(
                label: '豆量',
                value: _beanAmount,
                min: 10,
                max: 30,
                divisions: 40,
                display: '${_grams(_beanAmount)} g',
                onChanged: (double v) => setState(() => _beanAmount = v),
              ),
              _SliderField(
                label: '湯量',
                value: _water,
                min: 120,
                max: 600,
                divisions: 48,
                display: '${_water.round()} ml',
                onChanged: (double v) => setState(() => _water = v),
              ),
              _SliderField(
                label: '湯温',
                value: _temp,
                min: 70,
                max: 96,
                divisions: 26,
                display: '${_temp.round()} ℃',
                onChanged: (double v) => setState(() => _temp = v),
              ),
              _SliderField(
                label: '蒸らし時間',
                value: _bloom,
                min: 15,
                max: 90,
                divisions: 15,
                display: formatDurationJa(Duration(seconds: _bloom.round())),
                onChanged: (double v) => setState(() => _bloom = v),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('注湯回数（蒸らしのあと）', style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: <Widget>[
                  for (int i = 1; i <= 6; i++)
                    ChoiceChip(
                      label: Text('$i回'),
                      selected: _pours == i,
                      onSelected: (_) => setState(() => _pours = i),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              SectionCard(
                title: 'ステップのプレビュー',
                trailing: Text(
                  '合計 ${formatDurationJa(plan.totalDuration)}',
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    StepStrip(plan: plan),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '蒸らし ${plan.steps.first.pourMl} ml → '
                      '${plan.steps.length - 1}回に分けて注ぎ、'
                      '最終的に ${plan.waterMl} ml。1投あたり ${plan.steps[1].durationMs ~/ 1000}秒の注湯です。',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _grams(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(label, style: text.titleSmall)),
              Text(
                display,
                style: AppTypography.numeric(
                  text.titleMedium!.copyWith(color: scheme.primary),
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: display,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: AppSize.iconMedium, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
