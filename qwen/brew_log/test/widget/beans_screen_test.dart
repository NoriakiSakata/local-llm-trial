import 'package:brew_log/data/models.dart';
import 'package:brew_log/presentation/beans/beans_screen.dart';
import 'package:brew_log/presentation/home_shell.dart';
import 'package:brew_log/presentation/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

Future<void> openBeansTab(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(NavigationDestination, '豆'));
  await tester.pumpAndSettle();
}

Finder beanList(WidgetTester tester) => find.descendant(
  of: find.byType(BeansScreen),
  matching: find.byType(Dismissible),
);

Finder beanName(WidgetTester tester, String name) =>
    find.descendant(of: find.byType(BeansScreen), matching: find.text(name));

/// スワイプ削除 → 確認ダイアログ → 実行、までを一気にやる。
Future<void> swipeDelete(WidgetTester tester, Finder target) async {
  await tester.drag(target.first, const Offset(-420, 0));
  await tester.pumpAndSettle();
  expect(find.text('豆を削除しますか？'), findsOneWidget);
  await tester.tap(find.text('削除する'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('起動するとタブと AppBar タイトルが出る', (WidgetTester tester) async {
    await pumpApp(tester, state: sampleState());
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'タイマー'), findsOneWidget);
    for (final String label in <String>['淹れる', '記録', '豆', '見返す']) {
      expect(find.widgetWithText(NavigationDestination, label), findsOneWidget);
    }
  });

  testWidgets('豆が0件なら空状態から登録画面へ進める', (WidgetTester tester) async {
    final harness = await pumpApp(tester);
    await openBeansTab(tester);

    expect(find.text('まだ豆が登録されていません'), findsOneWidget);
    expect(find.byType(EmptyState), findsWidgets);

    await tester.tap(find.text('最初の豆を登録'));
    await tester.pumpAndSettle();
    expect(find.text('豆を登録'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.byType(EditableText),
      ),
      'テスト用の豆',
    );
    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await tester.pumpAndSettle();

    expect(beanName(tester, 'テスト用の豆'), findsOneWidget);
    expect(harness.store.snapshot.beans.length, 1);
    expect(find.text('焙煎 0 日目'), findsOneWidget);
  });

  testWidgets('スワイプ → 確認で削除し、Undo で元の位置へ戻せる', (WidgetTester tester) async {
    final harness = await pumpApp(tester, state: sampleState());
    await openBeansTab(tester);

    expect(beanList(tester), findsNWidgets(2));
    await swipeDelete(tester, beanList(tester));

    expect(beanList(tester), findsNWidgets(1));
    expect(harness.store.snapshot.beans.length, 1);
    expect(find.text('エチオピア ゲイシャ を削除しました'), findsOneWidget);

    await tester.tap(find.text('戻す'));
    await tester.pumpAndSettle();
    expect(beanList(tester), findsNWidgets(2));
    expect(
      harness.store.snapshot.beans.map((Bean b) => b.id).toList(),
      <String>['bean-a', 'bean-b'],
    );
  });

  testWidgets('確認をやめれば豆は残る', (WidgetTester tester) async {
    final harness = await pumpApp(tester, state: sampleState());
    await openBeansTab(tester);

    await tester.drag(beanList(tester).first, const Offset(-420, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();

    expect(harness.store.snapshot.beans.length, 2);
  });

  testWidgets('編集画面で焙煎度を更新できる', (WidgetTester tester) async {
    final harness = await pumpApp(tester, state: sampleState());
    await openBeansTab(tester);

    await tester.tap(beanName(tester, 'エチオピア ゲイシャ'));
    await tester.pumpAndSettle();
    expect(find.text('豆を編集'), findsOneWidget);

    await tester.tap(find.text('深煎り'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await tester.pumpAndSettle();

    expect(harness.store.snapshot.beans.first.roast, RoastLevel.dark);
    expect(find.textContaining('深煎り'), findsWidgets);
  });

  testWidgets('名前は必須（空なら保存できない）', (WidgetTester tester) async {
    await pumpApp(tester, state: sampleState());
    await openBeansTab(tester);
    await tester.tap(find.widgetWithText(FloatingActionButton, '豆を追加'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await tester.pumpAndSettle();
    expect(find.text('名前を入力してください'), findsOneWidget);
  });

  testWidgets('幅360dpでも潰れずスクロールできる', (WidgetTester tester) async {
    await pumpApp(
      tester,
      state: sampleState(),
      logicalSize: const Size(360, 780),
    );
    await openBeansTab(tester);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView).first, const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Card), findsWidgets);
  });
}
