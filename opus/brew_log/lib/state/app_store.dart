import 'package:flutter/widgets.dart';

import '../data/models.dart';
import '../data/storage.dart';

typedef Clock = DateTime Function();

/// アプリ全体のデータを持ち、変更のたびに保存する。
class AppStore extends ChangeNotifier {
  AppStore({required this._repository, required AppData initial, this.startupNotice, Clock? clock})
    : _data = initial,
      clock = clock ?? DateTime.now;

  final AppRepository _repository;
  final Clock clock;
  AppData _data;
  int _idSeq = 0;

  /// 起動時に読み込みで問題があった場合のメッセージ。一度表示したら消す。
  String? startupNotice;

  /// 直近の保存に失敗していればそのメッセージ
  String? saveError;

  AppData get data => _data;
  List<Bean> get beans => _data.beans;

  /// 新しい順
  List<BrewRecord> get records => _data.records;

  Bean? beanById(String? id) {
    for (final b in _data.beans) {
      if (b.id == id) return b;
    }
    return null;
  }

  String newId() => '${clock().microsecondsSinceEpoch.toRadixString(36)}-${(_idSeq++).toRadixString(36)}';

  Future<void> _update(AppData next) async {
    _data = next;
    notifyListeners();
    try {
      await _repository.save(next);
      if (saveError != null) {
        saveError = null;
        notifyListeners();
      }
    } catch (e) {
      saveError = '保存に失敗しました。端末の空き容量を確認してください。';
      notifyListeners();
    }
  }

  Future<void> upsertBean(Bean bean) {
    final exists = _data.beans.any((b) => b.id == bean.id);
    final beans = exists ? [for (final b in _data.beans) b.id == bean.id ? bean : b] : [bean, ..._data.beans];
    // 記録に控えた豆の名前も合わせて更新する
    final records = [
      for (final r in _data.records)
        r.beanId == bean.id && r.beanName != bean.name
            ? BrewRecord.fromJson({...r.toJson(), 'beanName': bean.name})
            : r,
    ];
    return _update(_data.copyWith(beans: beans, records: records));
  }

  /// 削除した豆と元の位置を返す（元に戻す用）
  (Bean, int)? deleteBean(String id) {
    final index = _data.beans.indexWhere((b) => b.id == id);
    if (index < 0) return null;
    final bean = _data.beans[index];
    _update(_data.copyWith(beans: [..._data.beans]..removeAt(index)));
    return (bean, index);
  }

  Future<void> restoreBean(Bean bean, int index) {
    final beans = [..._data.beans]..insert(index.clamp(0, _data.beans.length), bean);
    return _update(_data.copyWith(beans: beans));
  }

  Future<void> addRecord(BrewRecord record) {
    final records = [record, ..._data.records]..sort((a, b) => b.brewedAt.compareTo(a.brewedAt));
    return _update(_data.copyWith(records: records));
  }

  (BrewRecord, int)? deleteRecord(String id) {
    final index = _data.records.indexWhere((r) => r.id == id);
    if (index < 0) return null;
    final record = _data.records[index];
    _update(_data.copyWith(records: [..._data.records]..removeAt(index)));
    return (record, index);
  }

  Future<void> restoreRecord(BrewRecord record, int index) {
    final records = [..._data.records]..insert(index.clamp(0, _data.records.length), record);
    return _update(_data.copyWith(records: records));
  }

  Future<void> setLastRecipe(Recipe recipe) =>
      recipe == _data.lastRecipe ? Future.value() : _update(_data.copyWith(lastRecipe: recipe));

  Future<void> setTheme(AppThemePreference theme) => _update(_data.copyWith(theme: theme));

  /// 豆・記録・レシピを消す。テーマ設定は残す。
  Future<void> deleteAll() => _update(AppData(theme: _data.theme));
}

/// [AppStore] を画面に渡す
class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child}) : super(notifier: store);

  static AppStore of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// 変更を購読せずに参照する（ボタンの処理などで使う）
  static AppStore read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
