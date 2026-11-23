import 'package:brew_log/data/models/recipe.dart';
import 'package:brew_log/domain/brew_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrewSchedule.fromRecipe', () {
    test('標準レシピは 蒸らし → 3投 → 落としきり の5ステップ', () {
      final s = BrewSchedule.fromRecipe(Recipe.standard);

      expect(s.steps.map((e) => e.label).toList(), [
        '蒸らし',
        '1投目',
        '2投目',
        '3投目',
        '落としきり',
      ]);
      // 蒸らしは豆の量の2倍 = 30ml。残り 210ml を3等分。
      expect(s.steps.map((e) => e.targetTotalMl).toList(), [
        30,
        100,
        170,
        240,
        240,
      ]);
      expect(s.steps.map((e) => e.start.inSeconds).toList(), [
        0,
        30,
        60,
        90,
        120,
      ]);
      expect(s.total, const Duration(seconds: 150));
    });

    test('割り切れない湯量でも最後の投で総湯量にぴったり一致する', () {
      final s = BrewSchedule.fromRecipe(
        Recipe.standard.copyWith(doseG: 13, waterMl: 200, pours: 3),
      );
      // 蒸らし 26ml、残り 174ml → 58ml ずつ
      expect(s.steps.map((e) => e.targetTotalMl).toList(), [
        26,
        84,
        142,
        200,
        200,
      ]);

      final odd = BrewSchedule.fromRecipe(
        Recipe.standard.copyWith(doseG: 10, waterMl: 100, pours: 3),
      );
      // 残り 80ml を3投: 26, 53, 80（累計 46, 73, 100）
      expect(odd.steps.map((e) => e.targetTotalMl).toList(), [
        20,
        46,
        73,
        100,
        100,
      ]);
    });

    test('累計湯量は単調増加する', () {
      for (final pours in [1, 2, 5, 8]) {
        final s = BrewSchedule.fromRecipe(
          Recipe.standard.copyWith(pours: pours, waterMl: 333),
        );
        for (var i = 1; i < s.steps.length; i++) {
          expect(
            s.steps[i].targetTotalMl,
            greaterThanOrEqualTo(s.steps[i - 1].targetTotalMl),
          );
        }
        expect(s.steps.last.targetTotalMl, 333);
      }
    });

    test('蒸らし 0 秒なら蒸らしステップを省略する', () {
      final s = BrewSchedule.fromRecipe(
        Recipe.standard.copyWith(bloomSec: 0, pours: 2),
      );
      expect(s.steps.first.label, '1投目');
      expect(s.steps.map((e) => e.targetTotalMl).toList(), [120, 240, 240]);
    });

    test('蒸らし湯量は総湯量を超えない', () {
      final s = BrewSchedule.fromRecipe(
        Recipe.standard.copyWith(doseG: 40, waterMl: 60),
      );
      expect(s.steps.first.targetTotalMl, 60);
      expect(s.steps.last.targetTotalMl, 60);
    });
  });

  group('BrewSchedule.positionAt', () {
    final s = BrewSchedule.fromRecipe(Recipe.standard);

    test('開始直後は蒸らしで、残りは蒸らし時間', () {
      final p = s.positionAt(Duration.zero);
      expect(p.stepIndex, 0);
      expect(p.remainingInStep, const Duration(seconds: 30));
      expect(p.stepProgress, 0);
      expect(p.isFinished, isFalse);
    });

    test('ステップの途中', () {
      final p = s.positionAt(const Duration(seconds: 45));
      expect(p.stepIndex, 1);
      expect(p.remainingInStep, const Duration(seconds: 15));
      expect(p.stepProgress, closeTo(0.5, 1e-9));
    });

    test('境界ちょうどは次のステップに属する', () {
      expect(s.positionAt(const Duration(seconds: 30)).stepIndex, 1);
      expect(s.positionAt(const Duration(seconds: 120)).stepIndex, 4);
    });

    test('合計時間以降は完了扱い', () {
      final p = s.positionAt(const Duration(seconds: 150));
      expect(p.isFinished, isTrue);
      expect(p.stepIndex, s.steps.length - 1);
      expect(p.remainingInStep, Duration.zero);
      expect(s.positionAt(const Duration(hours: 1)).isFinished, isTrue);
    });

    test('負の経過時間は 0 として扱う', () {
      expect(s.positionAt(const Duration(seconds: -5)).stepIndex, 0);
    });
  });
}
