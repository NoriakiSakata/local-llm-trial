import 'package:brew_log/application/brew_plan.dart';
import 'package:brew_log/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

Recipe recipe({
  double grams = 15,
  int water = 240,
  int temp = 90,
  int bloom = 40,
  int pours = 3,
}) {
  return Recipe(
    id: 'r',
    name: 'テスト',
    beanAmountG: grams,
    waterMl: water,
    tempC: temp,
    bloomSeconds: bloom,
    pours: pours,
  );
}

void main() {
  group('BrewPlan.from', () {
    test('蒸らし湯量は豆量の2倍、以降は等分', () {
      final plan = BrewPlan.from(recipe());
      expect(plan.steps.length, 4); // 蒸らし + 3投
      expect(plan.steps[0].label, '蒸らし');
      expect(plan.steps[0].pourMl, 30);
      expect(plan.steps[1].pourMl, 70);
      expect(plan.steps.map((BrewStep s) => s.targetCumMl).toList(), <int>[
        30,
        100,
        170,
        240,
      ]);
    });

    test('最後の注湯に端数が載り、総湯量と必ず一致する', () {
      final plan = BrewPlan.from(recipe(water: 250, grams: 15));
      expect(plan.steps.last.targetCumMl, 250);
      expect(plan.steps[1].pourMl, 73);
      expect(plan.steps[3].pourMl, 74);
    });

    test('注湯の長さは湯量 ÷ 6ml/秒（最低8秒）', () {
      final plan = BrewPlan.from(recipe());
      expect(plan.steps[0].durationMs, 40 * 1000);
      expect(plan.steps[1].durationMs, (70 / 6).ceil() * 1000);
      expect(plan.totalMs, (40 + 3 * 12) * 1000);
    });

    test('極端に少ない湯量でもステップが破綻しない', () {
      final plan = BrewPlan.from(recipe(water: 10, grams: 15, pours: 5));
      expect(plan.steps.length, 6);
      expect(plan.steps.last.targetCumMl, plan.waterMl);
      for (final BrewStep step in plan.steps) {
        expect(step.pourMl, greaterThan(0));
      }
    });

    test('注湯回数が0以下でも1回として扱う', () {
      final plan = BrewPlan.from(recipe(pours: 0));
      expect(plan.steps.length, 2);
      expect(plan.steps.last.targetCumMl, plan.waterMl);
    });

    test('経過時間からステップ位置と残り時間を引ける', () {
      final plan = BrewPlan.from(recipe());
      expect(plan.indexAt(0), 0);
      expect(plan.indexAt(39999), 0);
      expect(plan.indexAt(40000), 1);
      expect(plan.indexAt(plan.totalMs + 1), plan.steps.length - 1);
      expect(plan.isFinished(plan.totalMs), isTrue);
      expect(plan.isFinished(plan.totalMs - 1), isFalse);
      expect(plan.remainingMs(0, 15000), 25000);
      expect(plan.stepAt(45000).label, '1投目');
    });

    test('formatClock は m:ss に揃う', () {
      expect(formatClock(const Duration(seconds: 9)), '00:09');
      expect(formatClock(const Duration(seconds: 75)), '01:15');
      expect(formatClock(const Duration(seconds: -5)), '00:00');
    });
  });
}
