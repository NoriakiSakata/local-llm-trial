import 'package:flutter/material.dart' show ThemeMode;

import '../json_io.dart';

/// 設定画面から変更される永続化対象。
final class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.lastRecipeId,
    this.lastBeanId,
  });

  final ThemeMode themeMode;

  /// 直前に淹れたレシピ。起動時の初期選択に使う。
  final String? lastRecipeId;

  /// 設定で選択した「淹れる予定の豆」。
  final String? lastBeanId;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? lastRecipeId,
    String? lastBeanId,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      lastRecipeId: lastRecipeId ?? this.lastRecipeId,
      lastBeanId: lastBeanId ?? this.lastBeanId,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.key,
    if (lastRecipeId != null) 'lastRecipeId': lastRecipeId,
    if (lastBeanId != null) 'lastBeanId': lastBeanId,
  };

  static AppSettings fromJson(JsonMap json) => AppSettings(
    themeMode: ThemeModeX.fromKey(json.string('themeMode', '設定')),
    lastRecipeId: json.nullableString('lastRecipeId', '設定'),
    lastBeanId: json.nullableString('lastBeanId', '設定'),
  );
}

extension ThemeModeX on ThemeMode {
  String get key => switch (this) {
    ThemeMode.system => 'system',
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
  };

  static ThemeMode fromKey(String value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
