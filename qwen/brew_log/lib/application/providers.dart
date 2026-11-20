import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/state_store.dart';
import 'app_data.dart';
import 'brew_session.dart';
import 'clock.dart';
import 'stats.dart';

/// 端末保存（通信はしない）。
final storeProvider = Provider<BrewLogStore>(
  (ref) => const SharedPreferencesStore(),
);

/// 時刻源。テストでは ManualBrewClock に差し替える。
final clockProvider = Provider<BrewClock>((ref) => const SystemBrewClock());

/// main() で読み込んだ初期データ。必ず override して使う。
final appBootstrapProvider = Provider<AppBootstrap>(
  (ref) => throw UnimplementedError('main() またはテストで override する'),
);

/// アプリ全体のデータ状態。
final appDataProvider = NotifierProvider<AppDataNotifier, AppState>(
  AppDataNotifier.new,
);

/// 実行中の抽出セッション（なければ null）。
final brewSessionProvider = NotifierProvider<BrewSessionNotifier, BrewSession?>(
  BrewSessionNotifier.new,
);

/// 淹れる画面が使うレシピ。
final selectedRecipeProvider = Provider<Recipe?>(
  (ref) => ref.watch(appDataProvider).selectedRecipe,
);

/// 選択中レシピに対応する豆（いなければ null）。
final selectedRecipeBeanProvider = Provider<Bean?>((ref) {
  final Recipe? recipe = ref.watch(selectedRecipeProvider);
  if (recipe == null) return null;
  return ref.watch(appDataProvider).beanById(recipe.beanId);
});

/// 直近 windowDays 日などの集計。データが変わったときだけ再計算される。
final statsProvider = Provider<BrewStats>((ref) {
  final AppState data = ref.watch(appDataProvider);
  return BrewStats.of(
    extractions: data.extractions,
    beans: data.beans,
    now: ref.watch(clockProvider).now(),
  );
});

/// 履歴画面の豆別フィルタ（null は「すべて」）。
final beanFilterProvider = NotifierProvider<BeanFilterNotifier, String?>(
  BeanFilterNotifier.new,
);

/// フィルタ適用済みの履歴（新しい順）。
final filteredExtractionsProvider = Provider<List<Extraction>>((ref) {
  final AppState data = ref.watch(appDataProvider);
  final String? filter = ref.watch(beanFilterProvider);
  return data.sortedExtractions(beanId: filter);
});
