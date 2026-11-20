import 'package:brew_log/data/models.dart';
import 'package:brew_log/domain/brew_plan.dart';
import 'package:brew_log/ui/brew/timer_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

class _RecordingEffects extends DeviceEffects {
  final events = <String>[];
  @override
  void keepAwake(bool on) => events.add('awake:$on');
  @override
  void stepChanged() => events.add('step');
  @override
  void finished() => events.add('finished');
}

void main() {
  testWidgets('レシピを変えて抽出し、終わったら評価を記録すると記録タブに出る', (tester) async {
    final app = await pumpApp(tester, data: AppData(beans: sampleBeans));

    // 前回のレシピ（初期値）から注湯回数を1回減らす
    await tester.tap(find.byTooltip('注湯回数を減らす'));
    await tester.pump();
    expect(find.text('2投目'), findsOneWidget);
    expect(find.text('3投目'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'エチオピア グジ'));
    await tester.pump();
    await scrollTo(tester, find.text('抽出を始める'));
    await tester.tap(find.text('抽出を始める'));
    await tester.pumpAndSettle();

    expect(find.text('蒸らし'), findsWidgets);
    expect(find.text('0:30'), findsOneWidget);
    await tester.tap(find.text('スタート'));

    // 時計を進めながら描画する（30 + 30×2 + 45 = 135秒）
    for (var i = 0; i < 140; i++) {
      app.clock.now = app.clock.now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('完了'), findsOneWidget);
    await tester.tap(find.text('記録する'));
    await tester.pumpAndSettle();

    // ★を付けるまで保存できない
    final save = find.widgetWithText(FilledButton, '記録する');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.tap(find.byTooltip('★4'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '甘みが強い');
    await scrollTo(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final record = app.store.records.single;
    expect(record.rating, 4);
    expect(record.beanName, 'エチオピア グジ');
    expect(record.recipe.pours, 2);
    expect(record.elapsedSeconds, 135);
    expect(record.note, '甘みが強い');
    // 前回のレシピとして覚えている
    expect(app.store.data.lastRecipe.pours, 2);
    // 記録タブに切り替わっている
    expect(find.text('記録しました'), findsOneWidget);
    expect(find.text('甘みが強い'), findsNothing); // 一覧にはメモは出さない
    expect(find.widgetWithText(ListTile, 'エチオピア グジ'), findsOneWidget);
  });

  testWidgets('タイマー：一時停止・再開・リセット、ステップ切り替えで振動、画面中はスリープ防止', (tester) async {
    final app = await pumpApp(tester);
    final effects = _RecordingEffects();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TimerScreen(
            plan: BrewPlan.fromRecipe(const Recipe(bloomSeconds: 30, pours: 1)),
            bean: null,
            effects: effects,
            clock: app.clock.call,
          ),
        ),
      ),
    );
    expect(effects.events, ['awake:true']);

    Future<void> run(int seconds) async {
      for (var i = 0; i < seconds; i++) {
        app.clock.now = app.clock.now.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }
    }

    await tester.tap(find.text('スタート'));
    await run(10);
    expect(find.text('0:20'), findsOneWidget);

    await tester.tap(find.text('一時停止'));
    await tester.pump();
    app.clock.now = app.clock.now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0:20'), findsOneWidget);

    await tester.tap(find.text('再開'));
    await run(21);
    expect(find.text('1投目'), findsWidgets);
    expect(effects.events.where((e) => e == 'step'), hasLength(1));

    await tester.tap(find.text('リセット'));
    await tester.pump();
    expect(find.text('スタート'), findsOneWidget);
    expect(find.text('0:30'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(effects.events.last, 'awake:false');
  });

  testWidgets('実行中に戻ろうとすると確認が出る', (tester) async {
    await pumpApp(tester);
    await scrollTo(tester, find.text('抽出を始める'));
    await tester.tap(find.text('抽出を始める'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('スタート'));
    await tester.pump();

    await systemBack(tester);
    expect(find.text('抽出を中断しますか？'), findsOneWidget);
    await tester.tap(find.text('中断する'));
    await tester.pumpAndSettle();
    expect(find.text('抽出を始める'), findsOneWidget);
  });
}
