import 'package:brew_log/presentation/beans/beans_screen.dart';
import 'package:brew_log/presentation/log/extractions_screen.dart';
import 'package:brew_log/presentation/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

Future<void> openLogTab(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(NavigationDestination, '記録'));
  await tester.pumpAndSettle();
}

Finder logTiles(WidgetTester tester) => find.descendant(
  of: find.byType(ExtractionsScreen),
  matching: find.byType(Dismissible),
);

/// 横スクロールの chips を確実に押す（未構築の item は ensureVisible できない）。
Future<void> tapChip(WidgetTester tester, Finder chip) async {
  if (chip.evaluate().isNotEmpty) {
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
  }
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('記録が0件なら案内を出す', (WidgetTester tester) async {
    await pumpApp(tester);
    await openLogTab(tester);
    expect(find.text('まだ記録がありません'), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('記録一覧と日付ヘッダー、評価★が表示される', (WidgetTester tester) async {
    await pumpApp(tester, state: sampleState(), now: DateTime(2026, 10, 30, 9));
    await openLogTab(tester);

    expect(logTiles(tester), findsNWidgets(5));
    expect(find.text('2026年10月30日'), findsOneWidget);
    expect(find.text('2026年9月29日'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
  });

  testWidgets('豆で絞り込むと該当する記録だけ残る', (WidgetTester tester) async {
    await pumpApp(tester, state: sampleState());
    await openLogTab(tester);

    await tapChip(tester, find.widgetWithText(FilterChip, 'エチオピア ゲイシャ'));
    expect(logTiles(tester), findsNWidgets(3));

    // 同じ chip をもう一度押すとフィルタが外れる（トグル）。
    await tapChip(tester, find.widgetWithText(FilterChip, 'エチオピア ゲイシャ'));
    expect(logTiles(tester), findsNWidgets(5));
  });

  testWidgets('記録を削除しても Undo で復元できる', (WidgetTester tester) async {
    final harness = await pumpApp(tester, state: sampleState());
    await openLogTab(tester);

    await tester.drag(logTiles(tester).first, const Offset(-420, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();
    expect(harness.store.snapshot.extractions.length, 4);

    await tester.tap(find.text('戻す'));
    await tester.pumpAndSettle();
    expect(harness.store.snapshot.extractions.length, 5);
    expect(harness.store.snapshot.extractions.first.id, 'ex-1');
  });

  testWidgets('詳細から削除すると一覧へ戻り記録が消える', (WidgetTester tester) async {
    final harness = await pumpApp(tester, state: sampleState());
    await openLogTab(tester);

    await tester.tap(logTiles(tester).first);
    await tester.pumpAndSettle();
    expect(find.text('記録の詳細'), findsOneWidget);
    expect(find.text('注湯タイムライン'), findsOneWidget);
    expect(find.text('香りが立っている'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(harness.store.snapshot.extractions.length, 4);
    expect(find.text('記録の詳細'), findsNothing);
  });

  testWidgets('記録した豆を一覧から消すとフィルタが外れて全件戻る', (WidgetTester tester) async {
    await pumpApp(tester, state: sampleState());
    await openLogTab(tester);

    await tapChip(tester, find.widgetWithText(FilterChip, 'エチオピア ゲイシャ'));
    expect(logTiles(tester), findsNWidgets(3));

    // 豆タブに出て、該当する豆をスワイプ削除する。
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
    await tester.pumpAndSettle();

    await openLogTab(tester);
    expect(logTiles(tester), findsNWidgets(5));
    expect(
      find.descendant(
        of: find.byType(ExtractionsScreen),
        matching: find.widgetWithText(FilterChip, 'すべての豆'),
      ),
      findsOneWidget,
    );
  });
}
