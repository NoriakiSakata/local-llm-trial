/// アプリで扱うデータの型。すべて不変で、JSON との相互変換を持つ。
library;

enum RoastLevel {
  light('浅煎り'),
  medium('中煎り'),
  dark('深煎り');

  const RoastLevel(this.label);
  final String label;

  static RoastLevel fromName(Object? name) =>
      RoastLevel.values.firstWhere((r) => r.name == name, orElse: () => RoastLevel.medium);
}

class Bean {
  const Bean({
    required this.id,
    required this.name,
    this.origin = '',
    this.roast = RoastLevel.medium,
    this.roastedOn,
    this.memo = '',
  });

  final String id;
  final String name;
  final String origin;
  final RoastLevel roast;

  /// 焙煎日（時刻は持たない）。不明なら null。
  final DateTime? roastedOn;
  final String memo;

  /// [today] 時点での焙煎からの経過日数。焙煎日が未設定なら null。
  int? daysSinceRoast(DateTime today) {
    final roasted = roastedOn;
    if (roasted == null) return null;
    final a = DateTime(roasted.year, roasted.month, roasted.day);
    final b = DateTime(today.year, today.month, today.day);
    // 夏時間をまたいでもずれないよう UTC で日数を数える
    return DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  }

  Bean copyWith({
    String? name,
    String? origin,
    RoastLevel? roast,
    DateTime? roastedOn,
    bool clearRoastedOn = false,
    String? memo,
  }) => Bean(
    id: id,
    name: name ?? this.name,
    origin: origin ?? this.origin,
    roast: roast ?? this.roast,
    roastedOn: clearRoastedOn ? null : (roastedOn ?? this.roastedOn),
    memo: memo ?? this.memo,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'origin': origin,
    'roast': roast.name,
    'roastedOn': roastedOn?.toIso8601String(),
    'memo': memo,
  };

  factory Bean.fromJson(Map<String, Object?> json) => Bean(
    id: json['id'] as String,
    name: json['name'] as String,
    origin: (json['origin'] as String?) ?? '',
    roast: RoastLevel.fromName(json['roast']),
    roastedOn: _parseDate(json['roastedOn']),
    memo: (json['memo'] as String?) ?? '',
  );
}

class Recipe {
  const Recipe({this.beanGrams = 15, this.waterMl = 240, this.waterTempC = 90, this.bloomSeconds = 30, this.pours = 3});

  final int beanGrams;
  final int waterMl;
  final int waterTempC;
  final int bloomSeconds;

  /// 蒸らしの後に注ぐ回数
  final int pours;

  /// 豆:湯 の比率（1:n の n）
  double get ratio => waterMl / beanGrams;

  Recipe copyWith({int? beanGrams, int? waterMl, int? waterTempC, int? bloomSeconds, int? pours}) => Recipe(
    beanGrams: beanGrams ?? this.beanGrams,
    waterMl: waterMl ?? this.waterMl,
    waterTempC: waterTempC ?? this.waterTempC,
    bloomSeconds: bloomSeconds ?? this.bloomSeconds,
    pours: pours ?? this.pours,
  );

  Map<String, Object?> toJson() => {
    'beanGrams': beanGrams,
    'waterMl': waterMl,
    'waterTempC': waterTempC,
    'bloomSeconds': bloomSeconds,
    'pours': pours,
  };

  factory Recipe.fromJson(Map<String, Object?> json) => Recipe(
    beanGrams: (json['beanGrams'] as num).toInt(),
    waterMl: (json['waterMl'] as num).toInt(),
    waterTempC: (json['waterTempC'] as num).toInt(),
    bloomSeconds: (json['bloomSeconds'] as num).toInt(),
    pours: (json['pours'] as num).toInt(),
  );

  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.beanGrams == beanGrams &&
      other.waterMl == waterMl &&
      other.waterTempC == waterTempC &&
      other.bloomSeconds == bloomSeconds &&
      other.pours == pours;

  @override
  int get hashCode => Object.hash(beanGrams, waterMl, waterTempC, bloomSeconds, pours);
}

