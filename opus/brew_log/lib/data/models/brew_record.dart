import 'package:flutter/foundation.dart';

import 'json_read.dart';
import 'recipe.dart';

/// 味の評価軸。スライダーは 1〜5 の 5 段階。
enum TasteAxis {
  acidity('酸味'),
  bitterness('苦味'),
  sweetness('甘み');

  const TasteAxis(this.label);
  final String label;

  static const int min = 1;
  static const int max = 5;
}

@immutable
class BrewRecord {
  const BrewRecord({
    required this.id,
    required this.beanId,
    required this.beanName,
    required this.recipe,
    required this.brewedAt,
    required this.elapsedSec,
    required this.rating,
    required this.acidity,
    required this.bitterness,
    required this.sweetness,
    required this.note,
  });

  final String id;

  /// 豆を削除しても記録は残すため、名前はスナップショットで持つ。
  final String? beanId;
  final String beanName;
  final Recipe recipe;
  final DateTime brewedAt;

  /// 実際にかかった抽出時間（秒）
  final int elapsedSec;

  /// 評価 ★1〜5
  final int rating;
  final int acidity;
  final int bitterness;
  final int sweetness;
  final String note;

  int taste(TasteAxis axis) => switch (axis) {
    TasteAxis.acidity => acidity,
    TasteAxis.bitterness => bitterness,
    TasteAxis.sweetness => sweetness,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'beanId': beanId,
    'beanName': beanName,
    'recipe': recipe.toJson(),
    'brewedAt': brewedAt.toIso8601String(),
    'elapsedSec': elapsedSec,
    'rating': rating,
    'acidity': acidity,
    'bitterness': bitterness,
    'sweetness': sweetness,
    'note': note,
  };

  factory BrewRecord.fromJson(Map<String, dynamic> json) {
    final record = BrewRecord(
      id: json.req<String>('id'),
      beanId: json.opt<String>('beanId'),
      beanName: json.req<String>('beanName'),
      recipe: Recipe.fromJson(json.req<Map<String, dynamic>>('recipe')),
      brewedAt: json.reqDate('brewedAt'),
      elapsedSec: json.reqInt('elapsedSec'),
      rating: json.reqInt('rating'),
      acidity: json.reqInt('acidity'),
      bitterness: json.reqInt('bitterness'),
      sweetness: json.reqInt('sweetness'),
      note: json.opt<String>('note') ?? '',
    );
    if (record.rating < 1 || record.rating > 5) {
      throw const FormatException('評価が範囲外です');
    }
    return record;
  }
}
