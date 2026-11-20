import '../json_io.dart';

/// 抽出レシピ。タイマーの設計図にもなる値オブジェクト。
final class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.beanAmountG,
    required this.waterMl,
    required this.tempC,
    required this.bloomSeconds,
    required this.pours,
    this.beanId,
    this.updatedAt,
  });

  final String id;
  final String name;

  /// 豆の量（グラム）。蒸らし湯量の算出根拠にする。
  final double beanAmountG;

  /// 総湯量（ミリリットル）。
  final int waterMl;

  /// 湯温（℃）。
  final int tempC;

  /// 蒸らし時間（秒）。
  final int bloomSeconds;

  /// 蒸らし以降の注湯回数。
  final int pours;

  /// 前提としている豆（削除されていれば null 扱いで表示される）。
  final String? beanId;

  final DateTime? updatedAt;

  Recipe copyWith({
    String? name,
    double? beanAmountG,
    int? waterMl,
    int? tempC,
    int? bloomSeconds,
    int? pours,
    String? beanId,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id,
      name: name ?? this.name,
      beanAmountG: beanAmountG ?? this.beanAmountG,
      waterMl: waterMl ?? this.waterMl,
      tempC: tempC ?? this.tempC,
      bloomSeconds: bloomSeconds ?? this.bloomSeconds,
      pours: pours ?? this.pours,
      beanId: beanId ?? this.beanId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'beanAmountG': beanAmountG,
    'waterMl': waterMl,
    'tempC': tempC,
    'bloomSeconds': bloomSeconds,
    'pours': pours,
    if (beanId != null) 'beanId': beanId,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  static Recipe fromJson(JsonMap json) {
    return Recipe(
      id: json.string('id', 'レシピ'),
      name: json.string('name', 'レシピ', fallback: '名称未設定のレシピ'),
      beanAmountG: json.dbl('beanAmountG', 'レシピ', fallback: 15),
      waterMl: json.integer('waterMl', 'レシピ', fallback: 240),
      tempC: json.integer('tempC', 'レシピ', fallback: 90),
      bloomSeconds: json.integer('bloomSeconds', 'レシピ', fallback: 40),
      pours: json.integer('pours', 'レシピ', fallback: 3),
      beanId: json.nullableString('beanId', 'レシピ'),
      updatedAt: json.nullableTimestamp('updatedAt', 'レシピ'),
    );
  }
}
