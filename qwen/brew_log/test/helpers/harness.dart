import 'package:brew_log/application/app_data.dart';
import 'package:brew_log/application/clock.dart';
import 'package:brew_log/application/providers.dart';
import 'package:brew_log/data/models.dart';
import 'package:brew_log/data/state_store.dart';
import 'package:brew_log/presentation/root_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// テスト用の足場。メモリ内保存と手動時計を差し込んで RootApp を立ち上げる。
class Harness {
  Harness(this.store, this.clock);

  final InMemoryStore store;
  final ManualBrewClock clock;

  /// 手動時計を進めてから、フレームを1回進める（Timer.periodic を発火させる）。
  Future<void> elapse(Duration delta) async {
    clock.advance(delta);
    await tester.pump(BrewTick.pulse);
  }

  late final WidgetTester tester;
}

/// brew_session のティック間隔に合わせる定数。
abstract final class BrewTick {
  static const Duration pulse = Duration(milliseconds: 200);
}

Future<Harness> pumpApp(
  WidgetTester tester, {
  PersistedState? state,
  StoreFailure? failure,
  DateTime? now,
  Size? logicalSize,
}) async {
  final ManualBrewClock clock = ManualBrewClock(
    now ?? DateTime(2026, 10, 30, 9),
  );
  final InMemoryStore store = InMemoryStore(state: state);

  /// デフォルトはスマホ縦画面（400x1200）。リストの内容が遅延構築で
  /// 消えてテストが flakes しないよう、わざと縦長にしている。
  final Size surface = logicalSize ?? const Size(400, 1200);
  tester.view.physicalSize = surface * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);

  final harness = Harness(store, clock)..tester = tester;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(clock),
        appBootstrapProvider.overrideWithValue(
          AppBootstrap(
            state: failure == null
                ? (state ?? PersistedState.empty)
                : PersistedState.empty,
            failure: failure,
          ),
        ),
      ],
      child: const RootApp(),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

/// microtask に流し込まれた保存処理を確実に完了させる。
Future<void> settle() async {
  for (int i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Widget 以外（Notifier 直接）のテスト用コンテナ。
ProviderContainer createContainer({
  PersistedState? state,
  InMemoryStore? store,
  ManualBrewClock? clock,
}) {
  final InMemoryStore resolvedStore = store ?? InMemoryStore(state: state);
  return ProviderContainer(
    overrides: [
      storeProvider.overrideWithValue(resolvedStore),
      clockProvider.overrideWithValue(clock ?? ManualBrewClock()),
      appBootstrapProvider.overrideWithValue(
        AppBootstrap(state: resolvedStore.snapshot),
      ),
    ],
  );
}

// ---------------------------------------------------------------- サンプルデータ

final Bean beanA = Bean(
  id: 'bean-a',
  name: 'エチオピア ゲイシャ',
  origin: 'イルガチェフェ',
  roast: RoastLevel.light,
  roastDate: DateTime(2026, 10, 22),
  note: '花のような香り',
);

final Bean beanB = Bean(
  id: 'bean-b',
  name: 'グアテマラ アンティグア',
  origin: 'アンティグア',
  roast: RoastLevel.medium,
  roastDate: DateTime(2026, 10, 2),
);

final Recipe recipeA = Recipe(
  id: 'recipe-a',
  name: 'いつもの一杯',
  beanAmountG: 15,
  waterMl: 240,
  tempC: 90,
  bloomSeconds: 40,
  pours: 3,
  beanId: 'bean-a',
);

final Recipe recipeB = Recipe(
  id: 'recipe-b',
  name: 'ゆっくり3投',
  beanAmountG: 18,
  waterMl: 300,
  tempC: 88,
  bloomSeconds: 45,
  pours: 2,
  beanId: 'bean-b',
);

Extraction extractionA({
  String id = 'ex-a',
  required DateTime at,
  int rating = 4,
  String? beanId = 'bean-a',
  String beanName = 'エチオピア ゲイシャ',
  String note = '',
}) {
  return Extraction(
    id: id,
    brewedAt: at,
    beanId: beanId,
    beanName: beanName,
    recipeName: 'いつもの一杯',
    rating: rating,
    beanAmountG: 15,
    waterMl: 240,
    tempC: 90,
    taste: const TasteProfile(acidity: 0.7, bitterness: 0.3, sweetness: 0.6),
    note: note,
    pours: const <PourLog>[
      PourLog(label: '蒸らし', targetCumMl: 30, elapsedMs: 0),
      PourLog(label: '1投目', targetCumMl: 100, elapsedMs: 55000),
    ],
  );
}

PersistedState sampleState({DateTime? now}) {
  final DateTime base = now ?? DateTime(2026, 10, 30, 9);
  return PersistedState(
    beans: <Bean>[beanA, beanB],
    recipes: <Recipe>[recipeA, recipeB],
    extractions: <Extraction>[
      extractionA(id: 'ex-1', at: base, rating: 5, note: '香りが立っている'),
      extractionA(
        id: 'ex-2',
        at: base.subtract(const Duration(days: 1)),
        rating: 4,
      ),
      extractionA(
        id: 'ex-3',
        at: base.subtract(const Duration(days: 3)),
        rating: 3,
        beanId: 'bean-b',
        beanName: 'グアテマラ アンティグア',
      ),
      extractionA(
        id: 'ex-4',
        at: base.subtract(const Duration(days: 9)),
        rating: 5,
        beanId: 'bean-b',
        beanName: 'グアテマラ アンティグア',
      ),
      extractionA(
        id: 'ex-5',
        at: base.subtract(const Duration(days: 31)),
        rating: 2,
      ),
    ],
  );
}
