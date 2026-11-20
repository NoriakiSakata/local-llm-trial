import 'dart:convert';

import 'package:brew_log/data/models.dart';
import 'package:brew_log/data/state_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesStore', () {
    test('保存領域が空なら失敗なしで空状態', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final outcome = await const SharedPreferencesStore().load();
      expect(outcome.failure, isNull);
      expect(outcome.state.beans, isEmpty);
    });

    test('保存 → 読み込みで往復する', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = const SharedPreferencesStore();
      final state = sampleState();
      await store.save(state);

      final outcome = await store.load();
      expect(outcome.failure, isNull);
      expect(outcome.state.beans.length, 2);
      expect(outcome.state.beans.first.name, 'エチオピア ゲイシャ');
      expect(outcome.state.extractions.length, 5);
      expect(outcome.state.settings.themeMode.name, 'system');
      final Extraction back = outcome.state.extractions.first;
      expect(
        back.brewedAt.isAtSameMomentAs(state.extractions.first.brewedAt),
        isTrue,
      );
    });

    test('JSON が壊れていたら空状態 + corrupt 失敗、元データは退避される', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesStore.stateKey: '{"beans":[{"id":"a","na',
      });

      final outcome = await const SharedPreferencesStore().load();
      expect(outcome.state.beans, isEmpty);
      expect(outcome.failure?.kind, StoreFailureKind.corrupt);
      expect(outcome.failure?.backupKey, isNotNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(outcome.failure!.backupKey!), contains('"beans"'));
    });

    test('型が想定外（beans が配列でない）でも corrupt として扱う', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesStore.stateKey: '{"schema":1,"beans":{"a":1}}',
      });
      final outcome = await const SharedPreferencesStore().load();
      expect(outcome.failure?.kind, StoreFailureKind.corrupt);
      expect(outcome.state, same(PersistedState.empty));
    });

    test('未来のスキーマならデータを消さず newerVersion 警告だけ', () async {
      final String future = jsonEncode(<String, Object?>{
        'schema': 99,
        'beans': <Object>[],
      });
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesStore.stateKey: future,
      });

      final outcome = await const SharedPreferencesStore().load();
      expect(outcome.failure?.kind, StoreFailureKind.newerVersion);
      expect(outcome.failure?.suspendsPersistence, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPreferencesStore.stateKey), future);
      expect(
        prefs.getKeys().any(
          (String k) => k.startsWith(SharedPreferencesStore.corruptKeyPrefix),
        ),
        isFalse,
      );
    });

    test('退避コピーは新しい3件だけ残す', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesStore.stateKey: '{broken',
        '${SharedPreferencesStore.corruptKeyPrefix}1': 'old-1',
        '${SharedPreferencesStore.corruptKeyPrefix}2': 'old-2',
        '${SharedPreferencesStore.corruptKeyPrefix}3': 'old-3',
        '${SharedPreferencesStore.corruptKeyPrefix}4': 'old-4',
      });
      await const SharedPreferencesStore().load();

      final prefs = await SharedPreferences.getInstance();
      final List<String> backups = prefs.getKeys().where((String k) {
        return k.startsWith(SharedPreferencesStore.corruptKeyPrefix);
      }).toList()..sort();
      expect(backups.length, 3);
      expect(backups.last, startsWith(SharedPreferencesStore.corruptKeyPrefix));
    });

    test('clear で本体キーだけが消える（退避は残る）', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesStore.stateKey: '{broken',
        '${SharedPreferencesStore.corruptKeyPrefix}9': 'old',
      });
      final store = const SharedPreferencesStore();
      final outcome = await store.load();
      await store.save(sampleState());
      await store.clear();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(SharedPreferencesStore.stateKey), isFalse);
      expect(prefs.containsKey(outcome.failure!.backupKey!), isTrue);
    });
  });

  group('InMemoryStore', () {
    test('failureOnLoad を積めば load で失敗を返す', () async {
      final store = InMemoryStore(
        state: sampleState(),
        failureOnLoad: const StoreFailure(
          kind: StoreFailureKind.storageUnavailable,
          message: '保存領域にアクセスできません',
        ),
      );
      final outcome = await store.load();
      expect(outcome.failure?.kind, StoreFailureKind.storageUnavailable);
      expect(outcome.state.beans, isEmpty);
    });

    test('failNextSave で一度だけ例外', () async {
      final store = InMemoryStore()..failNextSave = true;
      await expectLater(
        store.save(sampleState()),
        throwsA(isA<StoreWriteException>()),
      );
      await store.save(sampleState());
      expect(store.saveCount, 1);
    });
  });

  group('モデルのJSON往復', () {
    test('豆の焙煎日は時刻を落として日付で保持される', () {
      final bean = Bean(
        id: 'x',
        name: 'x',
        origin: '',
        roast: RoastLevel.dark,
        roastDate: DateTime(2026, 3, 4, 13, 45),
      );
      expect(bean.toJson()['roastDate'], '2026-03-04');
      final back = Bean.fromJson(JsonMap(bean.toJson()));
      expect(back.roastDate, DateTime(2026, 3, 4));
      expect(back.roast, RoastLevel.dark);
    });

    test('不正な焙煎度キーは DataShapeException', () {
      expect(
        () => Bean.fromJson(
          JsonMap(<String, dynamic>{'id': 'x', 'roast': 'medium-dark'}),
        ),
        throwsA(isA<DataShapeException>()),
      );
    });

    test('未知のキーが増えても読み捨てされる（前方互換）', () {
      final bean = Bean.fromJson(
        JsonMap(<String, dynamic>{
          'id': 'x',
          'name': 'y',
          'origin': 'z',
          'roast': 'light',
          'roastDate': '2026-01-02',
          '将来のフィールド': 42,
        }),
      );
      expect(bean.name, 'y');
    });
  });
}
