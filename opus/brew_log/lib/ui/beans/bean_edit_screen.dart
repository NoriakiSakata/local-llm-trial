import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../state/app_store.dart';
import '../format.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// 豆の登録・編集。[bean] が null なら新規
class BeanEditScreen extends StatefulWidget {
  const BeanEditScreen({super.key, this.bean});
  final Bean? bean;

  @override
  State<BeanEditScreen> createState() => _BeanEditScreenState();
}

class _BeanEditScreenState extends State<BeanEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.bean?.name);
  late final _origin = TextEditingController(text: widget.bean?.origin);
  late final _memo = TextEditingController(text: widget.bean?.memo);
  late RoastLevel _roast = widget.bean?.roast ?? RoastLevel.medium;
  late DateTime? _roastedOn = widget.bean?.roastedOn;

  bool get _isNew => widget.bean == null;

  @override
  void dispose() {
    _name.dispose();
    _origin.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = AppScope.read(context).clock();
    final picked = await showDatePicker(
      context: context,
      initialDate: _roastedOn ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: '焙煎日',
    );
    if (picked != null) setState(() => _roastedOn = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final store = AppScope.read(context);
    final bean = Bean(
      id: widget.bean?.id ?? store.newId(),
      name: _name.text.trim(),
      origin: _origin.text.trim(),
      roast: _roast,
      roastedOn: _roastedOn,
      memo: _memo.text.trim(),
    );
    store.upsertBean(bean);
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final bean = widget.bean!;
    final ok = await confirm(
      context,
      title: '豆を削除しますか？',
      message: '「${bean.name}」を削除します。これまでの抽出記録は残ります。',
      okLabel: '削除',
      destructive: true,
    );
    if (!ok || !mounted) return;
    AppScope.read(context).deleteBean(bean.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _roastedOn == null
        ? null
        : Bean(id: '', name: '', roastedOn: _roastedOn).daysSinceRoast(AppScope.read(context).clock());
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '豆を登録' : '豆を編集'),
        actions: [if (!_isNew) IconButton(tooltip: '削除', icon: const Icon(Icons.delete_outline), onPressed: _delete)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            TextFormField(
              controller: _name,
              autofocus: _isNew,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: '名前', hintText: '例：エチオピア イルガチェフェ'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '名前を入力してください' : null,
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _origin,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: '産地', hintText: '例：エチオピア'),
            ),
            const SectionLabel('焙煎度'),
            SegmentedButton<RoastLevel>(
              segments: [for (final r in RoastLevel.values) ButtonSegment(value: r, label: Text(r.label))],
              selected: {_roast},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _roast = s.first),
            ),
            const SectionLabel('焙煎日'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(_roastedOn == null ? '未設定' : formatFullDate(_roastedOn!)),
                subtitle: days == null ? null : Text('焙煎から $days 日'),
                onTap: _pickDate,
                trailing: _roastedOn == null
                    ? null
                    : IconButton(
                        tooltip: '焙煎日をクリア',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _roastedOn = null),
                      ),
              ),
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _memo,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'メモ', alignLabelWithHint: true),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(onPressed: _save, child: Text(_isNew ? '登録する' : '保存する')),
            SizedBox(height: Space.md + MediaQuery.paddingOf(context).bottom),
            if (!_isNew) Text('記録に表示される豆の名前も更新されます。', style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
