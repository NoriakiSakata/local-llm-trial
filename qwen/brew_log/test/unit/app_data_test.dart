import 'package:brew_log/application/app_data.dart';
import 'package:brew_log/application/clock.dart';
import 'package:brew_log/application/providers.dart';
import 'package:brew_log/data/models.dart';
import 'package:brew_log/data/state_store.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  late ProviderContainer container;
  late InMemoryStore store;

  setUp(() {
    store = InMemoryStore(state: sampleState());
    container = createContainer(store: store);
    addTearDown(container.dispose);
  });

  AppDataNotifier notifier() => container.read(appDataProvider.notifier);

  test('bootstrap のデータがそのまま状態になる', () {
    final state = container.read(appDataProvider);
    expect(state.beans.length, 2);
    expect(state.failure, isNull);
  });

  test('saveBean は id を採番して追加し、同じ id なら更新', () async {
    final draft = Bean(
      id: '',
      name: '新しい豆',
      origin: 'ブラジル',
      roast: RoastLevel.dark,
      roastDate: DateTime(2026, 10, 20),
    );
    final saved = notifier().saveBean(draft);
    expect(saved.id, isNotEmpty);
    expect(container.read(appDataProvider).beans.length, 3);

    notifier().saveBean(saved.copyWith(name: '名前の直した豆'));
    final after = container.read(appDataProvider);
    expect(after.beans.length, 3);
    expect(after.beans.last.name, '名前の直した豆');
    await settle();
    expect(store.snapshot.beans.last.name, '名前の直した豆');
  });

  test('removeBean → restoreBean で元の位置に戻る', () async {
    final removed = notifier().removeBean('bean-b');
    expect(removed?.index, 1);
    expect(container.read(appDataProvider).beans.length, 1);

    notifier().restoreBean(removed!);
    final restored = container.read(appDataProvider).beans;
    expect(restored.map((Bean b) => b.id).toList(), <String>[
      'bean-a',
      'bean-b',
    ]);
    await settle();
    expect(store.snapshot.beans.length, 2);
  });

  test('豆を消しても記録側の豆名スナップショットは残る', () {
    notifier().removeBean('bean-a');
    final state = container.read(appDataProvider);
    expect(state.extractions.first.beanName, 'エチオピア ゲイシャ');
    expect(
      notifier().labelForBean(null, state.extractions.first.beanName),
      'エチオピア ゲイシャ',
    );
    expect(notifier().labelForBean('bean-a', ''), '（削除済みの豆）');
  });

  test('addExtraction は先頭に追加され、sortedExtractions は新しい順', () {
    notifier().addExtraction(
      extractionA(id: 'ex-new', at: DateTime(2026, 10, 30, 12), rating: 5),
    );
    final state = container.read(appDataProvider);
    expect(state.extractions.first.id, 'ex-new');
    expect(
      state.sortedExtractions().first.brewedAt.isAfter(
        state.sortedExtractions().last.brewedAt,
      ),
      isTrue,
    );
    expect(state.sortedExtractions(beanId: 'bean-b').length, 2);
  });

  test('レシピ削除で lastRecipeId は生き残りの先頭に張り替わる', () {
    notifier().selectRecipe('recipe-a');
    expect(notifier().removeRecipe('recipe-a'), isTrue);
    final state = container.read(appDataProvider);
    expect(state.settings.lastRecipeId, 'recipe-b');
    expect(state.selectedRecipe?.id, 'recipe-b');
  });

  test('selectedRecipe は未設定なら1件目', () {
    final state = container.read(appDataProvider);
    expect(state.settings.lastRecipeId, isNull);
    expect(state.selectedRecipe?.id, 'recipe-a');
  });

  test('setThemeMode は永続化される', () async {
    notifier().setThemeMode(ThemeMode.dark);
    await settle();
    expect(store.snapshot.settings.themeMode, ThemeMode.dark);
  });

  test('clearAll はメモリと保存領域の両方を空にする', () async {
    await notifier().clearAll();
    expect(container.read(appDataProvider).hasData, isFalse);
    expect(store.snapshot.extractions, isEmpty);
  });

  test('保存に失敗しても状態は進み、saveError だけ立つ', () async {
    store.failNextSave = true;
    notifier().saveBean(
      Bean(
        id: '',
        name: '保存失敗のテスト',
        origin: '',
        roast: RoastLevel.light,
        roastDate: DateTime(2026, 10, 1),
      ),
    );
    expect(container.read(appDataProvider).beans.length, 3);
    await settle();
    final state = container.read(appDataProvider);
    expect(state.saveError, contains('保存'));
    // 次の変更からは正常に保存される
    notifier().setThemeMode(ThemeMode.light);
    await settle();
    expect(container.read(appDataProvider).saveError, contains('保存'));
    expect(store.snapshot.settings.themeMode, ThemeMode.light);
  });

  test('新しいスキーマのデータでは自動保存を止める', () async {
    final mem = InMemoryStore();
    final suspended = ProviderContainer(
      overrides: [
        storeProvider.overrideWithValue(mem),
        clockProvider.overrideWithValue(ManualBrewClock()),
        appBootstrapProvider.overrideWithValue(
          const AppBootstrap(
            state: PersistedState.empty,
            failure: StoreFailure(
              kind: StoreFailureKind.newerVersion,
              message: '新しいバージョンのデータです',
            ),
          ),
        ),
      ],
    );
    addTearDown(suspended.dispose);

    suspended
        .read(appDataProvider.notifier)
        .saveBean(
          Bean(
            id: '',
            name: '消えたくない豆',
            origin: '',
            roast: RoastLevel.medium,
            roastDate: DateTime(2026, 10, 1),
          ),
        );
    await settle();

    final state = suspended.read(appDataProvider);
    expect(state.persistenceSuspended, isTrue);
    expect(state.beans.length, 1);
    // 未来のデータの上書きはしない = 保存処理そのものが走っていない。
    expect(mem.snapshot.beans, isEmpty);
    expect(mem.saveCount, 0);
  });

  test('acknowledgeFailure でバナーが引っ込む', () {
    final c = ProviderContainer(
      overrides: [
        storeProvider.overrideWithValue(InMemoryStore()),
        clockProvider.overrideWithValue(ManualBrewClock()),
        appBootstrapProvider.overrideWithValue(
          const AppBootstrap(
            state: PersistedState.empty,
            failure: StoreFailure(
              kind: StoreFailureKind.corrupt,
              message: '壊れていました',
            ),
          ),
        ),
      ],
    );
    addTearDown(c.dispose);

    expect(c.read(appDataProvider).needsFailureBanner, isTrue);
    c.read(appDataProvider.notifier).acknowledgeFailure();
    expect(c.read(appDataProvider).needsFailureBanner, isFalse);
    expect(c.read(appDataProvider).failure, isNotNull);
  });

  test('filteredExtractionsProvider はフィルタと連動する', () {
    container.read(beanFilterProvider.notifier).select('bean-b');
    expect(container.read(filteredExtractionsProvider).length, 2);
    container.read(beanFilterProvider.notifier).select(null);
    expect(container.read(filteredExtractionsProvider).length, 5);
  });

  test('フィルタ対象の豆が消えるとフィルタは自動的に外れる', () async {
    container.read(beanFilterProvider.notifier).select('bean-a');
    expect(container.read(beanFilterProvider), 'bean-a');
    notifier().removeBean('bean-a');
    await settle();
    expect(container.read(beanFilterProvider), isNull);
  });
}
