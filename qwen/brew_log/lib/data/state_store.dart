import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// 保存の境界。壊れたデータや読めないデータも含めて「結果」として返す。
abstract interface class BrewLogStore {
  Future<LoadOutcome> load();

  /// 保存に失敗したときは [StoreWriteException] を送出する。呼び出し側で通知する。
  Future<void> save(PersistedState state);

  Future<void> clear();
}

/// 読み込み結果。`failure` が非 null でも [state] は常に有効な空データを持っている。
final class LoadOutcome {
  const LoadOutcome(this.state, [this.failure]);

  final PersistedState state;
  final StoreFailure? failure;
}

enum StoreFailureKind {
  /// JSON として壊れている、または想定外の形になっている。
  corrupt,

  /// 保存領域そのものにアクセスできない。
  storageUnavailable,

  /// このアプリより新しいスキーマで書かれていた。
  newerVersion,
}

/// 保存データにまつわる問題の利用者向け説明。
final class StoreFailure {
  const StoreFailure({
    required this.kind,
    required this.message,
    this.detail,
    this.backupKey,
  });

  final StoreFailureKind kind;

  /// 画面に出す日本語の一文。
  final String message;

  /// 設定画面などで見せる補足（例外の型名など）。
  final String? detail;

  /// 壊れたデータを退避できたときのキー名。
  final String? backupKey;

  /// 新しいスキーマが原因で、自動保存を止めるべきかどうか。
  bool get suspendsPersistence => kind == StoreFailureKind.newerVersion;

  String get headline => switch (kind) {
    StoreFailureKind.corrupt => '保存データを読み込めませんでした',
    StoreFailureKind.storageUnavailable => '端末の保存領域にアクセスできません',
    StoreFailureKind.newerVersion => 'より新しいバージョンのデータです',
  };
}

/// 保存に失敗したことを表す例外。
class StoreWriteException implements Exception {
  const StoreWriteException(this.message);

  final String message;

  @override
  String toString() => 'StoreWriteException: $message';
}

/// [SharedPreferences] を使った実装。通信は一切行わない。
final class SharedPreferencesStore implements BrewLogStore {
  const SharedPreferencesStore();

  @visibleForTesting
  static const String stateKey = 'brew_log.state.v1';

  @visibleForTesting
  static const String corruptKeyPrefix = 'brew_log.corrupt.';

  /// 退避コピーは新しいものだけ3件保持する。
  static const int _maxBackups = 3;

  @override
  Future<LoadOutcome> load() async {
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } on Exception catch (error) {
      return LoadOutcome(
        PersistedState.empty,
        StoreFailure(
          kind: StoreFailureKind.storageUnavailable,
          message:
              'この端末では記録を保存できません。動作確認用として、'
              'データは空の状態から始まります。',
          detail: error.toString(),
        ),
      );
    }

    final String? raw = prefs.getString(stateKey);
    if (raw == null || raw.trim().isEmpty) {
      return const LoadOutcome(PersistedState.empty);
    }

    try {
      final Object? decoded = jsonDecode(raw);
      return LoadOutcome(
        PersistedState.fromJson(JsonMap.require(decoded, '保存データ')),
      );
    } on NewerSchemaException catch (error) {
      // 未来のデータなので、退避も消去もしない。読み取り専用の警告だけ出す。
      return LoadOutcome(
        PersistedState.empty,
        StoreFailure(
          kind: StoreFailureKind.newerVersion,
          message:
              'このデータは新しいバージョン（スキーマ v${error.foundVersion}）'
              'で保存されています。アプリを更新するまで、上書きしないよう自動保存を停止します。',
        ),
      );
    } on Exception catch (error) {
      final String? backupKey = await _stashCorrupt(prefs, raw);
      return LoadOutcome(
        PersistedState.empty,
        StoreFailure(
          kind: StoreFailureKind.corrupt,
          message: backupKey == null
              ? '保存データが壊れていたため、空の状態から始めます。'
                    '壊れたデータの退避には失敗しました。'
              : '保存データが壊れていたため、空の状態から始めます。'
                    '元のデータは端末内に退避しました。',
          detail: error.toString(),
          backupKey: backupKey,
        ),
      );
    }
  }

  @override
  Future<void> save(PersistedState state) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool written = await prefs.setString(
        stateKey,
        jsonEncode(state.toJson()),
      );
      if (!written) {
        throw const StoreWriteException(
          'SharedPreferences が書き込みを false で返しました',
        );
      }
    } on StoreWriteException {
      rethrow;
    } on Exception catch (error) {
      throw StoreWriteException('保存に失敗しました: $error');
    }
  }

  @override
  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(stateKey);
  }

  /// 壊れた生データを読み取り専用のキーへ退避する。失敗しても null を返すだけ。
  Future<String?> _stashCorrupt(SharedPreferences prefs, String raw) async {
    final String key =
        '$corruptKeyPrefix${DateTime.now().millisecondsSinceEpoch}';
    try {
      await prefs.setString(key, raw);
      final List<String> others =
          prefs
              .getKeys()
              .where((String k) => k.startsWith(corruptKeyPrefix) && k != key)
              .toList()
            ..sort();
      // キー名はミリ秒タイムスタンプなので、辞書順 = 古い順。
      for (final String stale in others.skip(_maxBackups - 1)) {
        await prefs.remove(stale);
      }
      return key;
    } on Exception {
      return null;
    }
  }
}

/// テストとスクリーンショット生成用の、メモリ内保存。
final class InMemoryStore implements BrewLogStore {
  InMemoryStore({PersistedState? state, this.failureOnLoad})
    : _state = state ?? PersistedState.empty;

  PersistedState _state;

  /// 読み込み時に必ず失敗させる（破損時の挙動を検証するため）。
  final StoreFailure? failureOnLoad;

  /// 次の save だけ意図的に失敗させる。
  bool failNextSave = false;

  PersistedState get snapshot => _state;

  int saveCount = 0;

  @override
  Future<LoadOutcome> load() async {
    final StoreFailure? failure = failureOnLoad;
    if (failure != null) return LoadOutcome(PersistedState.empty, failure);
    return LoadOutcome(_state);
  }

  @override
  Future<void> save(PersistedState state) async {
    if (failNextSave) {
      failNextSave = false;
      throw const StoreWriteException('テストによる意図的な保存失敗');
    }
    saveCount++;
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = PersistedState.empty;
    saveCount++;
  }
}
