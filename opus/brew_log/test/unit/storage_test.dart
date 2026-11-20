import 'dart:convert';

import 'package:brew_log/data/models.dart';
import 'package:brew_log/data/storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _BrokenStore implements KeyValueStore {
  @override
  Future<String?> read(String key) => throw Exception('disk');
  @override
  Future<void> write(String key, String value) => throw Exception('disk');
  @override
  Future<void> remove(String key) async {}
}

void main() {
  final sample = AppData(
    beans: [
      Bean(id: 'b1', name: 'エチオピア', origin: 'グジ', roast: RoastLevel.light, roastedOn: DateTime(2026, 11, 1), memo: '花'),
    ],
    records: [
      BrewRecord(
        id: 'r1',
        brewedAt: DateTime(2026, 11, 18, 7, 30),
        beanId: 'b1',
        beanName: 'エチオピア',
        recipe: const Recipe(beanGrams: 16, waterMl: 250, waterTempC: 88, bloomSeconds: 40, pours: 4),
        elapsedSeconds: 200,
        rating: 4,
        acidity: 5,
        bitterness: 2,
        sweetness: 4,
        note: 'ベリー',
      ),
    ],
    lastRecipe: const Recipe(beanGrams: 20),
    theme: AppThemePreference.dark,
  );

  test('保存して読み戻すと同じ内容になる', () async {
    final store = MemoryStore();
    final repo = AppRepository(store);
    await repo.save(sample);
    final loaded = await repo.load();
    expect(loaded.recoveredFromError, isNull);
    expect(jsonEncode(loaded.data.toJson()), jsonEncode(sample.toJson()));
  });

  test('データがなければ空の状態', () async {
    final loaded = await AppRepository(MemoryStore()).load();
    expect(loaded.recoveredFromError, isNull);
    expect(loaded.data.beans, isEmpty);
    expect(loaded.data.lastRecipe, const Recipe());
  });

  for (final (name, raw) in [
    ('JSON として壊れている', '{"schema":1,"beans":['),
    ('オブジェクトでない', '[1,2,3]'),
    ('必須項目が欠けている', '{"schema":1,"beans":[{"name":"x"}]}'),
    ('型が違う', '{"schema":1,"records":[{"id":"r","brewedAt":"???"}]}'),
    ('新しすぎる形式', '{"schema":99}'),
  ]) {
    test('$name場合は落ちずに空で起動し、元データを退避する', () async {
      final store = MemoryStore({AppRepository.dataKey: raw});
      final loaded = await AppRepository(store).load();
      expect(loaded.recoveredFromError, contains('壊れていた'));
      expect(loaded.data.beans, isEmpty);
      expect(store.values[AppRepository.backupKey], raw);
      expect(store.values.containsKey(AppRepository.dataKey), isFalse);
    });
  }

  test('保存領域そのものが読めなくても落ちない', () async {
    final loaded = await AppRepository(_BrokenStore()).load();
    expect(loaded.recoveredFromError, isNotNull);
    expect(loaded.data.records, isEmpty);
  });

  test('未知の焙煎度・テーマは既定値に寄せる', () {
    final data = AppData.fromJson({
      'schema': 1,
      'beans': [
        {'id': 'b', 'name': 'x', 'roast': 'unknown'},
      ],
      'theme': 'sepia',
    });
    expect(data.beans.single.roast, RoastLevel.medium);
    expect(data.theme, AppThemePreference.system);
  });

  group('Bean.daysSinceRoast', () {
    test('日付単位で数える（時刻は無視）', () {
      final bean = Bean(id: 'b', name: 'x', roastedOn: DateTime(2026, 11, 1, 23, 59));
      expect(bean.daysSinceRoast(DateTime(2026, 11, 18, 0, 1)), 17);
    });

    test('焙煎日未設定なら null', () {
      expect(const Bean(id: 'b', name: 'x').daysSinceRoast(DateTime(2026)), isNull);
    });
  });
}
