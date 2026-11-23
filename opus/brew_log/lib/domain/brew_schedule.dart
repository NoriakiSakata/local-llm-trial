import 'package:flutter/foundation.dart';

import '../data/models/recipe.dart';

enum BrewStepKind { bloom, pour, drawdown }

/// 抽出の 1 ステップ。
@immutable
class BrewStep {
  const BrewStep({
    required this.kind,
    required this.pourNumber,
    required this.start,
    required this.duration,
    required this.targetTotalMl,
  });

  final BrewStepKind kind;

  /// 何投目か（蒸らし・落としきりは 0）
  final int pourNumber;

  /// 抽出開始からこのステップが始まるまでの時間
  final Duration start;
  final Duration duration;

  /// このステップ終了時点で注ぎ終えている累計湯量（ml）
  final int targetTotalMl;

  Duration get end => start + duration;

  String get label => switch (kind) {
    BrewStepKind.bloom => '蒸らし',
    BrewStepKind.pour => '$pourNumber投目',
    BrewStepKind.drawdown => '落としきり',
  };

  @override
  bool operator ==(Object other) =>
      other is BrewStep &&
      other.kind == kind &&
      other.pourNumber == pourNumber &&
      other.start == start &&
      other.duration == duration &&
      other.targetTotalMl == targetTotalMl;

  @override
  int get hashCode =>
      Object.hash(kind, pourNumber, start, duration, targetTotalMl);

  @override
  String toString() =>
      'BrewStep($label, start: ${start.inSeconds}s, '
      'dur: ${duration.inSeconds}s, total: ${targetTotalMl}ml)';
}

/// ある経過時間における、スケジュール上の位置。
@immutable
class BrewPosition {
  const BrewPosition({
    required this.stepIndex,
    required this.remainingInStep,
    required this.stepProgress,
    required this.isFinished,
  });

  final int stepIndex;
  final Duration remainingInStep;

  /// 現在ステップの進捗（0.0〜1.0）
  final double stepProgress;
  final bool isFinished;
}

/// レシピから「蒸らし → 1投目 → … → 落としきり」のスケジュールを組み立てる。
///
/// ルール:
/// - 蒸らしの湯量は豆の量の 2 倍（湯量の総量を超えない）。蒸らし 0 秒なら蒸らしは省略。
/// - 残りの湯を注湯回数で等分する。端数は最後の投に寄せ、合計が必ず総湯量に一致する。
/// - 各投は「投間隔」秒。最後に落としきり（[drawdownDuration]）を置く。
class BrewSchedule {
  BrewSchedule._(this.recipe, this.steps);

  factory BrewSchedule.fromRecipe(Recipe recipe) {
    final steps = <BrewStep>[];
    var cursor = Duration.zero;
    var poured = 0;

    if (recipe.bloomSec > 0) {
      final bloomMl = (recipe.doseG * 2).clamp(0, recipe.waterMl);
      final duration = Duration(seconds: recipe.bloomSec);
      steps.add(
        BrewStep(
          kind: BrewStepKind.bloom,
          pourNumber: 0,
          start: cursor,
          duration: duration,
          targetTotalMl: bloomMl,
        ),
      );
      cursor += duration;
      poured = bloomMl;
    }

    final remaining = recipe.waterMl - poured;
    final interval = Duration(seconds: recipe.pourIntervalSec);
    for (var i = 1; i <= recipe.pours; i++) {
      // 整数除算で切り捨て、最後の投で総量ぴったりにそろえる
      final target = i == recipe.pours
          ? recipe.waterMl
          : poured + remaining * i ~/ recipe.pours;
      steps.add(
        BrewStep(
          kind: BrewStepKind.pour,
          pourNumber: i,
          start: cursor,
          duration: interval,
          targetTotalMl: target,
        ),
      );
      cursor += interval;
    }

    steps.add(
      BrewStep(
        kind: BrewStepKind.drawdown,
        pourNumber: 0,
        start: cursor,
        duration: drawdownDuration,
        targetTotalMl: recipe.waterMl,
      ),
    );

    return BrewSchedule._(recipe, List.unmodifiable(steps));
  }

  static const Duration drawdownDuration = Duration(seconds: 30);

  final Recipe recipe;
  final List<BrewStep> steps;

  Duration get total => steps.last.end;

  /// 経過時間からステップ位置を求める。ステップ境界ちょうどは次のステップに属する。
  BrewPosition positionAt(Duration elapsed) {
    if (elapsed < Duration.zero) elapsed = Duration.zero;
    if (elapsed >= total) {
      return BrewPosition(
        stepIndex: steps.length - 1,
        remainingInStep: Duration.zero,
        stepProgress: 1,
        isFinished: true,
      );
    }
    final index = steps.lastIndexWhere((s) => s.start <= elapsed);
    final step = steps[index];
    final inStep = elapsed - step.start;
    return BrewPosition(
      stepIndex: index,
      remainingInStep: step.duration - inStep,
      stepProgress: step.duration == Duration.zero
          ? 1
          : inStep.inMicroseconds / step.duration.inMicroseconds,
      isFinished: false,
    );
  }
}
