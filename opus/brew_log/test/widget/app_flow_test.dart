import 'dart:convert';

import 'package:brew_log/data/repositories/brew_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

void main() {
  group('空状態', () {
    testWidgets('各タブに空状態と次の行動のボタンが出る', (tester) async {
      await pumpApp(tester);

      // 抽出タブ: 豆が無いので登録への案内
      expect(find.text('豆を登録する'), findsOneWidget);

      await openTab(tester, '豆');
      expect(find.text('まだ豆が登録されていません'), findsOneWidget);
      expect(find.text('最初の豆を登録'), findsOneWidget);

      await openTab(tester, '記録');
      expect(find.text('まだ抽出の記録がありません'), findsOneWidget);

      await openTab(tester, '振り返り');
      expect(find.text('振り返るデータがまだありません'), findsOneWidget);

      // 空状態のボタンで抽出タブへ移動できる
      await tester.tap(find.text('抽出をはじめる'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('start-brew')), findsOneWidget);
    });
  });

  testWidgets('豆を登録すると一覧に出て、保存もされる', (tester) async {
    final env = await pumpApp(tester);
    await openTab(tester, '豆');

    await tester.tap(find.text('最初の豆を登録'));
    await tester.pumpAndSettle();

    // 名前が空だと保存できない
    await tester.tap(find.byKey(const ValueKey('bean-save')));
    await tester.pumpAndSettle();
    expect(find.text('名前を入力してください'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('bean-name')), 'ケニア AA');
    await tester.enterText(find.byKey(const ValueKey('bean-origin')), 'ケニア');
    await tester.tap(find.text('浅煎り'));
    await tester.tap(find.byKey(const ValueKey('bean-save')));
    await tester.pumpAndSettle();

    expect(find.text('ケニア AA'), findsOneWidget);
    expect(find.text('浅煎り'), findsOneWidget);
    expect(find.text('焙煎から'), findsOneWidget);
    expect(env.store.values[BrewLogRepository.beansKey], contains('ケニア AA'));
  });

  testWidgets('タイマーで淹れて記録するまでの一連の流れ', (tester) async {
    final env = await pumpApp(
      tester,
      stored: {
        BrewLogRepository.beansKey: jsonEncode([testBean().toJson()]),
      },
    );

    await tester.tap(find.text('テスト豆'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start-brew')));
    await tester.pumpAndSettle();

    // 開始前: 蒸らしの目標 30ml、残り 0:30
    expect(find.text('蒸らし'), findsOneWidget);
    expect(find.text('0:30'), findsOneWidget);
    expect(find.textContaining('30'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('timer-toggle')));
    await tester.pump();
    expect(env.device.keepScreenOnCalls, [true]);

    // 31 秒後 → 1投目に切り替わり、ハプティクスが鳴る
    env.device.advance(const Duration(seconds: 31));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1投目'), findsOneWidget);
    expect(env.device.stepChangedCount, 1);

    // 一時停止でスリープ抑止を解除
    await tester.tap(find.byKey(const ValueKey('timer-toggle')));
    await tester.pump();
    expect(env.device.keepScreenOnCalls, [true, false]);

    // 再開して最後まで
    await tester.tap(find.byKey(const ValueKey('timer-toggle')));
    await tester.pump();
    env.device.advance(const Duration(seconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('抽出完了'), findsOneWidget);
    expect(env.device.finishedCount, 1);

    await tester.tap(find.byKey(const ValueKey('record-brew')));
    await tester.pumpAndSettle();
    expect(find.text('味を記録'), findsOneWidget);

    // 評価なしでは保存できない
    final save = find.byKey(const ValueKey('save-record'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('star-4')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '甘さが良い');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    // 記録タブに切り替わり、記録が並ぶ
    expect(find.text('記録'), findsWidgets);
    expect(find.widgetWithText(Card, 'テスト豆'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'テスト豆'), findsOneWidget);
    expect(find.text('甘さが良い'), findsOneWidget);
    expect(env.store.values[BrewLogRepository.recordsKey], contains('甘さが良い'));
  });

  testWidgets('履歴は豆で絞り込める', (tester) async {
    final now = DateTime.now();
    await pumpApp(
      tester,
      stored: {
        BrewLogRepository.beansKey: jsonEncode([
          testBean(id: 'a', name: '豆A').toJson(),
          testBean(id: 'b', name: '豆B').toJson(),
        ]),
        BrewLogRepository.recordsKey: jsonEncode([
          testRecord(id: '1', beanId: 'a', beanName: '豆A', at: now).toJson(),
          testRecord(id: '2', beanId: 'b', beanName: '豆B', at: now).toJson(),
          testRecord(id: '3', beanId: 'b', beanName: '豆B', at: now).toJson(),
        ]),
      },
    );
    await openTab(tester, '記録');

    final cards = find.byType(Card);
    expect(cards, findsNWidgets(3));

    await tester.tap(find.widgetWithText(FilterChip, '豆B'));
    await tester.pumpAndSettle();
    expect(cards, findsNWidgets(2));

    await tester.tap(find.widgetWithText(FilterChip, 'すべて'));
    await tester.pumpAndSettle();
    expect(cards, findsNWidgets(3));

    // 詳細を開ける
    await tester.tap(find.widgetWithText(Card, '豆A'));
    await tester.pumpAndSettle();
    expect(find.text('記録の詳細'), findsOneWidget);
    expect(find.text('1:16.0'), findsOneWidget);
  });

  testWidgets('振り返りに30日の回数・平均とランキングが出る', (tester) async {
    final now = DateTime.now();
    await pumpApp(
      tester,
      stored: {
        BrewLogRepository.beansKey: jsonEncode([
          testBean(id: 'a', name: '豆A').toJson(),
          testBean(id: 'b', name: '豆B').toJson(),
        ]),
        BrewLogRepository.recordsKey: jsonEncode([
          testRecord(id: '1', beanId: 'a', at: now, rating: 3).toJson(),
          testRecord(id: '2', beanId: 'b', at: now, rating: 5).toJson(),
          testRecord(
            id: '3',
            beanId: 'b',
            at: now.subtract(const Duration(days: 60)),
            rating: 4,
          ).toJson(),
        ]),
      },
    );
    await openTab(tester, '振り返り');

    // 直近30日は2件、平均 4.0
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('stat-count')),
        matching: find.textContaining('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('stat-average')),
        matching: find.textContaining('4.0'),
      ),
      findsOneWidget,
    );
    // ランキングは全期間: 豆B 4.5 > 豆A 3.0
    final b = tester.getTopLeft(find.text('豆B'));
    final a = tester.getTopLeft(find.text('豆A'));
    expect(b.dy, lessThan(a.dy));
    expect(find.text('4.5'), findsOneWidget);
  });

  testWidgets('設定から全データを削除できる（確認ダイアログ付き）', (tester) async {
    final env = await pumpApp(
      tester,
      stored: {
        BrewLogRepository.beansKey: jsonEncode([testBean().toJson()]),
      },
    );
    await tester.tap(find.byTooltip('設定').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('delete-all')));
    await tester.pumpAndSettle();
    expect(find.text('すべてのデータを削除しますか？'), findsOneWidget);

    // キャンセルでは消えない
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(env.store.values[BrewLogRepository.beansKey], isNotNull);

    await tester.tap(find.byKey(const ValueKey('delete-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-delete-all')));
    await tester.pumpAndSettle();
    expect(env.store.values[BrewLogRepository.beansKey], isNull);
    expect(find.text('削除するデータはありません'), findsOneWidget);
  });

  testWidgets('テーマを切り替えられる', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('設定').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('ダーク'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('テーマ'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text('ライト'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('テーマ'))).brightness,
      Brightness.light,
    );
  });

  testWidgets('保存データが壊れていてもクラッシュせず、バナーで知らせる', (tester) async {
    await pumpApp(tester, stored: {BrewLogRepository.recordsKey: '<<broken>>'});
    expect(find.textContaining('抽出記録のデータが壊れていた'), findsOneWidget);

    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.textContaining('壊れていた'), findsNothing);
  });
}
