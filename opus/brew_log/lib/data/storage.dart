import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// 生の文字列を読み書きする場所。テストではメモリ版に差し替える。
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._prefs);
  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, String>? initial]) : values = {...?initial};
  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// 読み込みの結果。壊れていた場合は [recoveredFromError] に理由が入る。
class LoadResult {
  const LoadResult(this.data, {this.recoveredFromError});
  final AppData data;
  final String? recoveredFromError;
}

/// アプリの状態を JSON 1本で保存する。
class AppRepository {
  AppRepository(this._store);

  static const dataKey = 'brew_log.data';
  static const backupKey = 'brew_log.corrupted_backup';

  final KeyValueStore _store;

  /// 保存データを読む。壊れていても例外は投げず、元の文字列を退避して空の状態を返す。
  Future<LoadResult> load() async {
    final String? raw;
    try {
      raw = await _store.read(dataKey);
    } catch (e) {
      return LoadResult(const AppData(), recoveredFromError: '保存領域を読み込めませんでした');
    }
    if (raw == null) return const LoadResult(AppData());
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('形式が正しくありません');
      return LoadResult(AppData.fromJson(decoded.cast<String, Object?>()));
    } catch (e) {
      await _store.write(backupKey, raw);
      await _store.remove(dataKey);
      return LoadResult(const AppData(), recoveredFromError: '保存データが壊れていたため、空の状態で起動しました。元のデータは端末内に退避してあります。');
    }
  }

  Future<void> save(AppData data) => _store.write(dataKey, jsonEncode(data.toJson()));
}
