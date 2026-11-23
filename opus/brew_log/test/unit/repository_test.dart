import 'dart:convert';

import 'package:brew_log/data/models/app_settings.dart';
import 'package:brew_log/data/models/bean.dart';
import 'package:brew_log/data/repositories/brew_log_repository.dart';
import 'package:brew_log/data/storage/key_value_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  test('保存したデータを読み戻せる', () async {
    final store = MemoryKeyValueStore();
    final repo = BrewLogRepository(store);
    final bean = testBean();
    final record = testRecord(id: 'r1', at: DateTime(2026, 11, 20, 8));
    await repo.saveBeans([bean]);
    await repo.saveRecords([record]);
    await repo.saveSettings(const AppSettings(theme: ThemePreference.dark));

    final beans = repo.loadBeans();
    expect(beans.issues, isEmpty);
    expect(beans.data.single, bean);
    expect(repo.loadRecords().data.single.id, 'r1');
    expect(repo.loadSettings().data.theme, ThemePreference.dark);
  });

  test('何も保存されていなければ空で、問題もない', () {
    final repo = BrewLogRepository(MemoryKeyValueStore());
    expect(repo.loadBeans().data, isEmpty);
    expect(repo.loadBeans().issues, isEmpty);
    expect(repo.loadSettings().data, const AppSettings());
  });

  test('JSON として壊れていたら空にし、元データを退避して問題を報告する', () {
    final store = MemoryKeyValueStore({
      BrewLogRepository.beansKey: '{not json',
    });
    final result = BrewLogRepository(store).loadBeans();

    expect(result.data, isEmpty);
    expect(result.issues.single.message, contains('豆のデータが壊れていた'));
    expect(store.values['${BrewLogRepository.beansKey}.corrupt'], '{not json');
  });

  test('一部の項目だけ壊れていたら、その項目だけ読み飛ばす', () {
    final good = testBean(id: 'ok').toJson();
    final store = MemoryKeyValueStore({
      BrewLogRepository.beansKey: jsonEncode([
        good,
        {'id': 'bad', 'name': 1},
        'string',
        {...good, 'id': 'bad-roast', 'roast': 'unknown'},
      ]),
    });
    final result = BrewLogRepository(store).loadBeans();

    expect(result.data.map((b) => b.id), ['ok']);
    expect(result.issues.single.message, contains('3 件'));
    expect(store.values, contains('${BrewLogRepository.beansKey}.corrupt'));
  });

  test('記録は新しい順に並べて返す', () async {
    final repo = BrewLogRepository(MemoryKeyValueStore());
    await repo.saveRecords([
      testRecord(id: 'old', at: DateTime(2026, 11, 1)),
      testRecord(id: 'new', at: DateTime(2026, 11, 20)),
    ]);
    expect(repo.loadRecords().data.map((r) => r.id), ['new', 'old']);
  });

  test('設定が壊れていたら初期設定に戻す', () {
    final store = MemoryKeyValueStore({
      BrewLogRepository.settingsKey: '[1,2,3]',
    });
    final result = BrewLogRepository(store).loadSettings();
    expect(result.data, const AppSettings());
    expect(result.issues, hasLength(1));
  });

  test('clearAll は豆と記録を消し、テーマ設定は残す', () async {
    final store = MemoryKeyValueStore();
    final repo = BrewLogRepository(store);
    await repo.saveBeans([testBean()]);
    await repo.saveRecords([testRecord(id: 'r', at: DateTime(2026))]);
    await repo.saveSettings(const AppSettings(theme: ThemePreference.light));

    await repo.clearAll();

    expect(repo.loadBeans().data, isEmpty);
    expect(repo.loadRecords().data, isEmpty);
    expect(repo.loadSettings().data.theme, ThemePreference.light);
  });

  test('焙煎からの経過日数は暦日で数える', () {
    final bean = testBean(roastedOn: DateTime(2026, 11, 20));
    expect(bean.daysSinceRoast(DateTime(2026, 11, 20, 23, 59)), 0);
    expect(bean.daysSinceRoast(DateTime(2026, 11, 21, 0, 1)), 1);
    expect(bean.daysSinceRoast(DateTime(2026, 12, 1, 9)), 11);
    expect(Bean.daysBetween(DateTime(2026, 3, 1), DateTime(2026, 2, 28)), -1);
  });
}
