/// 永続化されるデータを束ねた不変スナップショット。
///
/// 保存の単位はこのオブジェクト1個。JSON のトップレベルにスキーマ番号を持たせ、
/// 将来の移行に備える。
library;

import 'bean.dart';
import 'extraction.dart';
import 'recipe.dart';
import 'settings.dart';
import '../json_io.dart';

final class PersistedState {
  const PersistedState({
    this.beans = const <Bean>[],
    this.recipes = const <Recipe>[],
    this.extractions = const <Extraction>[],
    this.settings = const AppSettings(),
  });

  static const int schemaVersion = 1;

  final List<Bean> beans;
  final List<Recipe> recipes;
  final List<Extraction> extractions;
  final AppSettings settings;

  static const PersistedState empty = PersistedState();

  PersistedState copyWith({
    List<Bean>? beans,
    List<Recipe>? recipes,
    List<Extraction>? extractions,
    AppSettings? settings,
  }) {
    return PersistedState(
      beans: beans ?? this.beans,
      recipes: recipes ?? this.recipes,
      extractions: extractions ?? this.extractions,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
    'schema': schemaVersion,
    'beans': beans.map((Bean e) => e.toJson()).toList(),
    'recipes': recipes.map((Recipe e) => e.toJson()).toList(),
    'extractions': extractions.map((Extraction e) => e.toJson()).toList(),
    'settings': settings.toJson(),
  };

  /// デコードは常に [DataShapeException] を送りうる。呼び出し側で捕まえる。
  static PersistedState fromJson(JsonMap json) {
    final int schema = json.integer('schema', 'データ', fallback: 1);
    if (schema > schemaVersion) {
      throw NewerSchemaException(schema);
    }
    return PersistedState(
      beans: json
          .list('beans', 'データ')
          .map(Bean.fromJson)
          .toList(growable: false),
      recipes: json
          .list('recipes', 'データ')
          .map(Recipe.fromJson)
          .toList(growable: false),
      extractions: json
          .list('extractions', 'データ')
          .map(Extraction.fromJson)
          .toList(growable: false),
      settings: AppSettings.fromJson(
        JsonMap.require(json.rawOrNull('settings') ?? const {}, 'データ.settings'),
      ),
    );
  }
}

/// より新しいスキーマで書き出されたデータを読んでしまったときのエラー。
class NewerSchemaException implements Exception {
  const NewerSchemaException(this.foundVersion);

  final int foundVersion;
}
