import 'package:brew_log/data/state_store.dart';
import 'package:brew_log/presentation/beans/beans_screen.dart';
import 'package:brew_log/presentation/settings/settings_screen.dart';
import 'package:brew_log/presentation/widgets/data_warning_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

Finder segmented(String label) => find.descendant(
  of: find.byType(SegmentedButton<ThemeMode>),
  matching: find.text(label),
);

Brightness brightnessOf(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(SettingsScreen))).brightness;

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
  expect(find.byType(SettingsScreen), findsOneWidget);
}

/// ListView を下までスクロールして対象を構築させる。
Future<void> reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isNotEmpty) return;
  await tester.scrollUntilVisible(
    target,
    240,
    scrollable: find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('テーマをライト／ダークへ切り替え、保存できる', (WidgetTester tester) async {
    final harness = await pumpApp(tester, state: sampleState());
    await openSettings(tester);

    await tester.tap(segmented('ダーク'));
    await tester.pumpAndSettle();
    expect(harness.store.snapshot.settings.themeMode, ThemeMode.dark);
    expect(brightnessOf(tester), Brightness.dark);

    await tester.tap(segmented('ライト'));
    await tester.pumpAndSettle();
    expect(harness.store.snapshot.settings.themeMode, ThemeMode.light);
    expect(brightnessOf(tester), Brightness.light);

    await tester.tap(segmented('システム'));
    await tester.pumpAndSettle();
    expect(harness.store.snapshot.settings.themeMode, ThemeMode.system);
  });

  testWidgets('データ件数が設定画面に表示される', (WidgetTester tester) async {
    await pumpApp(tester, state: sampleState());
    await openSettings(tester);

    await reveal(tester, find.text('登録済みの豆'));
    expect(find.text('レシピ'), findsWidgets);
    expect(find.text('5 件'), findsOneWidget);
    // 豆とレシピが同数なので '2 件' は2箇所出る
    expect(find.text('2 件'), findsNWidgets(2));
  });

  testWidgets('全データ削除は確認ダイアログを挟んで空になる', (WidgetTester tester) async {
    final harness = await pumpApp(tester, state: sampleState());
    await openSettings(tester);

    await reveal(tester, find.text('全データを削除'));
    await tester.tap(find.text('全データを削除'));
    await tester.pumpAndSettle();
    expect(find.text('全データを削除しますか？'), findsOneWidget);

    await tester.tap(find.text('すべて削除'));
    await tester.pumpAndSettle();

    expect(harness.store.snapshot.beans, isEmpty);
    expect(harness.store.snapshot.extractions, isEmpty);
    expect(find.text('全データを削除しました'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('まずは豆を登録しましょう'), findsWidgets);
  });

  testWidgets('ダイアログでやめるとデータは残る', (WidgetTester tester) async {
    final harness = await pumpApp(tester, state: sampleState());
    await openSettings(tester);

    await reveal(tester, find.text('全データを削除'));
    await tester.tap(find.text('全データを削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();

    expect(harness.store.snapshot.beans.length, 2);
  });

  testWidgets('壊れたデータでは警告バナーが出て、設定に理由が残る', (WidgetTester tester) async {
    await pumpApp(
      tester,
      failure: const StoreFailure(
        kind: StoreFailureKind.corrupt,
        message: '保存データが壊れていたため、空の状態から始めます。元のデータは端末内に退避しました。',
        backupKey: 'brew_log.corrupt.1730000000000',
        detail: 'FormatException: Unexpected end of input',
      ),
    );

    expect(find.byType(DataWarningBanner), findsOneWidget);
    expect(find.text('保存データを読み込めませんでした'), findsOneWidget);

    // バナーを閉じても、設定画面には残り続ける。
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(DataWarningBanner), findsNothing);

    await openSettings(tester);
    await reveal(tester, find.textContaining('保存データの状態'));
    expect(find.textContaining('brew_log.corrupt.'), findsOneWidget);
    expect(find.textContaining('FormatException'), findsOneWidget);
  });

  testWidgets('未来スキーマのデータでは自動保存が止まる', (WidgetTester tester) async {
    final harness = await pumpApp(
      tester,
      state: sampleState(),
      failure: const StoreFailure(
        kind: StoreFailureKind.newerVersion,
        message: 'このデータは新しいバージョン（スキーマ v9）で保存されています。',
      ),
    );

    expect(find.textContaining('より新しいバージョンのデータです'), findsOneWidget);
    expect(harness.store.saveCount, 0);

    await openSettings(tester);
    await reveal(tester, find.textContaining('自動保存は停止中です'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('保存に失敗したことはスナックバーで知らせる', (WidgetTester tester) async {
    final harness = await pumpApp(tester, state: sampleState());
    harness.store.failNextSave = true;

    await tester.tap(find.widgetWithText(NavigationDestination, '豆'));
    await tester.pumpAndSettle();
    await tester.drag(
      find
          .descendant(
            of: find.byType(BeansScreen),
            matching: find.byType(Dismissible),
          )
          .first,
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('テストによる意図的な保存失敗'), findsOneWidget);
  });

  testWidgets('設定画面を閉じると元のタブに戻る', (WidgetTester tester) async {
    await pumpApp(tester, state: sampleState());
    await tester.tap(find.widgetWithText(NavigationDestination, '見返す'));
    await tester.pumpAndSettle();
    await openSettings(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'ふりかえり'), findsOneWidget);
  });
}
