/// JSON の読み出しを厳密にするための小さなヘルパー。
///
/// 壊れたデータでクラッシュさせないため、想定外の形はここで例外にして
/// 上位（[StoreFailure]）に渡す。
library;

class DataShapeException implements Exception {
  const DataShapeException(this.message);

  final String message;

  @override
  String toString() => 'DataShapeException: $message';
}

final class JsonMap {
  JsonMap(this._map);

  final Map<String, dynamic> _map;

  static JsonMap require(Object? value, String context) {
    if (value is Map<String, dynamic>) return JsonMap(value);
    if (value is Map) {
      return JsonMap(Map<String, dynamic>.from(value));
    }
    throw DataShapeException('$context の形式が不正です');
  }

  List<JsonMap> list(String key, String context) {
    final Object? raw = _map[key];
    if (raw == null) return const [];
    if (raw is! List) {
      throw DataShapeException('$context の $key が配列ではありません');
    }
    return raw
        .map((Object? e) => JsonMap.require(e, '$context.$key'))
        .toList(growable: false);
  }

  String string(String key, String context, {String fallback = ''}) {
    final Object? raw = _map[key];
    if (raw == null) return fallback;
    if (raw is String) return raw;
    throw DataShapeException('$context.$key が文字列ではありません');
  }

  String? nullableString(String key, String context) {
    final Object? raw = _map[key];
    if (raw == null) return null;
    if (raw is String) return raw;
    throw DataShapeException('$context.$key が文字列ではありません');
  }

  int integer(String key, String context, {required int fallback}) {
    final Object? raw = _map[key];
    if (raw == null) return fallback;
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    throw DataShapeException('$context.$key が数値ではありません');
  }

  double dbl(String key, String context, {required double fallback}) {
    final Object? raw = _map[key];
    if (raw == null) return fallback;
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    throw DataShapeException('$context.$key が数値ではありません');
  }

  double ratio(String key, String context, {double fallback = 0.5}) {
    final double value = dbl(key, context, fallback: fallback);
    return value.clamp(0.0, 1.0);
  }

  /// `yyyy-MM-dd` 形式の日付（焙煎日など、時刻を持たない日）。
  DateTime date(String key, String context, {required DateTime fallback}) {
    final Object? raw = _map[key];
    if (raw == null) return fallback;
    if (raw is! String) {
      throw DataShapeException('$context.$key が日付文字列ではありません');
    }
    final List<String> parts = raw.split('-');
    if (parts.length != 3) {
      throw DataShapeException('$context.$key の日付形式が不正です: $raw');
    }
    final int? y = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    final int? d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) {
      throw DataShapeException('$context.$key の日付が解釈できません: $raw');
    }
    return DateTime(y, m, d);
  }

  /// ISO8601 のタイムスタンプ（端末のローカル時刻として解釈する）。
  DateTime timestamp(String key, String context, {required DateTime fallback}) {
    final Object? raw = _map[key];
    if (raw == null) return fallback;
    return _parseTimestamp(raw, key, context);
  }

  /// 有無が許されるタイムスタンプ。
  DateTime? nullableTimestamp(String key, String context) {
    final Object? raw = _map[key];
    if (raw == null) return null;
    return _parseTimestamp(raw, key, context);
  }

  DateTime _parseTimestamp(Object? raw, String key, String context) {
    if (raw is! String) {
      throw DataShapeException('$context.$key が時刻文字列ではありません');
    }
    try {
      return DateTime.parse(raw).toLocal();
    } on FormatException {
      throw DataShapeException('$context.$key の時刻が解釈できません: $raw');
    }
  }

  /// キーの生の値（存在しなければ null）。
  Object? rawOrNull(String key) => _map[key];

  Map<String, dynamic> raw(String key, String context) {
    return Map<String, dynamic>.from(
      JsonMap.require(_map[key], '$context.$key')._map,
    );
  }
}

/// `yyyy-MM-dd` に正規化する。
String encodeDate(DateTime value) {
  final String y = value.year.toString().padLeft(4, '0');
  final String m = value.month.toString().padLeft(2, '0');
  final String d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// 日付-only の DateTime に丸める。
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
