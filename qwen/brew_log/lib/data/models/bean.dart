import 'dart:math' as math;

import '../json_io.dart';

/// 焙煎度。
enum RoastLevel {
  light('浅煎り'),
  medium('中煎り'),
  dark('深煎り');

  const RoastLevel(this.label);

  /// 画面に表示する名称。
  final String label;

  String get key => name;

  static RoastLevel fromKey(Object? value) {
    if (value is String) {
      for (final RoastLevel level in values) {
        if (level.name == value) return level;
      }
    }
    throw DataShapeException('焙煎度の値が不明です: $value');
  }
}

/// 豆の登録情報。
final class Bean {
  const Bean({
    required this.id,
    required this.name,
    required this.origin,
    required this.roast,
    required this.roastDate,
    this.note = '',
    this.referenceRecipeId,
  });

  final String id;

  /// 豆の名前（例：「エチオピア ゲイシャ 水洗い」）。
  final String name;

  /// 産地（自由記述）。
  final String origin;

  final RoastLevel roast;

  /// 焙煎日。時刻は持たない。
  final DateTime roastDate;

  final String note;

  /// よく使うレシピへのショートカット（削除されていれば無視される）。
  final String? referenceRecipeId;

  Bean copyWith({
    String? name,
    String? origin,
    RoastLevel? roast,
    DateTime? roastDate,
    String? note,
    String? referenceRecipeId,
  }) {
    return Bean(
      id: id,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      roast: roast ?? this.roast,
      roastDate: roastDate == null ? this.roastDate : dateOnly(roastDate),
      note: note ?? this.note,
      referenceRecipeId: referenceRecipeId ?? this.referenceRecipeId,
    );
  }

  /// 焙煎からの経過日数。未来日指定でも 0 以下にはしない。
  int daysSinceRoast(DateTime now) {
    final int days = dateOnly(now).difference(dateOnly(roastDate)).inDays;
    return math.max(0, days);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'origin': origin,
    'roast': roast.key,
    'roastDate': encodeDate(roastDate),
    if (note.isNotEmpty) 'note': note,
    if (referenceRecipeId != null) 'referenceRecipeId': referenceRecipeId,
  };

  static Bean fromJson(JsonMap json) {
    return Bean(
      id: json.string('id', '豆'),
      name: json.string('name', '豆', fallback: '名称未設定の豆'),
      origin: json.string('origin', '豆'),
      roast: RoastLevel.fromKey(json.string('roast', '豆', fallback: 'medium')),
      roastDate: json.date(
        'roastDate',
        '豆',
        fallback: dateOnly(DateTime.now()),
      ),
      note: json.string('note', '豆'),
      referenceRecipeId: json.nullableString('referenceRecipeId', '豆'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Bean &&
      other.id == id &&
      other.name == name &&
      other.origin == origin &&
      other.roast == roast &&
      other.roastDate == roastDate &&
      other.note == note &&
      other.referenceRecipeId == referenceRecipeId;

  @override
  int get hashCode =>
      Object.hash(id, name, origin, roast, roastDate, note, referenceRecipeId);
}
