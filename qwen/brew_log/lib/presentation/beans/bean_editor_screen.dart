import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/app_data.dart';
import '../../application/providers.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../format.dart';
import '../widgets/feedback.dart';

/// 豆の登録・編集画面。
class BeanEditorScreen extends ConsumerStatefulWidget {
  const BeanEditorScreen({required this.bean, super.key});

  final Bean? bean;

  @override
  ConsumerState<BeanEditorScreen> createState() => _BeanEditorScreenState();
}

class _BeanEditorScreenState extends ConsumerState<BeanEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.bean?.name ?? '',
  );
  late final TextEditingController _origin = TextEditingController(
    text: widget.bean?.origin ?? '',
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.bean?.note ?? '',
  );
  late RoastLevel _roast = widget.bean?.roast ?? RoastLevel.medium;
  late DateTime _roastDate = dateOnly(
    widget.bean?.roastDate ?? ref.read(clockProvider).now(),
  );

  @override
  void dispose() {
    _name.dispose();
    _origin.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _isNew => widget.bean == null;

  Future<void> _pickDate() async {
    final DateTime now = ref.read(clockProvider).now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _roastDate.isAfter(now) ? now : _roastDate,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      helpText: '焙煎した日',
    );
    if (picked == null) return;
    setState(() => _roastDate = dateOnly(picked));
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Bean draft = Bean(
      id: widget.bean?.id ?? '',
      name: _name.text.trim(),
      origin: _origin.text.trim(),
      roast: _roast,
      roastDate: _roastDate,
      note: _note.text.trim(),
      referenceRecipeId: widget.bean?.referenceRecipeId,
    );
    ref.read(appDataProvider.notifier).saveBean(draft);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final Bean? bean = widget.bean;
    if (bean == null) return;
    final bool ok = await confirmAction(
      context,
      title: '豆を削除しますか？',
      message: '「${bean.name}」を一覧から削除します。\nこの豆で淹れた記録は残ります。',
    );
    if (!ok) return;
    final RemovedBean? removed = ref
        .read(appDataProvider.notifier)
        .removeBean(bean.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (removed == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        undoSnackBar(
          message: '${bean.name} を削除しました',
          actionLabel: '戻す',
          onUndo: () => ref.read(appDataProvider.notifier).restoreBean(removed),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final DateTime now = ref.watch(clockProvider).now();
    final int days = dateOnly(now).difference(_roastDate).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '豆を登録' : '豆を編集'),
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
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: '豆の名前',
                  hintText: '例：エチオピア ゲイシャ G1',
                ),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                    ? '名前を入力してください'
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _origin,
                decoration: const InputDecoration(
                  labelText: '産地（任意）',
                  hintText: '例：エチオピア イルガチェフェ',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('焙煎度', style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<RoastLevel>(
                segments: <ButtonSegment<RoastLevel>>[
                  for (final RoastLevel level in RoastLevel.values)
                    ButtonSegment<RoastLevel>(
                      value: level,
                      label: Text(level.label),
                    ),
                ],
                selected: <RoastLevel>{_roast},
                showSelectedIcon: false,
                onSelectionChanged: (Set<RoastLevel> value) =>
                    setState(() => _roast = value.first),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('焙煎日', style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(formatDateJa(_roastDate)),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '焙煎から $days 日目',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('メモ', style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _note,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '香り・産地の補足・買った店など',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
