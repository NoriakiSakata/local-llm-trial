import 'package:shared_preferences/shared_preferences.dart';

/// 永続化の最小インターフェース。
/// リポジトリはこれだけに依存するため、テストでは [MemoryKeyValueStore] に差し替えられる。
abstract interface class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

/// shared_preferences（キャッシュ付き API）による実装。
class SharedPrefsKeyValueStore implements KeyValueStore {
  SharedPrefsKeyValueStore._(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<SharedPrefsKeyValueStore> open(Set<String> keys) async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: SharedPreferencesWithCacheOptions(allowList: keys),
    );
    return SharedPrefsKeyValueStore._(prefs);
  }

  @override
  String? getString(String key) {
    // 型の違う値が入っていた場合も「壊れたデータ」として呼び出し側に伝える
    final Object? raw = _prefs.get(key);
    if (raw == null || raw is String) return raw as String?;
    throw FormatException('"$key" に文字列以外の値が保存されています');
  }

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// メモリ上だけで動く実装。テストと、ストレージを開けなかったときの退避先に使う。
class MemoryKeyValueStore implements KeyValueStore {
  MemoryKeyValueStore([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
