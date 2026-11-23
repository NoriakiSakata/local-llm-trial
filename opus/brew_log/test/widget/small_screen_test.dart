import 'dart:convert';

import 'package:brew_log/data/repositories/brew_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

/// 幅 360dp・高さ 640dp の小さな画面で、主要画面がはみ出さないこと。
/// レイアウトのオーバーフローは例外として検出される。
void main() {
  const small = Size(360, 640);

  Map<String, String> seeded() {
    final now = DateTime.now();
    return {
      BrewLogRepository.beansKey: jsonEncode([
        testBean(id: 'a', name: 'とても長い名前の豆 エチオピア イルガチェフェ コチャレ G1').toJson(),
      ]),
      BrewLogRepository.recordsKey: jsonEncode([
        for (var i = 0; i < 5; i++)
          testRecord(
            id: '$i',
            beanId: 'a',
            beanName: 'とても長い名前の豆 エチオピア イルガチェフェ コチャレ G1',
            at: now.subtract(Duration(days: i * 3)),
          ).toJson(),
      ]),
    };
  }

  testWidgets('全タブが 360x640 で崩れない', (tester) async {
    await pumpApp(tester, size: small, stored: seeded());
    expect(tester.takeException(), isNull);
    for (final tab in ['豆', '記録', '振り返り', '抽出']) {
      await openTab(tester, tab);
      expect(tester.takeException(), isNull, reason: tab);
    }
  });

  testWidgets('タイマー画面と記録入力が 360x640 で崩れない', (tester) async {
    final env = await pumpApp(tester, size: small, stored: seeded());

    await tester.tap(find.byKey(const ValueKey('start-brew')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('timer-toggle')));
    env.device.advance(const Duration(minutes: 5));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('抽出完了'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('record-brew')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('文字サイズを大きくしてもタイマー画面が崩れない', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, size: small);

    await tester.tap(find.byKey(const ValueKey('start-brew')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
