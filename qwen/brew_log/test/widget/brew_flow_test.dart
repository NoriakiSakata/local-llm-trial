import 'package:brew_log/application/brew_session.dart';
import 'package:brew_log/application/providers.dart';
import 'package:brew_log/data/models.dart';
import 'package:brew_log/presentation/brew/brew_idle_view.dart';
import 'package:brew_log/presentation/brew/brew_running_view.dart';
import 'package:brew_log/presentation/brew/rating_sheet.dart';
import 'package:brew_log/presentation/brew/recipe_editor_screen.dart';
import 'package:brew_log/presentation/home_shell.dart';
import 'package:brew_log/presentation/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

Finder runningText(WidgetTester tester, String text) => find.descendant(
  of: find.byType(BrewRunningView),
  matching: find.text(text),
);

/// 実行中セッション（Provider の実値を読む）。
BrewSession? sessionOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(HomeShell)))
        .read(brewSessionProvider);

Future<void> startTimer(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'タイマーをスタート'));
  // タイマーが動き出すので pumpAndSettle は使わない（永遠に落ち着かない）。
  await tester.pump();
}

void main() {
  testWidgets('豆もレシピも無いときは豆登録を勧める', (WidgetTester tester) async {
    await pumpApp(tester);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('まずは豆を登録しましょう'), findsOneWidget);
  });

  testWidgets('レシピを選ぶとステップと合計時間が追随する', (WidgetTester tester) async {
    await pumpApp(tester, state: sampleState());

    // recipeA: 蒸らし40秒 + 70ml×3（各12秒）= 76秒
    expect(find.textContaining('合計 1分16秒'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BrewIdleView),
        matching: find.text('ゆっくり3投'),
      ),
    );
    await tester.pump();
    // recipeB: 蒸らし45秒 + 132ml×2（各22秒）= 89秒
    expect(find.textContaining('合計 1分29秒'), findsOneWidget);
    expect(find.text('18 g'), findsOneWidget);
  });

  testWidgets('タイマー開始 → 蒸らし → 1投目 → 完了 → 保存', (WidgetTester tester) async {
    final harness = await pumpApp(tester, state: sampleState());
    await startTimer(tester);

    expect(find.byType(BrewRunningView), findsOneWidget);
    // 中央のステップ名と StepStrip の両方に出る
    expect(runningText(tester, '蒸らし'), findsWidgets);
    expect(sessionOf(tester)?.elapsedMs, 0);

    await harness.elapse(const Duration(seconds: 41));
    expect(sessionOf(tester)?.currentIndex, 1);
    expect(runningText(tester, '1投目'), findsWidgets);

    await harness.elapse(const Duration(seconds: 12));
    expect(sessionOf(tester)?.currentIndex, 2);
    expect(runningText(tester, '2投目'), findsWidgets);

    // 一時停止 → 時刻が進んでも経過は止まる
    await tester.tap(find.widgetWithText(FilledButton, '一時停止'));
    await tester.pump();
    final int frozen = sessionOf(tester)!.elapsedMs;
    expect(find.text('一時停止中'), findsOneWidget);
    harness.clock.advance(const Duration(seconds: 30));
    await tester.pump();
    expect(sessionOf(tester)!.elapsedMs, frozen);

    await tester.tap(find.widgetWithText(FilledButton, '再開'));
    await tester.pump();
    await harness.elapse(const Duration(seconds: 1));
    expect(sessionOf(tester)!.elapsedMs, frozen + 1000);

    // 手動完了で評価シートへ
    await tester.tap(find.byTooltip('ここで完了'));
    await tester.pumpAndSettle();
    expect(find.byType(RatingSheet), findsOneWidget);
    expect(sessionOf(tester)?.phase, BrewPhase.finished);

    await tester.tap(find.byTooltip('5 つ星'));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(TextField).last,
        matching: find.byType(EditableText),
      ),
      '柑橘のあとに甘さが残った',
    );
    await tester.tap(find.widgetWithText(FilledButton, '保存して完了'));
    await tester.pumpAndSettle();

    final List<Extraction> saved = harness.store.snapshot.extractions;
    expect(saved.length, 6);
    expect(saved.first.rating, 5);
    expect(saved.first.note, '柑橘のあとに甘さが残った');
    expect(saved.first.beanName, 'エチオピア ゲイシャ');
    expect(saved.first.pours.map((PourLog l) => l.label).toList(), <String>[
      '蒸らし',
      '1投目',
      '2投目',
      '3投目',
    ]);
    expect(sessionOf(tester), isNull, reason: '保存したらセッションは閉じる');
  });

  testWidgets('リセットすると蒸らしに戻る', (WidgetTester tester) async {
    final harness = await pumpApp(tester, state: sampleState());
    await startTimer(tester);
    await harness.elapse(const Duration(seconds: 50));
    expect(sessionOf(tester)!.elapsedMs, 50000);

    await tester.tap(find.widgetWithText(OutlinedButton, 'リセット'));
    await tester.pump();
    expect(find.byType(BrewRunningView), findsOneWidget);
    expect(sessionOf(tester)!.elapsedMs, 0);
    expect(sessionOf(tester)!.currentIndex, 0);
  });

  testWidgets('中断すると待機画面に戻る', (WidgetTester tester) async {
    await pumpApp(tester, state: sampleState());
    await startTimer(tester);

    await tester.tap(find.text('中断して終了'));
    await tester.pump();
    expect(sessionOf(tester), isNull);
    await tester.pumpAndSettle();
    expect(find.byType(BrewRunningView), findsNothing);
    expect(find.widgetWithText(FilledButton, 'タイマーをスタート'), findsOneWidget);
  });

  testWidgets('新しいレシピを作ってそのまま淹れられる', (WidgetTester tester) async {
    final harness = await pumpApp(tester, state: sampleState());

    await tester.tap(find.text('新しいレシピを作る'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeEditorScreen), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.byType(EditableText),
      ),
      '夕方用',
    );
    // 注湯回数を4回に変える
    await tester.tap(find.widgetWithText(ChoiceChip, '4回'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await tester.pumpAndSettle();

    expect(harness.store.snapshot.recipes.length, 3);
    final Recipe made = harness.store.snapshot.recipes.last;
    expect(made.name, '夕方用');
    expect(made.pours, 4);
    expect(made.id, isNotEmpty);

    await tester.tap(
      find.descendant(
        of: find.byType(BrewIdleView),
        matching: find.text('夕方用'),
      ),
    );
    await tester.pump();
    await startTimer(tester);
    expect(find.byType(BrewRunningView), findsOneWidget);
    expect(sessionOf(tester)!.plan.steps.length, 5);
  });

  testWidgets('レシピ名を空にするとバリデーションで止められる', (WidgetTester tester) async {
    await pumpApp(tester, state: sampleState());
    await tester.tap(find.text('新しいレシピを作る'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.byType(EditableText),
      ),
      '   ',
    );
    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('レシピ名を入力してください'), findsOneWidget);
    expect(find.byType(RecipeEditorScreen), findsOneWidget);
  });
}
