import 'package:brew_log/app.dart';
import 'package:brew_log/data/models.dart';
import 'package:brew_log/data/storage.dart';
import 'package:brew_log/state/app_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// テスト用の時計。[advance] で進める
class TestClock {
  TestClock(this.now);
  DateTime now;
  DateTime call() => now;
}

class TestApp {
  TestApp(this.store, this.kv, this.clock);
  final AppStore store;
  final MemoryStore kv;
  final TestClock clock;
}

/// アプリを起動する。[width] で画面幅（dp）を指定できる
Future<TestApp> pumpApp(
  WidgetTester tester, {
  AppData data = const AppData(),
  String? startupNotice,
  int initialTab = 0,
  double width = 390,
  double height = 844,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

  final clock = TestClock(DateTime(2026, 11, 18, 8, 0));
  final kv = MemoryStore();
  final store = AppStore(repository: AppRepository(kv), initial: data, startupNotice: startupNotice, clock: clock.call);
  await tester.pumpWidget(BrewLogApp(store: store, initialTab: initialTab));
  await tester.pumpAndSettle();
  return TestApp(store, kv, clock);
}

final sampleBeans = [
  Bean(id: 'b1', name: 'エチオピア グジ', origin: 'エチオピア', roast: RoastLevel.light, roastedOn: DateTime(2026, 11, 8)),
  Bean(id: 'b2', name: 'ブラジル セラード', origin: 'ブラジル', roast: RoastLevel.dark, roastedOn: DateTime(2026, 10, 1)),
];

BrewRecord sampleRecord(String id, DateTime at, {String beanId = 'b1', String beanName = 'エチオピア グジ', int rating = 4}) =>
    BrewRecord(
      id: id,
      brewedAt: at,
      beanId: beanId,
      beanName: beanName,
      recipe: const Recipe(),
      elapsedSeconds: 165,
      rating: rating,
      note: 'メモ$id',
    );

AppData sampleData() => AppData(
  beans: sampleBeans,
  records: [
    sampleRecord('r1', DateTime(2026, 11, 17, 7, 30), rating: 5),
    sampleRecord('r2', DateTime(2026, 11, 15, 7, 10), beanId: 'b2', beanName: 'ブラジル セラード', rating: 3),
    sampleRecord('r3', DateTime(2026, 11, 12, 8, 0), rating: 4),
  ],
);

/// 下部ナビのタブを押す
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

/// システムの「戻る」操作
Future<void> systemBack(WidgetTester tester) async {
  await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
  await tester.pumpAndSettle();
}

/// Text.rich も含めて文字を探す
Finder findRich(String text) => find.text(text, findRichText: true);

/// 画面の一番外側のリストをスクロールして [finder] を表示する
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}
