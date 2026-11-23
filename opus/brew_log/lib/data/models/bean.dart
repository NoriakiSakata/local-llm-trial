import 'package:flutter/foundation.dart';

import 'json_read.dart';

enum RoastLevel {
  light('浅煎り'),
  medium('中煎り'),
  dark('深煎り');

  const RoastLevel(this.label);
  final String label;

  static RoastLevel parse(String value) => RoastLevel.values.firstWhere(
    (e) => e.name == value,
    orElse: () => throw FormatException('焙煎度 "$value" は不明です'),
  );
}

@immutable
class Bean {
  const Bean({
    required this.id,
    required this.name,
    required this.origin,
    required this.roast,
    required this.roastedOn,
    required this.memo,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String origin;
  final RoastLevel roast;

  /// 焙煎日（時刻は持たない）
  final DateTime roastedOn;
  final String memo;
  final DateTime createdAt;

  /// 焙煎日からの経過日数。暦日で数える（焙煎当日は 0 日）。
  int daysSinceRoast(DateTime now) => daysBetween(roastedOn, now);

  /// [from] の日付から [to] の日付までの暦日数。
  /// 夏時間の影響を避けるため、日付だけを UTC に置き直して差を取る。
  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  Bean copyWith({
    String? name,
    String? origin,
    RoastLevel? roast,
    DateTime? roastedOn,
    String? memo,
  }) {
    return Bean(
      id: id,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      roast: roast ?? this.roast,
      roastedOn: roastedOn ?? this.roastedOn,
      memo: memo ?? this.memo,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'origin': origin,
    'roast': roast.name,
    'roastedOn': roastedOn.toIso8601String(),
    'memo': memo,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Bean.fromJson(Map<String, dynamic> json) => Bean(
    id: json.req<String>('id'),
    name: json.req<String>('name'),
    origin: json.opt<String>('origin') ?? '',
    roast: RoastLevel.parse(json.req<String>('roast')),
    roastedOn: json.reqDate('roastedOn'),
    memo: json.opt<String>('memo') ?? '',
    createdAt: json.reqDate('createdAt'),
  );

  @override
  bool operator ==(Object other) =>
      other is Bean &&
      other.id == id &&
      other.name == name &&
      other.origin == origin &&
      other.roast == roast &&
      other.roastedOn == roastedOn &&
      other.memo == memo &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, name, origin, roast, roastedOn, memo, createdAt);
}
