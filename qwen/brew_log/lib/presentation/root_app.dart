import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import 'home_shell.dart';
import '../theme/app_theme.dart';

/// MaterialApp の設定とテーマ切替を担うルート。
class RootApp extends ConsumerWidget {
  const RootApp({this.initialIndex = 0, this.initialRoute, super.key});

  /// 起動時に見せるタブ（スクリーンショット生成用）。0 = 淹れる。
  final int initialIndex;

  /// 起動直後に開く画面（'settings'）。外部ディープリンク用の口。
  final String? initialRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Brew Log',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(appDataProvider).settings.themeMode,
      locale: const Locale('ja'),
      supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeShell(initialIndex: initialIndex, initialRoute: initialRoute),
    );
  }
}
