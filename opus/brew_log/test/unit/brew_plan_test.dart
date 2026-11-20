import 'package:brew_log/data/models.dart';
import 'package:brew_log/domain/brew_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrewPlan.fromRecipe', () {
    test('蒸らし→注湯×回数→落ちきり の順にステップを作る', () {
      final plan = BrewPlan.fromRecipe(const Recipe(beanGrams: 15, waterMl: 240, bloomSeconds: 30, pours: 3));
      expect(plan.steps.map((s) => s.label), ['蒸らし', '1投目', '2投目', '3投目', '落ちきり']);
      expect(plan.steps.map((s) => s.startSecond), [0, 30, 60, 90, 120]);
      expect(plan.total, const Duration(seconds: 165));
    });

    test('蒸らしは豆の2倍、残りを等分して累計湯量を出す', () {
      final plan = BrewPlan.fromRecipe(const Recipe(beanGrams: 15, waterMl: 240, pours: 3));
      // 蒸らし 30ml、残り 210ml を 70ml ずつ
      expect(plan.steps.map((s) => s.targetTotalMl), [30, 100, 170, 240, 240]);
    });

    test('割り切れない端数は最後の1投に寄せ、最後は必ず湯量ちょうどになる', () {
      final plan = BrewPlan.fromRecipe(const Recipe(beanGrams: 16, waterMl: 250, pours: 3));
      // 蒸らし 32ml、残り 218 → 72, 72, 74
      expect(plan.steps.map((s) => s.targetTotalMl), [32, 104, 176, 250, 250]);
    });

    test('蒸らし0秒なら蒸らしステップを作らず、最初から湯量を等分する', () {
      final plan = BrewPlan.fromRecipe(const Recipe(beanGrams: 15, waterMl: 200, bloomSeconds: 0, pours: 2));
      expect(plan.steps.first.kind, BrewStepKind.pour);
      expect(plan.steps.map((s) => s.targetTotalMl), [100, 200, 200]);
    });

    test('蒸らしの湯量は総湯量を超えない', () {
      final plan = BrewPlan.fromRecipe(const Recipe(beanGrams: 50, waterMl: 60, pours: 1));
      expect(plan.steps.first.targetTotalMl, 60);
    });

    test('不正なレシピは ArgumentError', () {
      expect(() => BrewPlan.fromRecipe(const Recipe(pours: 0)), throwsArgumentError);
      expect(() => BrewPlan.fromRecipe(const Recipe(beanGrams: 0)), throwsArgumentError);
    });
  });

  group('BrewPlan.progressAt', () {
    final plan = BrewPlan.fromRecipe(const Recipe(bloomSeconds: 30, pours: 3));

    test('開始直後は蒸らしで残り30秒', () {
      final p = plan.progressAt(Duration.zero);
      expect(p.step.label, '蒸らし');
      expect(p.remainingInStep, const Duration(seconds: 30));
      expect(p.finished, isFalse);
    });

    test('境界ちょうどで次のステップに切り替わる', () {
      expect(plan.progressAt(const Duration(milliseconds: 29999)).stepIndex, 0);
      expect(plan.progressAt(const Duration(seconds: 30)).stepIndex, 1);
    });

    test('ステップ途中の残り時間', () {
      final p = plan.progressAt(const Duration(seconds: 75, milliseconds: 500));
      expect(p.step.label, '2投目');
      expect(p.remainingInStep, const Duration(seconds: 14, milliseconds: 500));
    });

    test('合計時間に達したら完了', () {
      final p = plan.progressAt(plan.total);
      expect(p.finished, isTrue);
      expect(p.remainingInStep, Duration.zero);
      expect(p.step.kind, BrewStepKind.drain);
    });

    test('負の経過時間は0として扱う', () {
      expect(plan.progressAt(const Duration(seconds: -5)).remainingInStep, const Duration(seconds: 30));
    });
  });
}