/// 1回分の抽出記録。豆が後で削除されても読めるよう、豆の名前を控えておく。
class BrewRecord {
  const BrewRecord({
    required this.id,
    required this.brewedAt,
    required this.beanId,
    required this.beanName,
    required this.recipe,
    required this.elapsedSeconds,
    required this.rating,
    this.acidity = 3,
    this.bitterness = 3,
    this.sweetness = 3,
    this.note = '',
  });

  final String id;
  final DateTime brewedAt;
  final String? beanId;
  final String beanName;
  final Recipe recipe;
  final int elapsedSeconds;

  /// ★1〜5
  final int rating;

  /// 味の評価。いずれも 1（弱い）〜 5（強い）
  final int acidity;
  final int bitterness;
  final int sweetness;
  final String note;

  Map<String, Object?> toJson() => {
    'id': id,
    'brewedAt': brewedAt.toIso8601String(),
    'beanId': beanId,
    'beanName': beanName,
    'recipe': recipe.toJson(),
    'elapsedSeconds': elapsedSeconds,
    'rating': rating,
    'acidity': acidity,
    'bitterness': bitterness,
    'sweetness': sweetness,
    'note': note,
  };

  factory BrewRecord.fromJson(Map<String, Object?> json) => BrewRecord(
    id: json['id'] as String,
    brewedAt: DateTime.parse(json['brewedAt'] as String),
    beanId: json['beanId'] as String?,
    beanName: json['beanName'] as String,
    recipe: Recipe.fromJson((json['recipe'] as Map).cast<String, Object?>()),
    elapsedSeconds: (json['elapsedSeconds'] as num).toInt(),
    rating: (json['rating'] as num).toInt().clamp(1, 5),
    acidity: (json['acidity'] as num?)?.toInt() ?? 3,
    bitterness: (json['bitterness'] as num?)?.toInt() ?? 3,
    sweetness: (json['sweetness'] as num?)?.toInt() ?? 3,
    note: (json['note'] as String?) ?? '',
  );
}

enum AppThemePreference {
  system('システムに合わせる'),
  light('ライト'),
  dark('ダーク');

  const AppThemePreference(this.label);
  final String label;

  static AppThemePreference fromName(Object? name) =>
      AppThemePreference.values.firstWhere((t) => t.name == name, orElse: () => AppThemePreference.system);
}

/// 端末に保存する内容のすべて。
class AppData {
  const AppData({
    this.beans = const [],
    this.records = const [],
    this.lastRecipe = const Recipe(),
    this.theme = AppThemePreference.system,
  });

  static const schemaVersion = 1;

  final List<Bean> beans;
  final List<BrewRecord> records;
  final Recipe lastRecipe;
  final AppThemePreference theme;

  AppData copyWith({List<Bean>? beans, List<BrewRecord>? records, Recipe? lastRecipe, AppThemePreference? theme}) =>
      AppData(
        beans: beans ?? this.beans,
        records: records ?? this.records,
        lastRecipe: lastRecipe ?? this.lastRecipe,
        theme: theme ?? this.theme,
      );

  Map<String, Object?> toJson() => {
    'schema': schemaVersion,
    'beans': [for (final b in beans) b.toJson()],
    'records': [for (final r in records) r.toJson()],
    'lastRecipe': lastRecipe.toJson(),
    'theme': theme.name,
  };

  /// 形式が想定と違う場合は [FormatException] などを投げる。呼び出し側で扱う。
  factory AppData.fromJson(Map<String, Object?> json) {
    final schema = json['schema'];
    if (schema is! int || schema > schemaVersion) {
      throw FormatException('未対応の保存形式です（schema: $schema）');
    }
    List<Map<String, Object?>> list(String key) => [
      for (final e in (json[key] as List? ?? const [])) (e as Map).cast<String, Object?>(),
    ];
    final recipe = json['lastRecipe'];
    return AppData(
      beans: [for (final b in list('beans')) Bean.fromJson(b)],
      records: [for (final r in list('records')) BrewRecord.fromJson(r)],
      lastRecipe: recipe is Map ? Recipe.fromJson(recipe.cast<String, Object?>()) : const Recipe(),
      theme: AppThemePreference.fromName(json['theme']),
    );
  }
}

DateTime? _parseDate(Object? value) => value is String ? DateTime.tryParse(value) : null;
