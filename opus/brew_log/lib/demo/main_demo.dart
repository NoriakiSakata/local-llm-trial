// スクリーンショット撮影用の入口。製品のコードからは読み込まれない。
//
//   fvm flutter run -t lib/demo/main_demo.dart --dart-define=SCENE_FILE=/path/to/scene.txt
//
// SCENE_FILE に「stats:dark」のように書くと、その画面に切り替わる（シミュレータはホストのファイルを読める）。
import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../data/models.dart';
import '../data/storage.dart';
import '../domain/brew_plan.dart';
import '../state/app_store.dart';
import '../ui/brew/timer_screen.dart';
import '../ui/history/record_detail_screen.dart';
import '../ui/settings/settings_screen.dart';
import 'demo_data.dart';

const _sceneFile = String.fromEnvironment('SCENE_FILE');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _DemoHost());
}

class _DemoHost extends StatefulWidget {
  const _DemoHost();

  @override
  State<_DemoHost> createState() => _DemoHostState();
}

class _DemoHostState extends State<_DemoHost> {
  String _scene = 'brew:light';
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    if (_sceneFile.isNotEmpty) {
      _poll = Timer.periodic(const Duration(milliseconds: 300), (_) {
        final f = File(_sceneFile);
        if (!f.existsSync()) return;
        final s = f.readAsStringSync().trim();
        if (s.isNotEmpty && s != _scene) setState(() => _scene = s);
      });
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final [name, mode] = [..._scene.split(':'), 'light'].take(2).toList();
    final now = demoNow;
    final store = AppStore(
      repository: AppRepository(MemoryStore()),
      initial: (name == 'empty' ? const AppData() : demoData()).copyWith(
        theme: mode == 'dark' ? AppThemePreference.dark : AppThemePreference.light,
      ),
      clock: () => now,
    );
    final nav = GlobalKey<NavigatorState>();
    final tab = switch (name) {
      'history' || 'detail' => 1,
      'beans' || 'empty' => 2,
      'stats' => 3,
      _ => 0,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = switch (name) {
        'timer' => MaterialPageRoute<void>(
          builder: (_) => TimerScreen(
            plan: BrewPlan.fromRecipe(store.data.lastRecipe),
            bean: store.beans.first,
            clock: _frozenAfterStart(now, const Duration(seconds: 52)),
            autoStart: true,
          ),
        ),
        'detail' => MaterialPageRoute<void>(builder: (_) => RecordDetailScreen(recordId: store.records.first.id)),
        'settings' => MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
        _ => null,
      };
      if (route != null) nav.currentState?.push(route);
    });
    return BrewLogApp(key: ValueKey(_scene), store: store, initialTab: tab, navigatorKey: nav);
  }
}

/// 最初の呼び出しだけ [start]、以降は [start] + [elapsed] を返す（タイマー途中の画面を固定で撮る）
Clock _frozenAfterStart(DateTime start, Duration elapsed) {
  var first = true;
  return () {
    if (first) {
      first = false;
      return start;
    }
    return start.add(elapsed);
  };
}
