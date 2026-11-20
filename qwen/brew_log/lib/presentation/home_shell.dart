import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/app_data.dart';
import '../application/providers.dart';
import '../data/state_store.dart' show StoreFailure;
import '../theme/tokens.dart';
import 'beans/beans_screen.dart';
import 'brew/brew_screen.dart';
import 'log/extractions_screen.dart';
import 'settings/settings_screen.dart';
import 'stats/stats_screen.dart';
import 'widgets/data_warning_banner.dart';

/// 4つのタブ + 設定への入口。アプリの骨格。
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({this.initialIndex = 0, this.initialRoute, super.key});

  /// 起動時に見せるタブ。既定は「淹れる」。
  /// スクリーンショット生成用のエントリポイント（lib/demo）から渡す。
  final int initialIndex;

  /// 起動直後に重ねて開く画面。現状は 'settings' のみ。
  /// 外部ディープリンクを受け取るための口も兼ねる。
  final String? initialRoute;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const List<_Destination> _destinations = <_Destination>[
    _Destination('淹れる', 'タイマー', Icons.timer_outlined, Icons.timer_rounded),
    _Destination(
      '記録',
      '抽出記録',
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
    ),
    _Destination('豆', '豆の管理', Icons.eco_outlined, Icons.eco_rounded),
    _Destination(
      '見返す',
      'ふりかえり',
      Icons.insights_outlined,
      Icons.insights_rounded,
    ),
  ];

  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoute != 'settings') return;
    // Navigator は初回ビルド後でないと push できないので、初フレーム後に重ねる。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openSettings();
    });
  }

  void _goTo(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // 自動保存の失敗だけは都度スナックバーで伝える（黙って失わせないため）。
    ref.listen<AppState>(appDataProvider, (AppState? previous, AppState next) {
      final String? error = next.saveError;
      if (error != null && error != previous?.saveError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(error),
              action: SnackBarAction(
                label: '閉じる',
                textColor: Theme.of(context).colorScheme.inversePrimary,
                onPressed: () =>
                    ref.read(appDataProvider.notifier).clearSaveError(),
              ),
            ),
          );
      }
    });

    final AppState data = ref.watch(appDataProvider);
    final StoreFailure? failure = data.failure;

    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[_index].appTitle),
        actions: <Widget>[
          IconButton(
            onPressed: _openSettings,
            tooltip: '設定',
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            if (failure != null && !data.failureAcknowledged)
              AnimatedSize(
                duration: AppMotion.normal,
                curve: AppMotion.standardCurve,
                alignment: Alignment.topCenter,
                child: DataWarningBanner(
                  failure: failure,
                  onDismiss: () =>
                      ref.read(appDataProvider.notifier).acknowledgeFailure(),
                  onOpenDetails: _openSettings,
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: <Widget>[
                  BrewScreen(onGoToTab: _goTo),
                  const ExtractionsScreen(),
                  BeansScreen(onGoToTab: _goTo),
                  StatsScreen(onGoToTab: _goTo),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: <Widget>[
          for (int i = 0; i < _destinations.length; i++)
            NavigationDestination(
              icon: Icon(_destinations[i].icon),
              selectedIcon: Icon(_destinations[i].selectedIcon),
              label: _destinations[i].title,
            ),
        ],
      ),
    );
  }
}

/// NavigationBar の項目定義。
class _Destination {
  const _Destination(this.title, this.appTitle, this.icon, this.selectedIcon);

  /// NavigationBar のラベル（短い語）。
  final String title;

  /// AppBar に出す画面名（ラベルとかぶらないようにする）。
  final String appTitle;
  final IconData icon;
  final IconData selectedIcon;
}
