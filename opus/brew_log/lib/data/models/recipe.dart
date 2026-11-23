import 'package:flutter/foundation.dart';

import 'json_read.dart';

/// 抽出レシピ。値の範囲は UI のステッパーと同じ制約を持つ。
@immutable
class Recipe {
  const Recipe({
    required this.doseG,
    required this.waterMl,
    required this.tempC,
    required this.bloomSec,
    required this.pours,
    required this.pourIntervalSec,
  });

  /// 豆 15g・湯 240ml（1:16）・92℃・蒸らし 30 秒・3 投・投間隔 30 秒
  static const Recipe standard = Recipe(
    doseG: 15,
    waterMl: 240,
    tempC: 92,
    bloomSec: 30,
    pours: 3,
    pourIntervalSec: 30,
  );

  static const doseRange = (min: 5, max: 40);
  static const waterRange = (min: 60, max: 600);
  static const tempRange = (min: 70, max: 100);
  static const bloomRange = (min: 0, max: 90);
  static const poursRange = (min: 1, max: 8);
  static const intervalRange = (min: 10, max: 90);

  final int doseG;
  final int waterMl;
  final int tempC;
  final int bloomSec;
  final int pours;
  final int pourIntervalSec;

  /// 湯量 ÷ 豆の量（例: 16 なら 1:16）
  double get ratio => waterMl / doseG;

  Recipe copyWith({
    int? doseG,
    int? waterMl,
    int? tempC,
    int? bloomSec,
    int? pours,
    int? pourIntervalSec,
  }) {
    return Recipe(
      doseG: doseG ?? this.doseG,
      waterMl: waterMl ?? this.waterMl,
      tempC: tempC ?? this.tempC,
      bloomSec: bloomSec ?? this.bloomSec,
      pours: pours ?? this.pours,
      pourIntervalSec: pourIntervalSec ?? this.pourIntervalSec,
    );
  }

  Map<String, dynamic> toJson() => {
    'doseG': doseG,
    'waterMl': waterMl,
    'tempC': tempC,
    'bloomSec': bloomSec,
    'pours': pours,
    'pourIntervalSec': pourIntervalSec,
  };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final recipe = Recipe(
      doseG: json.reqInt('doseG'),
      waterMl: json.reqInt('waterMl'),
      tempC: json.reqInt('tempC'),
      bloomSec: json.reqInt('bloomSec'),
      pours: json.reqInt('pours'),
      pourIntervalSec: json.reqInt('pourIntervalSec'),
    );
    if (recipe.doseG <= 0 || recipe.waterMl <= 0 || recipe.pours <= 0) {
      throw const FormatException('レシピの値が範囲外です');
    }
    return recipe;
  }

  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.doseG == doseG &&
      other.waterMl == waterMl &&
      other.tempC == tempC &&
      other.bloomSec == bloomSec &&
      other.pours == pours &&
      other.pourIntervalSec == pourIntervalSec;

  @override
  int get hashCode =>
      Object.hash(doseG, waterMl, tempC, bloomSec, pours, pourIntervalSec);
}
