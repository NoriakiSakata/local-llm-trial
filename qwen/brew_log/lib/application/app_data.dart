import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/state_store.dart';
import 'providers.dart';

/// 起動時に読み終わっていたデータ。
final class AppBootstrap {
  const AppBootstrap({required this.state, this.failure});

  final PersistedState state;
  final StoreFailure? failure;

  static const AppBootstrap empty = AppBootstrap(state: PersistedState.empty);
}

/// データ層の状態。破損情報と保存エラーを同じ入れ物で保持する。
final class AppState {
  const AppState({
    required this.data,
    this.failure,
    this.saveError,
    this.failureAcknowledged = false,
  });

  factory AppState.fromBootstrap(AppBootstrap bootstrap) =>
      AppState(data: bootstrap.state, failure: bootstrap.failure);

  final PersistedState data;

  /// 起動時の読み込みで生じた問題。
  final StoreFailure? failure;

  /// 自動保存に失敗した直後のエラー文（スナックバーに出す）。
  final String? saveError;

  /// 破損警告をユーザーが閉じたかどうか。
  final bool failureAcknowledged;

  List<Bean> get beans => data.beans;
  List<Recipe> get recipes => data.recipes;
  List<Extraction> get extractions => data.extractions;
  AppSettings get settings => data.settings;

  /// 新しいスキーマのデータで、書き込みを止めている状態。
  bool get persistenceSuspended => failure?.suspendsPersistence ?? false;

  /// 全画面の上部に出す警告が必要かどうか。
  bool get needsFailureBanner => failure != null && !failureAcknowledged;

  bool get hasData =>
      beans.isNotEmpty || recipes.isNotEmpty || extractions.isNotEmpty;

  /// 淹れる画面で使うレシピ。未選択なら1件目にフォールバックする。
  Recipe? get selectedRecipe {
    final List<Recipe> all = recipes;
    for (int i = 0; i < all.length; i++) {
      if (all[i].id == settings.lastRecipeId) return all[i];
    }
    return all.isEmpty ? null : all.first;
  }

  Bean? beanById(String? id) {
    if (id == null) return null;
    final List<Bean> all = beans;
    for (int i = 0; i < all.length; i++) {
      if (all[i].id == id) return all[i];
    }
    return null;
  }

  /// 履歴表示用。新しい順に並べ、beanId を渡せばその豆だけに残す。
  List<Extraction> sortedExtractions({String? beanId}) {
    final List<Extraction> items = List<Extraction>.of(extractions)
      ..sort((Extraction a, Extraction b) => b.brewedAt.compareTo(a.brewedAt));
    if (beanId == null) return items;
    return items
        .where((Extraction e) => e.beanId == beanId)
        .toList(growable: false);
  }

  AppState copyWith({
    PersistedState? data,
    StoreFailure? failure,
    String? saveError,
    bool clearSaveError = false,
    bool acknowledgeFailure = false,
  }) {
    return AppState(
      data: data ?? this.data,
      failure: failure ?? this.failure,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      failureAcknowledged: acknowledgeFailure || failureAcknowledged,
    );
  }
}

/// 削除した豆の取り消し用スナップショット。
final class RemovedBean {
  const RemovedBean({required this.bean, required this.index});

  final Bean bean;
  final int index;
}

/// データの読み書きをまとめて担う Notifier。
///
/// 変更のたびに自動で永続化する。保存に失敗しても状態はメモリ上で進み、
/// エラーは画面に通知する（クラッシュはさせない）。
final class AppDataNotifier extends Notifier<AppState> {
  @override
  AppState build() => AppState.fromBootstrap(ref.watch(appBootstrapProvider));

  BrewLogStore get _store => ref.read(storeProvider);

  // 豆 ------------------------------------------------------------------

  /// id が空の Bean を受け取って採番し、追加または更新する。
  Bean saveBean(Bean draft) {
    final Bean bean = draft.id.isEmpty
        ? Bean(
            id: newId(),
            name: draft.name,
            origin: draft.origin,
            roast: draft.roast,
            roastDate: draft.roastDate,
            note: draft.note,
            referenceRecipeId: draft.referenceRecipeId,
          )
        : draft;
    final List<Bean> next = List<Bean>.of(state.beans);
    final int index = next.indexWhere((Bean b) => b.id == bean.id);
    if (index >= 0) {
      next[index] = bean;
    } else {
      next.add(bean);
    }
    _commit(state.data.copyWith(beans: next));
    return bean;
  }

  RemovedBean? removeBean(String id) {
    final int index = state.beans.indexWhere((Bean b) => b.id == id);
    if (index < 0) return null;
    final Bean bean = state.beans[index];
    final List<Bean> next = List<Bean>.of(state.beans)..removeAt(index);
    _commit(state.data.copyWith(beans: next));
    return RemovedBean(bean: bean, index: index);
  }

  void restoreBean(RemovedBean removed) {
    final List<Bean> next = List<Bean>.of(state.beans);
    next.insert(removed.index.clamp(0, next.length), removed.bean);
    _commit(state.data.copyWith(beans: next));
  }

  Bean? beanById(String? id) => state.beanById(id);

  /// 記録表示用。豆が消されていても、記録に残った名前を優先して返す。
  String labelForBean(String? beanId, String snapshotName) {
    if (snapshotName.isNotEmpty) return snapshotName;
    final Bean? bean = beanById(beanId);
    return bean?.name ?? '（削除済みの豆）';
  }

