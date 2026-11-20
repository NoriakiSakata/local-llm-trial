import 'dart:convert';

import 'package:brew_log/data/models.dart';
import 'package:brew_log/data/storage.dart';
import 'package:brew_log/state/app_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingWrites extends MemoryStore {
  @override
  Future<void> write(String key, String value) async => throw Exception('full');
}

BrewRecord rec(String id, DateTime at, {String beanId = 'b1', String beanName = 'エチオピア'}) => BrewRecord(
  id: id,
  brewedAt: at,
  beanId: beanId,
  beanName: beanName,
  recipe: const Recipe(),
  elapsedSeconds: 150,
  rating: 4,
);

void main() {
  late MemoryStore kv;
  late AppStore store;

  setUp(() {
    kv = MemoryStore();
    store = AppStore(repository: AppRepository(kv), initial: const AppData(), clock: () => DateTime(2026, 11, 18));
  });

  Map<String, Object?> saved() => jsonDecode(kv.values[AppRepository.dataKey]!) as Map<String, Object?>;

  test('変更はすぐ保存される', () async {
    await store.upsertBean(const Bean(id: 'b1', name: 'エチオピア'));
    expect((saved()['beans'] as List).single['name'], 'エチオピア');
  });

  test('豆の名前を変えると、記録に控えた名前も変わる', () async {
    await store.upsertBean(const Bean(id: 'b1', name: 'エチオピア'));
    await store.addRecord(rec('r1', DateTime(2026, 11, 17)));
    await store.upsertBean(const Bean(id: 'b1', name: 'エチオピア グジ'));
    expect(store.records.single.beanName, 'エチオピア グジ');
  });

  test('記録は新しい順に並ぶ', () async {
    await store.addRecord(rec('old', DateTime(2026, 11, 1)));
    await store.addRecord(rec('new', DateTime(2026, 11, 10)));
    await store.addRecord(rec('mid', DateTime(2026, 11, 5)));
    expect(store.records.map((r) => r.id), ['new', 'mid', 'old']);
  });

  test('削除した記録を元の位置に戻せる', () async {
    await store.addRecord(rec('a', DateTime(2026, 11, 3)));
    await store.addRecord(rec('b', DateTime(2026, 11, 2)));
    await store.addRecord(rec('c', DateTime(2026, 11, 1)));
    final removed = store.deleteRecord('b')!;
    expect(store.records.map((r) => r.id), ['a', 'c']);
    await store.restoreRecord(removed.$1, removed.$2);
    expect(store.records.map((r) => r.id), ['a', 'b', 'c']);
  });

  test('豆を削除しても記録は残る', () async {
    await store.upsertBean(const Bean(id: 'b1', name: 'エチオピア'));
    await store.addRecord(rec('r1', DateTime(2026, 11, 17)));
    store.deleteBean('b1');
    expect(store.beans, isEmpty);
    expect(store.records.single.beanName, 'エチオピア');
  });

  test('全削除はテーマ設定だけ残す', () async {
    await store.setTheme(AppThemePreference.dark);
    await store.upsertBean(const Bean(id: 'b1', name: 'x'));
    await store.addRecord(rec('r1', DateTime(2026, 11, 17)));
    await store.setLastRecipe(const Recipe(beanGrams: 20));
    await store.deleteAll();
    expect(store.beans, isEmpty);
    expect(store.records, isEmpty);
    expect(store.data.lastRecipe, const Recipe());
    expect(store.data.theme, AppThemePreference.dark);
  });

  test('保存に失敗したらエラーを持ち、画面は変更後の状態のまま', () async {
    final failing = AppStore(repository: AppRepository(_FailingWrites()), initial: const AppData());
    await failing.upsertBean(const Bean(id: 'b1', name: 'x'));
    expect(failing.beans, hasLength(1));
    expect(failing.saveError, isNotNull);
  });

  test('ID は呼ぶたびに異なる', () {
    expect(store.newId(), isNot(store.newId()));
  });
}
