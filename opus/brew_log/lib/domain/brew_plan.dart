import '../data/models.dart';

enum BrewStepKind { bloom, pour, drain }

class BrewStep {
  const BrewStep({
    required this.kind,
    required this.label,
    required this.startSecond,
    required this.endSecond,
    required this.targetTotalMl,
  });

  final BrewStepKind kind;

  /// 「蒸らし」「1投目」「落ちきり」など
  final String label;
  final int startSecond;
  final int endSecond;

  /// このステップが終わるまでに注いでおく累計湯量
  final int targetTotalMl;

  int get durationSeconds => endSecond - startSecond;
}

/// タイマーのある時点の状態
class BrewProgress {
  const BrewProgress({
    required this.stepIndex,
    required this.step,
    required this.remainingInStep,
    required this.finished,
  });

  final int stepIndex;
  final BrewStep step;
  final Duration remainingInStep;
  final bool finished;
}

/// レシピからステップ列を組み立てる。
///
/// - 蒸らしの湯量は豆の重さの2倍（湯量を超えない）
/// - 残りの湯を注湯回数で等分し、端数は最後の1投に寄せる
/// - 1投あたり [pourSeconds] 秒、最後に [drainSeconds] 秒の落ちきり待ち
class BrewPlan {
  BrewPlan._(this.recipe, this.steps);

  static const pourSeconds = 30;
  static const drainSeconds = 45;

  factory BrewPlan.fromRecipe(Recipe recipe) {
    if (recipe.beanGrams <= 0 || recipe.waterMl <= 0 || recipe.pours < 1 || recipe.bloomSeconds < 0) {
      throw ArgumentError.value(recipe, 'recipe', 'レシピの値が不正です');
    }
    final steps = <BrewStep>[];
    final bloomMl = (recipe.beanGrams * 2).clamp(0, recipe.waterMl);
    var t = 0;
    if (recipe.bloomSeconds > 0) {
      steps.add(
        BrewStep(
          kind: BrewStepKind.bloom,
          label: '蒸らし',
          startSecond: 0,
          endSecond: recipe.bloomSeconds,
          targetTotalMl: bloomMl,
        ),
      );
      t = recipe.bloomSeconds;
    }
    final startMl = recipe.bloomSeconds > 0 ? bloomMl : 0;
    final perPour = (recipe.waterMl - startMl) ~/ recipe.pours;
    for (var i = 1; i <= recipe.pours; i++) {
      final total = i == recipe.pours ? recipe.waterMl : startMl + perPour * i;
      steps.add(
        BrewStep(
          kind: BrewStepKind.pour,
          label: '$i投目',
          startSecond: t,
          endSecond: t + pourSeconds,
          targetTotalMl: total,
        ),
      );
      t += pourSeconds;
    }
    steps.add(
      BrewStep(
        kind: BrewStepKind.drain,
        label: '落ちきり',
        startSecond: t,
        endSecond: t + drainSeconds,
        targetTotalMl: recipe.waterMl,
      ),
    );
    return BrewPlan._(recipe, List.unmodifiable(steps));
  }

  final Recipe recipe;
  final List<BrewStep> steps;

  Duration get total => Duration(seconds: steps.last.endSecond);

  BrewProgress progressAt(Duration elapsed) {
    if (elapsed >= total) {
      return BrewProgress(
        stepIndex: steps.length - 1,
        step: steps.last,
        remainingInStep: Duration.zero,
        finished: true,
      );
    }
    final ms = elapsed.isNegative ? 0 : elapsed.inMilliseconds;
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      if (ms < s.endSecond * 1000) {
        return BrewProgress(
          stepIndex: i,
          step: s,
          remainingInStep: Duration(milliseconds: s.endSecond * 1000 - ms),
          finished: false,
        );
      }
    }
    throw StateError('unreachable');
  }
}
