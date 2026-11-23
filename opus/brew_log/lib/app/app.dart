import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/app_settings.dart';
import '../dev/demo_data.dart';
import '../features/home/home_shell.dart';
import '../state/app_providers.dart';
import 'theme/app_theme.dart';

class BrewLogApp extends ConsumerWidget {
  const BrewLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(settingsProvider.select((s) => s.theme));
    return MaterialApp(
      title: 'Brew Log',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (preference) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      themeAnimationDuration: const Duration(milliseconds: 250),
      locale: const Locale('ja', 'JP'),
      supportedLocales: const [Locale('ja', 'JP')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: DemoData.openTimer ? const DemoTimerLauncher() : const HomeShell(),
    );
  }
}
