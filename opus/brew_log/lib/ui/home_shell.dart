import 'package:material_ui/material_ui.dart';

import '../state/app_store.dart';
import 'beans/beans_screen.dart';
import 'brew/recipe_screen.dart';
import 'history/history_screen.dart';
import 'stats/stats_screen.dart';
import 'theme/tokens.dart';

/// 下部ナビゲーションで4つのタブを切り替える
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  final int initialTab;

  static const brewTab = 0;
  static const historyTab = 1;

  /// 子孫の画面からタブを切り替える
  static void selectTab(BuildContext context, int index) {
    if (!context.mounted) return;
    context.findAncestorStateOfType<_HomeShellState>()?.select(index);
  }

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialTab;

  void select(int index) => setState(() => _index = index);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showStartupNotice());
  }

  void _showStartupNotice() {
    final store = AppScope.read(context);
    final notice = store.startupNotice;
    if (notice == null || !mounted) return;
    store.startupNotice = null;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showMaterialBanner(
      MaterialBanner(
        leading: const Icon(Icons.info_outline),
        content: Text(notice),
        actions: [TextButton(onPressed: messenger.hideCurrentMaterialBanner, child: const Text('閉じる'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saveError = AppScope.of(context).saveError;
    return Scaffold(
      body: Column(
        children: [
          if (saveError != null)
            MaterialBanner(
              content: Text(saveError),
              leading: const Icon(Icons.error_outline),
              actions: const [SizedBox.shrink()],
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.short,
              switchInCurve: Motion.curve,
              child: KeyedSubtree(
                key: ValueKey(_index),
                child: switch (_index) {
                  0 => const RecipeScreen(),
                  1 => const HistoryScreen(),
                  2 => const BeansScreen(),
                  _ => const StatsScreen(),
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: select,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: '淹れる'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '記録'),
          NavigationDestination(icon: Icon(Icons.grain_outlined), selectedIcon: Icon(Icons.grain), label: '豆'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: '振り返り'),
        ],
      ),
    );
  }
}
