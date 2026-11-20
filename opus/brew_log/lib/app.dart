import 'package:material_ui/material_ui.dart';

import 'data/models.dart';
import 'state/app_store.dart';
import 'ui/home_shell.dart';
import 'ui/theme/app_theme.dart';

class BrewLogApp extends StatelessWidget {
  const BrewLogApp({super.key, required this.store, this.initialTab = 0, this.navigatorKey});

  final AppStore store;

  /// スクリーンショット撮影用。通常は 0（淹れる）
  final int initialTab;

  /// スクリーンショット撮影用
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => MaterialApp(
          title: 'Brew Log',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: switch (store.data.theme) {
            AppThemePreference.system => ThemeMode.system,
            AppThemePreference.light => ThemeMode.light,
            AppThemePreference.dark => ThemeMode.dark,
          },
          locale: const Locale('ja'),
          supportedLocales: const [Locale('ja')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: HomeShell(initialTab: initialTab),
        ),
      ),
    );
  }
}
