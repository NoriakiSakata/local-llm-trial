import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/app_data.dart';
import '../application/brew_session.dart';
import '../application/providers.dart';
import '../data/models.dart';
import '../data/state_store.dart';
import '../presentation/root_app.dart';
import 'demo_data.dart';

/// スクリーンショット生成専用のエントリポイント。通常の実行には使わない。
///
/// データはメモリ内にだけ作り、実機の保存領域には触れない。
///
///   fvm flutter build ios --simulator -t lib/demo/demo_main.dart \
///     --dart-define=DEMO_TAB=running
///
/// tab: brew（既定）/ running / log / beans / stats / settings
const String _tab = String.fromEnvironment('DEMO_TAB', defaultValue: 'brew');

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final PersistedState state = demoState();
  final InMemoryStore store = InMemoryStore(state: state);
  final _Target target = _Target.of(_tab);

  runApp(
    ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
        appBootstrapProvider.overrideWithValue(AppBootstrap(state: state)),
        if (target.running) brewSessionProvider.overrideWith(_DemoSession.new),
      ],
      child: RootApp(initialIndex: target.index, initialRoute: target.route),
    ),
  );
}

/// DEMO_TAB の値を、タブ番号 / 追加ルート / 実行中セッションに対応させる。
class _Target {
  const _Target(this.index, this.route, this.running);

  final int index;
  final String? route;
  final bool running;

  static _Target of(String tab) => switch (tab) {
    'running' => const _Target(0, null, true),
    'log' => const _Target(1, null, false),
    'beans' => const _Target(2, null, false),
    'stats' => const _Target(3, null, false),
    'settings' => const _Target(0, 'settings', false),
    _ => const _Target(0, null, false),
  };
}

/// 淹れている最中の画面を静止させるためのセッション。
final class _DemoSession extends BrewSessionNotifier {
  @override
  BrewSession? build() => demoRunningSession();
}
