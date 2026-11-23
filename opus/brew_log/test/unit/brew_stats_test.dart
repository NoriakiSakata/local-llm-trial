import 'package:brew_log/domain/brew_stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final now = DateTime(2026, 11, 23, 21, 0);

  group('BrewStats.recent', () {
    test('記録 0 件なら回数 0・平均は null', () {
      final s = BrewStats.recent([], now);
      expect(s.count, 0);
      expect(s.averageRating, isNull);
      expect(s.dailyCounts, hasLength(30));
      expect(s.dailyCounts.every((c) => c == 0), isTrue);
      expect(s.firstDay, DateTime(2026, 10, 25));
    });

    test('今日を含む直近30暦日だけを数える', () {
      final records = [
        testRecord(id: 'today', at: DateTime(2026, 11, 23, 7), rating: 5),
        testRecord(id: 'today2', at: DateTime(2026, 11, 23, 15), rating: 3),
        // 29日前（範囲の先頭日・深夜0時）
        testRecord(id: 'edge', at: DateTime(2026, 10, 25, 0, 0), rating: 4),
        // 30日前（範囲外）
        testRecord(id: 'old', at: DateTime(2026, 10, 24, 23, 59), rating: 1),
        // 未来（範囲外）
        testRecord(id: 'future', at: DateTime(2026, 11, 24, 8), rating: 1),
      ];
      final s = BrewStats.recent(records, now);

      expect(s.count, 3);
      expect(s.averageRating, closeTo(4.0, 1e-9));
      expect(s.dailyCounts.first, 1);
      expect(s.dailyCounts.last, 2);
      expect(s.dailyCounts.fold<int>(0, (a, b) => a + b), 3);
    });

    test('月をまたいでも日ごとの位置がずれない', () {
      final s = BrewStats.recent([
        testRecord(id: 'a', at: DateTime(2026, 10, 31, 12)),
        testRecord(id: 'b', at: DateTime(2026, 11, 1, 12)),
      ], now);
      // 10/25 が index 0 → 10/31 は 6、11/1 は 7
      expect(s.dailyCounts[6], 1);
      expect(s.dailyCounts[7], 1);
    });
  });

  group('BrewStats.beanRanking', () {
    test('平均評価の高い順、同点は記録数の多い順', () {
      final beans = [
        testBean(id: 'a', name: 'A'),
        testBean(id: 'b', name: 'B'),
        testBean(id: 'c', name: 'C'),
      ];
      final records = [
        testRecord(id: '1', beanId: 'a', at: now, rating: 3),
        testRecord(id: '2', beanId: 'a', at: now, rating: 5), // A: 4.0 (2)
        testRecord(id: '3', beanId: 'b', at: now, rating: 5), // B: 5.0 (1)
        testRecord(id: '4', beanId: 'c', at: now, rating: 4), // C: 4.0 (1)
      ];
      final r = BrewStats.beanRanking(records, beans);

      expect(r.map((e) => e.beanName).toList(), ['B', 'A', 'C']);
      expect(r[1].averageRating, 4.0);
      expect(r[1].count, 2);
    });

    test('削除済みの豆は記録時の名前で残し、豆の指定なしは除外する', () {
      final records = [
        testRecord(id: '1', beanId: 'gone', beanName: '昔の豆', at: now),
        testRecord(id: '2', beanId: null, beanName: '豆の指定なし', at: now),
      ];
      final r = BrewStats.beanRanking(records, []);
      expect(r, hasLength(1));
      expect(r.single.beanName, '昔の豆');
    });

    test('豆名を変更した場合は現在の名前で表示する', () {
      final r = BrewStats.beanRanking(
        [testRecord(id: '1', beanId: 'a', beanName: '旧名', at: now)],
        [testBean(id: 'a', name: '新名')],
      );
      expect(r.single.beanName, '新名');
    });
  });
}
