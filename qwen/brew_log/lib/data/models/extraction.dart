import '../json_io.dart';

/// 1回分の抽出記録。
///
/// 豆を削除しても履歴が壊れないよう、豆名はスナップショットとして持つ。
final class Extraction {
  const Extraction({
    required this.id,
    required this.brewedAt,
    required this.beanName,
    required this.rating,
    required this.beanAmountG,
    required this.waterMl,
    required this.tempC,
    this.beanId,
    this.recipeName,
    this.taste = const TasteProfile(),
    this.note = '',
    this.pours = const <PourLog>[],
  });

  final String id;
  final DateTime brewedAt;

  /// 抽出に使った豆（存在しうることを保証しない）。
  final String? beanId;

  /// 抽出時点の豆名。
  final String beanName;

  final String? recipeName;

  /// 評価（1〜5）。
  final int rating;

  final double beanAmountG;
  final int waterMl;
  final int tempC;

  final TasteProfile taste;
  final String note;

  /// 実際に流したステップのログ（タイマーから保存したもの）。
  final List<PourLog> pours;

  /// 目標に対する抽出時間（秒）。ステップログが無い場合は 0。
  int get totalSeconds =>
      pours.isEmpty ? 0 : (pours.last.elapsedMs / 1000).round();

  Extraction copyWith({String? note, int? rating}) {
    return Extraction(
      id: id,
      brewedAt: brewedAt,
      beanName: beanName,
      beanId: beanId,
      recipeName: recipeName,
      rating: rating ?? this.rating,
      beanAmountG: beanAmountG,
      waterMl: waterMl,
      tempC: tempC,
      taste: taste,
      note: note ?? this.note,
      pours: pours,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brewedAt': brewedAt.toIso8601String(),
    if (beanId != null) 'beanId': beanId,
    'beanName': beanName,
    if (recipeName != null) 'recipeName': recipeName,
    'rating': rating,
    'beanAmountG': beanAmountG,
    'waterMl': waterMl,
    'tempC': tempC,
    'taste': taste.toJson(),
    if (note.isNotEmpty) 'note': note,
    if (pours.isNotEmpty)
      'pours': pours.map((PourLog e) => e.toJson()).toList(),
  };

  static Extraction fromJson(JsonMap json) {
    return Extraction(
      id: json.string('id', '抽出記録'),
      brewedAt: json.timestamp('brewedAt', '抽出記録', fallback: DateTime.now()),
      beanId: json.nullableString('beanId', '抽出記録'),
      beanName: json.string('beanName', '抽出記録', fallback: '（削除済みの豆）'),
      recipeName: json.nullableString('recipeName', '抽出記録'),
      rating: json.integer('rating', '抽出記録', fallback: 3).clamp(1, 5),
      beanAmountG: json.dbl('beanAmountG', '抽出記録', fallback: 15),
      waterMl: json.integer('waterMl', '抽出記録', fallback: 240),
      tempC: json.integer('tempC', '抽出記録', fallback: 90),
      taste: TasteProfile.fromJson(
        JsonMap.require(json.rawOrNull('taste') ?? const {}, '抽出記録.taste'),
      ),
      note: json.string('note', '抽出記録'),
      pours: json
          .list('pours', '抽出記録')
          .map(PourLog.fromJson)
          .toList(growable: false),
    );
  }
}

/// 1ステップ分の実測ログ。
final class PourLog {
  const PourLog({
    required this.label,
    required this.targetCumMl,
    required this.elapsedMs,
  });

  final String label;

  /// そのステップ終了時の目標累計湯量。
  final int targetCumMl;

  /// 抽出開始からの経過ミリ秒。
  final int elapsedMs;

  Map<String, dynamic> toJson() => {
    'label': label,
    'targetCumMl': targetCumMl,
    'elapsedMs': elapsedMs,
  };

  static PourLog fromJson(JsonMap json) => PourLog(
    label: json.string('label', '注湯ログ'),
    targetCumMl: json.integer('targetCumMl', '注湯ログ', fallback: 0),
    elapsedMs: json.integer('elapsedMs', '注湯ログ', fallback: 0),
  );
}

/// 味の傾向（0〜1）。スライダーの値をそのまま保持する。
final class TasteProfile {
  const TasteProfile({
    this.acidity = 0.5,
    this.bitterness = 0.5,
    this.sweetness = 0.5,
  });

  final double acidity;
  final double bitterness;
  final double sweetness;

  static const List<(String, String)> fields = <(String, String)>[
    ('acidity', '酸味'),
    ('bitterness', '苦味'),
    ('sweetness', '甘み'),
  ];

  Map<String, dynamic> toJson() => {
    'acidity': acidity,
    'bitterness': bitterness,
    'sweetness': sweetness,
  };

  static TasteProfile fromJson(JsonMap json) => TasteProfile(
    acidity: json.ratio('acidity', '味'),
    bitterness: json.ratio('bitterness', '味'),
    sweetness: json.ratio('sweetness', '味'),
  );
}
