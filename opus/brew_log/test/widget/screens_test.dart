import 'package:brew_log/data/models.dart';
import 'package:brew_log/data/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

void main() {
  group('空状態', () {
    testWidgets('豆・記録・振り返りに、次にやることを示す', (tester) async {
      await pumpApp(tester);
      await tapTab(tester, '豆');
      expect(find.text('まだ豆が登録されていません'), findsOneWidget);
      expect(find.text('最初の豆を登録する'), findsOneWidget);

      await tapTab(tester, '記録');
      expect(find.text('まだ記録がありません'), findsOneWidget);

      await tapTab(tester, '振り返り');
      expect(find.text('直近30日の記録がありません'), findsOneWidget);
      await tester.tap(find.text('淹れにいく'));
      await tester.pumpAndSettle();
      expect(find.text('淹れる').first, findsOneWidget);
      expect(find.text('レシピ'), findsOneWidget);
    });
  });

  group('豆', () {
    testWidgets('登録すると一覧に焙煎からの日数が出る', (tester) async {
      final app = await pumpApp(tester, initialTab: 2);
      await tester.tap(find.text('最初の豆を登録する'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('登録する'));
      await tester.pump();
      expect(find.text('名前を入力してください'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, '名前'), 'ケニア ニエリ');
      await tester.enterText(find.widgetWithText(TextFormField, '産地'), 'ケニア');
      await tester.tap(find.text('浅煎り'));
      await tester.tap(find.text('未設定'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('焙煎から 8 日'), findsOneWidget);

      await tester.tap(find.text('登録する'));
      await tester.pumpAndSettle();
      final bean = app.store.beans.single;
      expect(bean.name, 'ケニア ニエリ');
      expect(bean.roast, RoastLevel.light);
      expect(bean.roastedOn, DateTime(2026, 11, 10));
      expect(find.text('ケニア · 浅煎り'), findsOneWidget);
      expect(findRich('8 日'), findsOneWidget);
      expect(app.kv.values[AppRepository.dataKey], contains('ケニア ニエリ'));
    });

    testWidgets('スワイプで削除し、元に戻せる', (tester) async {
      final app = await pumpApp(tester, data: AppData(beans: sampleBeans), initialTab: 2);
      await tester.drag(find.text('エチオピア グジ'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(app.store.beans.map((b) => b.id), ['b2']);
      expect(find.text('「エチオピア グジ」を削除しました'), findsOneWidget);
      await tester.tap(find.text('元に戻す'));
      await tester.pumpAndSettle();
      expect(app.store.beans.map((b) => b.id), ['b1', 'b2']);
    });

    testWidgets('編集画面から削除すると確認が出る', (tester) async {
      final app = await pumpApp(tester, data: AppData(beans: sampleBeans), initialTab: 2);
      await tester.tap(find.text('ブラジル セラード'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('削除'));
      await tester.pumpAndSettle();
      expect(find.textContaining('これまでの抽出記録は残ります'), findsOneWidget);
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();
      expect(app.store.beans.map((b) => b.id), ['b1']);
    });
  });

  group('記録', () {
    testWidgets('豆で絞り込める', (tester) async {
      await pumpApp(tester, data: sampleData(), initialTab: 1);
      expect(find.byType(ListTile), findsNWidgets(3));
      await tester.tap(find.widgetWithText(ChoiceChip, 'ブラジル セラード'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'すべて'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('詳細に味とメモとレシピが出て、削除は元に戻せる', (tester) async {
      final app = await pumpApp(tester, data: sampleData(), initialTab: 1);
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      expect(find.text('メモr1'), findsOneWidget);
      expect(find.text('240 ml（1:16.0）'), findsOneWidget);
      expect(find.bySemanticsLabel('評価 5'), findsOneWidget);

      await tester.tap(find.byTooltip('削除'));
      await tester.pumpAndSettle();
      expect(app.store.records, hasLength(2));
      await tester.tap(find.text('元に戻す'));
      await tester.pumpAndSettle();
      expect(app.store.records.first.id, 'r1');
    });
  });

  group('振り返り', () {
    testWidgets('直近30日の回数・平均と、豆ランキング', (tester) async {
      final data = sampleData();
      await pumpApp(
        tester,
        initialTab: 3,
        data: data.copyWith(
          records: [
            ...data.records,
            // 31日以上前の記録は数えない
            sampleRecord('old', DateTime(2026, 10, 1), rating: 1),
          ],
        ),
      );
      expect(findRich('3 杯'), findsOneWidget); // 抽出回数
      expect(findRich('4.0 / 5'), findsOneWidget); // 平均評価
      final ranks = tester.widgetList<ListTile>(find.byType(ListTile)).map((t) => (t.title as Text).data);
      expect(ranks, ['エチオピア グジ', 'ブラジル セラード']);
      expect(find.text('4.5'), findsOneWidget);
    });
  });

  group('設定', () {
    testWidgets('テーマを切り替えると保存される', (tester) async {
      final app = await pumpApp(tester);
      await tester.tap(find.byTooltip('設定'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ダーク'));
      await tester.pumpAndSettle();
      expect(app.store.data.theme, AppThemePreference.dark);
      expect(Theme.of(tester.element(find.text('設定').first)).brightness, Brightness.dark);
    });

    testWidgets('全データ削除は確認してから消す', (tester) async {
      final app = await pumpApp(tester, data: sampleData());
      await tester.tap(find.byTooltip('設定'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('すべてのデータを削除'));
      await tester.pumpAndSettle();
      expect(find.text('豆 2 件と記録 3 件を削除します。元に戻せません。'), findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(app.store.records, hasLength(3));

      await tester.tap(find.text('すべてのデータを削除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('すべて削除'));
      await tester.pumpAndSettle();
      expect(app.store.records, isEmpty);
      expect(app.store.beans, isEmpty);
    });
  });

  testWidgets('読み込みに失敗していたら起動時に知らせる', (tester) async {
    await pumpApp(tester, startupNotice: '保存データが壊れていたため、空の状態で起動しました。');
    await tester.pump();
    expect(find.text('保存データが壊れていたため、空の状態で起動しました。'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.textContaining('壊れていた'), findsNothing);
  });

  group('幅360dpでも崩れない', () {
    for (final brightness in Brightness.values) {
      for (final tab in [0, 1, 2, 3]) {
        testWidgets('タブ$tab ${brightness.name}', (tester) async {
          await pumpApp(tester, data: sampleData(), initialTab: tab, width: 360, height: 640, brightness: brightness);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('タイマー画面', (tester) async {
      await pumpApp(tester, data: sampleData(), width: 360, height: 640);
      await scrollTo(tester, find.text('抽出を始める'));
      await tester.tap(find.text('抽出を始める'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('スタート'), findsOneWidget);
    });
  });
}
