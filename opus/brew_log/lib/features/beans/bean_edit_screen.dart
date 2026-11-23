import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../../data/models/bean.dart';
import '../../state/app_providers.dart';
import '../../ui/format.dart';
import '../../ui/id.dart';
import '../../ui/widgets/common.dart';

/// 豆の登録・編集フォーム。[initial] が null なら新規登録。
class BeanEditScreen extends ConsumerStatefulWidget {
  const BeanEditScreen({super.key, this.initial});

  final Bean? initial;

  @override
  ConsumerState<BeanEditScreen> createState() => _BeanEditScreenState();
}

class _BeanEditScreenState extends ConsumerState<BeanEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _origin;
  late final TextEditingController _memo;
  late RoastLevel _roast;
  late DateTime _roastedOn;

  bool get _isNew => widget.initial == null;

  @override
  void initState() {
    super.initState();
    final b = widget.initial;
    _name = TextEditingController(text: b?.name ?? '');
    _origin = TextEditingController(text: b?.origin ?? '');
    _memo = TextEditingController(text: b?.memo ?? '');
    _roast = b?.roast ?? RoastLevel.medium;
    final now = DateTime.now();
    _roastedOn = b?.roastedOn ?? DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _name.dispose();
    _origin.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _roastedOn,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: '焙煎日を選択',
    );
    if (picked != null) setState(() => _roastedOn = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(beansProvider.notifier);
    final initial = widget.initial;
    if (initial == null) {
      await notifier.add(
        Bean(
          id: newId(),
          name: _name.text.trim(),
          origin: _origin.text.trim(),
          roast: _roast,
          roastedOn: _roastedOn,
          memo: _memo.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
    } else {
      await notifier.replace(
        initial.copyWith(
          name: _name.text.trim(),
          origin: _origin.text.trim(),
          roast: _roast,
          roastedOn: _roastedOn,
          memo: _memo.text.trim(),
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showMessageSnackBar(context, _isNew ? '豆を登録しました' : '変更を保存しました');
  }

  Future<void> _delete() async {
    final bean = widget.initial!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('この豆を削除しますか？'),
        content: Text('「${bean.name}」を削除します。これまでの抽出記録は残ります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(beansProvider.notifier).remove(bean.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    showMessageSnackBar(context, '「${bean.name}」を削除しました');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = Bean.daysBetween(_roastedOn, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '豆を登録' : '豆を編集'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: '削除',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.sm,
              AppSpace.screen,
              AppSpace.xxl,
            ),
            children: [
              TextFormField(
                key: const ValueKey('bean-name'),
                controller: _name,
                autofocus: _isNew,
                textInputAction: TextInputAction.next,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: '名前',
                  hintText: '例: エチオピア イルガチェフェ',
                  counterText: '',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '名前を入力してください' : null,
              ),
              const SizedBox(height: AppSpace.lg),
              TextFormField(
                key: const ValueKey('bean-origin'),
                controller: _origin,
                textInputAction: TextInputAction.next,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: '産地',
                  hintText: '例: エチオピア',
                  counterText: '',
                ),
              ),
              const SectionLabel('焙煎度'),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<RoastLevel>(
                  segments: [
                    for (final r in RoastLevel.values)
                      ButtonSegment(value: r, label: Text(r.label)),
                  ],
                  selected: {_roast},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _roast = s.first),
                ),
              ),
              const SectionLabel('焙煎日'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text(Fmt.date(_roastedOn)),
                  subtitle: Text(days == 0 ? '今日焙煎' : '焙煎から $days 日'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickDate,
                ),
              ),
              const SectionLabel('メモ'),
              TextFormField(
                key: const ValueKey('bean-memo'),
                controller: _memo,
                minLines: 3,
                maxLines: 6,
                maxLength: 400,
                decoration: const InputDecoration(hintText: '購入店、精製方法、印象など'),
              ),
              const SizedBox(height: AppSpace.xl),
              FilledButton(
                key: const ValueKey('bean-save'),
                onPressed: _save,
                child: Text(_isNew ? '登録する' : '保存する'),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'データはこの端末の中だけに保存されます。',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
