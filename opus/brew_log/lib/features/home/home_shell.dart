import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../../state/app_providers.dart';
import '../beans/bean_list_screen.dart';
import '../brew/recipe_screen.dart';
import '../history/history_screen.dart';
import '../insights/insights_screen.dart';
import 'storage_issue_banner.dart';

/// 下部ナビゲーションで 4 つのタブを切り替える土台。
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.coffee_maker_outlined),
      selectedIcon: Icon(Icons.coffee_maker_rounded),
      label: '抽出',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2_rounded),
      label: '豆',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_rounded),
      selectedIcon: Icon(Icons.history_rounded),
      label: '記録',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights_rounded),
      label: '振り返り',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(homeTabProvider);
    final hasIssues = ref.watch(
      storageIssuesProvider.select((issues) => issues.isNotEmpty),
    );
    final body = switch (tab) {
      HomeTab.brew => const RecipeScreen(),
      HomeTab.beans => const BeanListScreen(),
      HomeTab.history => const HistoryScreen(),
      HomeTab.insights => const InsightsScreen(),
    };

    return Scaffold(
      body: Column(
        children: [
          const StorageIssueBanner(),
          Expanded(
            // バナーがステータスバー分の余白を持つので、下の画面からは外す
            child: MediaQuery.removePadding(
              context: context,
              removeTop: hasIssues,
              // タブ切替は控えめなフェードスルー
              child: AnimatedSwitcher(
                duration: AppMotion.medium,
                switchInCurve: AppMotion.standard,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.98, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(tab), child: body),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) =>
            ref.read(homeTabProvider.notifier).select(HomeTab.values[i]),
        destinations: _destinations,
      ),
    );
  }
}
