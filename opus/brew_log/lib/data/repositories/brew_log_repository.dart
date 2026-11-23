import 'dart:convert';

import '../models/app_settings.dart';
import '../models/bean.dart';
import '../models/brew_record.dart';
import '../storage/key_value_store.dart';

/// 読み込み時に見つかった問題。UI でバナーとして表示する。
class StorageIssue {
  const StorageIssue(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 読み込み結果。データと、読み込み中に見つかった問題をまとめて返す。
class LoadResult<T> {
  const LoadResult(this.data, [this.issues = const []]);
  final T data;
  final List<StorageIssue> issues;
}

/// 端末ローカルのデータを JSON で読み書きするリポジトリ。
///
/// 方針:
/// - 例外は外に出さない。壊れていたら空（または既定値）で続行し、[StorageIssue] で知らせる。
/// - 丸ごと読めない場合は元の文字列を `*.corrupt` キーに退避してから空にする。
/// - 一部の項目だけ壊れている場合は、その項目だけ読み飛ばす。
class BrewLogRepository {
  BrewLogRepository(this._store);

  final KeyValueStore _store;

  static const beansKey = 'brew_log.beans.v1';
  static const recordsKey = 'brew_log.records.v1';
  static const settingsKey = 'brew_log.settings.v1';

  static const Set<String> allKeys = {
    beansKey,
    recordsKey,
    settingsKey,
    '$beansKey.corrupt',
    '$recordsKey.corrupt',
    '$settingsKey.corrupt',
  };

  LoadResult<List<Bean>> loadBeans() => _loadList(beansKey, '豆', Bean.fromJson);

  LoadResult<List<BrewRecord>> loadRecords() {
    final result = _loadList(recordsKey, '抽出記録', BrewRecord.fromJson);
    final sorted = [...result.data]
      ..sort((a, b) => b.brewedAt.compareTo(a.brewedAt));
    return LoadResult(sorted, result.issues);
  }

  LoadResult<AppSettings> loadSettings() {
    try {
      final raw = _store.getString(settingsKey);
      if (raw == null) return const LoadResult(AppSettings());
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('設定の形式が不正です');
      }
      return LoadResult(AppSettings.fromJson(decoded));
    } on Object {
      _backup(settingsKey);
      return const LoadResult(AppSettings(), [
        StorageIssue('設定を読み込めなかったため、初期設定に戻しました。'),
      ]);
    }
  }

  Future<void> saveBeans(List<Bean> beans) => _store.setString(
    beansKey,
    jsonEncode([for (final b in beans) b.toJson()]),
  );

  Future<void> saveRecords(List<BrewRecord> records) => _store.setString(
    recordsKey,
    jsonEncode([for (final r in records) r.toJson()]),
  );

  Future<void> saveSettings(AppSettings settings) =>
      _store.setString(settingsKey, jsonEncode(settings.toJson()));

  /// 豆と記録を削除する。テーマなどの設定は残す。
  Future<void> clearAll() async {
    for (final key in allKeys) {
      if (key == settingsKey) continue;
      await _store.remove(key);
    }
  }

  LoadResult<List<T>> _loadList<T>(
    String key,
    String label,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final Object? decoded;
    try {
      final raw = _store.getString(key);
      if (raw == null) return LoadResult(<T>[]);
      decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('配列ではありません');
    } on Object {
      _backup(key);
      return LoadResult(<T>[], [
        StorageIssue('$labelのデータが壊れていたため読み込めませんでした。元データは退避してあります。'),
      ]);
    }

    final items = <T>[];
    var skipped = 0;
    for (final item in decoded) {
      try {
        if (item is! Map<String, dynamic>) throw const FormatException('');
        items.add(fromJson(item));
      } on Object {
        skipped++;
      }
    }
    // 次の保存で壊れた項目が消えるため、元データを退避しておく
    if (skipped > 0) _backup(key);
    return LoadResult(items, [
      if (skipped > 0)
        StorageIssue('$labelのデータのうち $skipped 件が壊れていたため表示していません。'),
    ]);
  }

  void _backup(String key) {
    try {
      final raw = _store.getString(key);
      if (raw != null) {
        // 退避は投げっぱなしで良い（失敗しても起動を止めない）
        _store.setString('$key.corrupt', raw).ignore();
      }
    } on Object {
      // 型違いなどで文字列として取り出せない場合は退避を諦める
    }
  }
}
