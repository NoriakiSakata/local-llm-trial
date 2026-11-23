import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/app_settings.dart';
import '../data/models/bean.dart';
import '../data/models/brew_record.dart';
import '../data/models/recipe.dart';
import '../data/repositories/brew_log_repository.dart';
import '../features/brew/timer_screen.dart';
import '../features/home/home_shell.dart';
import '../state/app_providers.dart';

/// スクリーンショット撮影などの開発用デモデータ。
///
/// 通常の起動では何もしない。`--dart-define` で指定したときだけ動く。
///   fvm flutter run --dart-define=DEMO_DATA=true --dart-define=DEMO_TAB=insights
///
/// 指定できる値: DEMO_TAB = brew / beans / history / insights、
/// DEMO_THEME = light / dark、DEMO_SCREEN = timer
abstract final class DemoData {
  static const _enabled = bool.fromEnvironment('DEMO_DATA');
  static const _tab = String.fromEnvironment('DEMO_TAB');
  static const _theme = String.fromEnvironment('DEMO_THEME');
  static const _screen = String.fromEnvironment('DEMO_SCREEN');

  /// タイマー画面を開いた状態で起動するか
  static bool get openTimer => _enabled && _screen == 'timer';

  static HomeTab? get initialTab {
    if (!_enabled) return null;
    for (final t in HomeTab.values) {
      if (t.name == _tab) return t;
    }
    return null;
  }

  /// 既存データを上書きしてデモデータを書き込む。
  static Future<void> seedIfRequested(BrewLogRepository repo) async {
    if (!_enabled) return;
    final now = DateTime.now();
    DateTime daysAgo(int d, [int hour = 8]) =>
        DateTime(now.year, now.month, now.day - d, hour, 15);

    final beans = [
      Bean(
        id: 'demo-ethiopia',
        name: 'エチオピア イルガチェフェ',
        origin: 'エチオピア',
        roast: RoastLevel.light,
        roastedOn: daysAgo(6),
        memo: 'ウォッシュト。ジャスミンと柑橘の香り。',
        createdAt: daysAgo(6),
      ),
      Bean(
        id: 'demo-colombia',
        name: 'コロンビア ウィラ',
        origin: 'コロンビア',
        roast: RoastLevel.medium,
        roastedOn: daysAgo(12),
        memo: 'キャラメルのような甘さ。',
        createdAt: daysAgo(12),
      ),
      Bean(
        id: 'demo-sumatra',
        name: 'スマトラ マンデリン',
        origin: 'インドネシア',
        roast: RoastLevel.dark,
        roastedOn: daysAgo(20),
        memo: '',
        createdAt: daysAgo(20),
      ),
    ];

    BrewRecord rec(
      String id,
      Bean bean,
      int day,
      int rating,
      (int, int, int) taste,
      String note, {
      int hour = 8,
    }) => BrewRecord(
      id: id,
      beanId: bean.id,
      beanName: bean.name,
      recipe: Recipe.standard,
      brewedAt: daysAgo(day, hour),
      elapsedSec: 165,
      rating: rating,
      acidity: taste.$1,
      bitterness: taste.$2,
      sweetness: taste.$3,
      note: note,
    );

    final e = beans[0], c = beans[1], s = beans[2];
    final records = [
      rec('d1', e, 0, 5, (4, 2, 4), '92℃で華やか。酸が綺麗に出た。'),
      rec('d2', c, 1, 4, (3, 3, 4), '甘さがしっかり。'),
      rec('d3', s, 2, 3, (1, 5, 2), '少し苦味が強い。湯温を下げたい。'),
      rec('d4', e, 3, 4, (4, 2, 3), ''),
      rec('d5', c, 3, 4, (3, 3, 3), '', hour: 15),
      rec('d6', e, 5, 5, (5, 2, 4), 'これまでで一番。'),
      rec('d7', s, 7, 3, (2, 4, 2), ''),
      rec('d8', c, 9, 4, (2, 3, 4), ''),
      rec('d9', e, 12, 4, (4, 2, 3), ''),
      rec('d10', c, 14, 3, (2, 3, 3), '挽き目が粗かった。'),
      rec('d11', s, 17, 4, (1, 4, 3), ''),
      rec('d12', c, 21, 4, (3, 3, 4), ''),
      rec('d13', e, 24, 3, (5, 2, 2), '酸っぱすぎた。'),
    ];

    await repo.saveBeans(beans);
    await repo.saveRecords(records);
    await repo.saveSettings(
      AppSettings(
        theme: switch (_theme) {
          'dark' => ThemePreference.dark,
          'light' => ThemePreference.light,
          _ => ThemePreference.system,
        },
      ),
    );
  }
}

/// 起動時のタブを指定するための Notifier（デモ用）。
class InitialTabNotifier extends HomeTabNotifier {
  InitialTabNotifier(this.initial);

  final HomeTab initial;

  @override
  HomeTab build() => initial;
}

/// ホームを表示したあと、タイマー画面を自動で開いてスタートする（デモ用）。
class DemoTimerLauncher extends ConsumerStatefulWidget {
  const DemoTimerLauncher({super.key});

  @override
  ConsumerState<DemoTimerLauncher> createState() => _DemoTimerLauncherState();
}

class _DemoTimerLauncherState extends ConsumerState<DemoTimerLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final beans = ref.read(beansProvider);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TimerScreen(
            recipe: Recipe.standard,
            bean: beans.isEmpty ? null : beans.first,
            autoStart: true,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const HomeShell();
}
