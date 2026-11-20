import 'package:brew_log/data/models.dart';
import 'package:brew_log/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

BrewRecord rec(String id, DateTime at, int rating, {String bean = 'A', String? beanId}) => BrewRecord(
  id: id,
  brewedAt: at,
  beanId: beanId ?? bean,
  beanName: bean,
  recipe: const Recipe(),
  elapsedSeconds: 150,
  rating: rating,
);

void main() {
  final now = DateTime(2026, 11, 18, 21, 30);

  test('記録がなければ0件・平均なし・日別は30日分の0', () {
    final s = BrewStats.compute(const [], now);
    expect(s.count, 0);
    expect(s.averageRating, isNull);
    expect(s.daily, hasLength(30));
    expect(s.daily.every((d) => d.count == 0), isTrue);
    expect(s.daily.first.day, DateTime(2026, 10, 20));
    expect(s.daily.last.day, DateTime(2026, 11, 18));
  });

  test('今日を含む30日だけを数える（31日前は含めない）', () {
    final s = BrewStats.compute([
      rec('1', DateTime(2026, 11, 18, 7), 5),
      rec('2', DateTime(2026, 10, 20, 0, 0), 3), // 30日目の0時ちょうど → 含む
      rec('3', DateTime(2026, 10, 19, 23, 59), 1), // 31日前 → 含まない
    ], now);
    expect(s.count, 2);
    expect(s.averageRating, 4.0);
  });

  test('同じ日の記録は日別でまとめて数える', () {
    final s = BrewStats.compute([rec('1', DateTime(2026, 11, 17, 7), 4), rec('2', DateTime(2026, 11, 17, 15), 4)], now);
    expect(s.daily[28].count, 2);
    expect(s.daily.last.count, 0);
  });

  test('豆ごとの平均評価が高い順、同点なら杯数の多い順', () {
    final s = BrewStats.compute([
      rec('1', DateTime(2026, 11, 10), 3, bean: 'ブラジル'),
      rec('2', DateTime(2026, 11, 11), 5, bean: 'ブラジル'),
      rec('3', DateTime(2026, 11, 12), 4, bean: 'エチオピア'),
      rec('4', DateTime(2026, 11, 13), 5, bean: 'ケニア'),
    ], now);
    expect(s.ranking.map((r) => r.beanName), ['ケニア', 'ブラジル', 'エチオピア']);
    expect(s.ranking[1].count, 2);
    expect(s.ranking[1].averageRating, 4.0);
  });

  test('平均が同点なら杯数の多い方が上', () {
    final s = BrewStats.compute([
      rec('1', DateTime(2026, 11, 10), 4, bean: 'X'),
      rec('2', DateTime(2026, 11, 11), 4, bean: 'Y'),
      rec('3', DateTime(2026, 11, 12), 4, bean: 'Y'),
    ], now);
    expect(s.ranking.first.beanName, 'Y');
  });

  test('豆が削除されていても（beanId なし）名前で集計する', () {
    final s = BrewStats.compute([
      BrewRecord(
        id: '1',
        brewedAt: DateTime(2026, 11, 10),
        beanId: null,
        beanName: '豆の指定なし',
        recipe: const Recipe(),
        elapsedSeconds: 1,
        rating: 2,
      ),
    ], now);
    expect(s.ranking.single.beanName, '豆の指定なし');
  });
}
