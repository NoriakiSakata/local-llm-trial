import 'package:flutter/foundation.dart';

import 'json_read.dart';
import 'recipe.dart';

enum ThemePreference {
  system('システム'),
  light('ライト'),
  dark('ダーク');

  const ThemePreference(this.label);
  final String label;
}

@immutable
class AppSettings {
  const AppSettings({
    this.theme = ThemePreference.system,
    this.lastRecipe = Recipe.standard,
  });

  final ThemePreference theme;

  /// 前回使ったレシピ。次回のレシピ画面の初期値になる。
  final Recipe lastRecipe;

  AppSettings copyWith({ThemePreference? theme, Recipe? lastRecipe}) =>
      AppSettings(
        theme: theme ?? this.theme,
        lastRecipe: lastRecipe ?? this.lastRecipe,
      );

  Map<String, dynamic> toJson() => {
    'theme': theme.name,
    'lastRecipe': lastRecipe.toJson(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final themeName = json.opt<String>('theme');
    final recipeJson = json.opt<Map<String, dynamic>>('lastRecipe');
    return AppSettings(
      theme: ThemePreference.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => ThemePreference.system,
      ),
      lastRecipe: recipeJson == null
          ? Recipe.standard
          : Recipe.fromJson(recipeJson),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.theme == theme &&
      other.lastRecipe == lastRecipe;

  @override
  int get hashCode => Object.hash(theme, lastRecipe);
}
