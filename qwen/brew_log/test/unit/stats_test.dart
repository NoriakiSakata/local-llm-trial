import 'package:brew_log/application/stats.dart';
import 'package:brew_log/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

Extraction at(
  int daysAgo,
  int rating, {
  String? beanId = 'bean-a',
  String name = 'ゲイシャ',
}) {
  return extractionA(
    id: 'ex-$daysAgo-$rating-$name-$beanId',
    at: DateTime(2026, 10, 30, 9).subtract(Duration(days: daysAgo)),
    rating: rating,
    beanId: beanId,
    beanName: name,
  );
}

void main() {
  final DateTime now = DateTime(2026, 10, 30, 12);

  group('BrewStats.of', () {
    test('直近30日の件数と平均評価', () {
      final stats = BrewStats.of(
        extractions: <Extraction>[at(0, 5), at(1, 4), at(29, 3), at(30, 1)],
        beans: const <Bean>[],
        now: now,
      );
      expect(stats.windowCount, 3);
      expect(stats.windowAverage, closeTo(4.0, 0.001));
      expect(stats.totalCount, 4);
      expect(stats.totalAverage, closeTo(3.25, 0.001));
    });

    test('日別配列は30件で、先頭が窓の初日・末尾が今日', () {
      final stats = BrewStats.of(
        extractions: <Extraction>[at(0, 4), at(12, 5)],
        beans: const <Bean>[],
        now: now,
      );
      expect(stats.daily.length, 30);
      expect(stats.daily.first.day, DateTime(2026, 10, 1));
      expect(stats.daily.last.day, DateTime(2026, 10, 30));
      expect(stats.daily.last.count, 1);
      expect(stats.daily[30 - 13].count, 1);
      expect(stats.daily.where((DayCount d) => d.count == 0).length, 28);
    });

    test('豆別ランキングは平均評価順、同率なら件数順', () {
      final stats = BrewStats.of(
        extractions: <Extraction>[
          at(0, 5, beanId: 'b1', name: 'Ａ'),
          at(1, 3, beanId: 'b2', name: 'Ｂ'),
          at(2, 3, beanId: 'b3', name: 'Ｃ'),
          at(3, 3, beanId: 'b3', name: 'Ｃ'),
        ],
        beans: const <Bean>[],
        now: now,
      );
      expect(
        stats.ranking.map((BeanRanking r) => r.beanName).toList(),
        <String>['Ａ', 'Ｃ', 'Ｂ'],
      );
      expect(stats.ranking[1].averageRating, 3.0);
      expect(stats.ranking[1].count, 2);
    });

    test('豆を削除しても記録のスナップショット名で集まる', () {
      final stats = BrewStats.of(
        extractions: <Extraction>[
          at(0, 4, beanId: null, name: '消えた豆'),
          at(5, 2, beanId: null, name: '消えた豆'),
        ],
        beans: const <Bean>[],
        now: now,
      );
      expect(stats.ranking.length, 1);
      expect(stats.ranking.single.beanName, '消えた豆');
      expect(stats.ranking.single.averageRating, 3.0);
      expect(stats.ranking.single.beanId, isNull);
    });

    test('データ0件では平均が null、グラフ上限は最低2', () {
      final stats = BrewStats.of(
        extractions: const <Extraction>[],
        beans: const <Bean>[],
        now: now,
      );
      expect(stats.windowAverage, isNull);
      expect(stats.totalAverage, isNull);
      expect(stats.dailyMax, 2);
      expect(stats.daily.every((DayCount d) => d.count == 0), isTrue);
    });

    test('dailyMax は見栄えのよい丸い値に切り上げる', () {
      final stats = BrewStats.of(
        extractions: <Extraction>[for (int i = 0; i < 7; i++) at(0, 5)],
        beans: const <Bean>[],
        now: now,
      );
      expect(stats.daily.last.count, 7);
      expect(stats.dailyMax, 10);
    });
  });

  group('Bean.daysSinceRoast', () {
    test('焙煎日からの経過日数', () {
      final bean = beanA; // 2026-10-22 焙煎
      expect(bean.daysSinceRoast(DateTime(2026, 10, 30)), 8);
      expect(bean.daysSinceRoast(DateTime(2026, 10, 22, 23, 59)), 0);
    });

    test('未来日を渡しても負数にはしない', () {
      expect(beanA.daysSinceRoast(DateTime(2026, 10, 1)), 0);
    });
  });
}