  // レシピ --------------------------------------------------------------

  Recipe saveRecipe(Recipe draft) {
    final DateTime now = ref.read(clockProvider).now();
    final Recipe recipe = draft.id.isEmpty
        ? Recipe(
            id: newId(),
            name: draft.name,
            beanAmountG: draft.beanAmountG,
            waterMl: draft.waterMl,
            tempC: draft.tempC,
            bloomSeconds: draft.bloomSeconds,
            pours: draft.pours,
            beanId: draft.beanId,
            updatedAt: now,
          )
        : draft.copyWith(updatedAt: now);
    final List<Recipe> next = List<Recipe>.of(state.recipes);
    final int index = next.indexWhere((Recipe r) => r.id == recipe.id);
    if (index >= 0) {
      next[index] = recipe;
    } else {
      next.add(recipe);
    }
    _commit(state.data.copyWith(recipes: next));
    return recipe;
  }

  bool removeRecipe(String id) {
    final List<Recipe> kept = List<Recipe>.of(state.recipes)
      ..removeWhere((Recipe r) => r.id == id);
    if (kept.length == state.recipes.length) return false;
    final AppSettings settings = state.settings.lastRecipeId == id
        ? state.settings.copyWith(
            lastRecipeId: kept.isEmpty ? null : kept.first.id,
          )
        : state.settings;
    _commit(state.data.copyWith(recipes: kept, settings: settings));
    return true;
  }

  Recipe? recipeById(String? id) {
    if (id == null) return null;
    final List<Recipe> recipes = state.recipes;
    for (int i = 0; i < recipes.length; i++) {
      if (recipes[i].id == id) return recipes[i];
    }
    return null;
  }

  /// 淹れる画面で選ぶレシピ。未選択なら1件目にフォールバックする。
  Recipe? get selectedRecipe => state.selectedRecipe;

  void selectRecipe(String id) {
    _commit(
      state.data.copyWith(settings: state.settings.copyWith(lastRecipeId: id)),
    );
  }

  // 抽出記録 ------------------------------------------------------------

  void addExtraction(Extraction extraction) {
    _commit(
      state.data.copyWith(
        extractions: <Extraction>[extraction, ...state.extractions],
      ),
    );
  }

  Extraction? removeExtraction(String id) {
    final int index = state.extractions.indexWhere(
      (Extraction e) => e.id == id,
    );
    if (index < 0) return null;
    final Extraction removed = state.extractions[index];
    final List<Extraction> next = List<Extraction>.of(state.extractions)
      ..removeAt(index);
    _commit(state.data.copyWith(extractions: next));
    return removed;
  }

  void restoreExtraction(Extraction extraction, int index) {
    final List<Extraction> next = List<Extraction>.of(state.extractions);
    next.insert(index.clamp(0, next.length), extraction);
    _commit(state.data.copyWith(extractions: next));
  }

  Extraction? extractionById(String id) {
    final List<Extraction> items = state.extractions;
    for (int i = 0; i < items.length; i++) {
      if (items[i].id == id) return items[i];
    }
    return null;
  }

  /// 履歴一覧（新しい順）。登録順に頼らず必ずソートする。
  List<Extraction> sortedExtractions({String? beanId}) {
    final List<Extraction> items = List<Extraction>.of(state.extractions)
      ..sort((Extraction a, Extraction b) => b.brewedAt.compareTo(a.brewedAt));
    if (beanId == null) return items;
    return items
        .where((Extraction e) => e.beanId == beanId)
        .toList(growable: false);
  }

  // 設定・破壊的操作 ----------------------------------------------------

  void setThemeMode(ThemeMode mode) {
    _commit(
      state.data.copyWith(settings: state.settings.copyWith(themeMode: mode)),
    );
  }

  void acknowledgeFailure() {
    state = state.copyWith(acknowledgeFailure: true);
  }

  /// すべてのデータを消す。保存領域からも削除する。
  Future<void> clearAll() async {
    state = const AppState(data: PersistedState.empty);
    try {
      await _store.clear();
    } on Exception catch (error) {
      state = state.copyWith(saveError: _describe(error));
    }
  }

  // 保存 ----------------------------------------------------------------

  void _commit(PersistedState next) {
    state = state.copyWith(data: next);
    if (state.persistenceSuspended) return;
    unawaited(_persist(next));
  }

  Future<void> _persist(PersistedState snapshot) async {
    try {
      await _store.save(snapshot);
    } on Exception catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(saveError: _describe(error));
    }
  }

  void clearSaveError() {
    state = state.copyWith(clearSaveError: true);
  }

  String _describe(Object error) {
    if (error is StoreWriteException) return error.message;
    return '自動保存に失敗しました（$error）';
  }
}

/// 履歴画面の豆別フィルタ（選択中の豆ID、null は「すべて」）。
final class BeanFilterNotifier extends Notifier<String?> {
  @override
  String? build() {
    // 豆が消されたらフィルタも外す。
    ref.listen(appDataProvider, (AppState? previous, AppState next) {
      final String? selected = state;
      if (selected != null && next.beanById(selected) == null) {
        state = null;
      }
    });
    return null;
  }

  void select(String? id) => state = id;
}
