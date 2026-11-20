import 'dart:math' as math;

import '../data/models.dart';

/// 抽出ステップの種類。
enum BrewStepKind { bloom, pour }

/// レシピから導出した1工程。
final class BrewStep {
  const BrewStep({
    required this.index,
    required this.kind,
    required this.label,
    required this.startMs,
    required this.durationMs,
    required this.pourMl,
    required this.targetCumMl,
  });

  final int index;
  final BrewStepKind kind;

  /// 「蒸らし」「1投目」などの表示名。
  final String label;

  /// 抽出開始からのステップ開始位置。
  final int startMs;
  final int durationMs;

  /// この工程で注ぐ湯量。
  final int pourMl;

  /// この工程が終わった時点の目標累計湯量。
  final int targetCumMl;

  int get endMs => startMs + durationMs;

  bool get isBloom => kind == BrewStepKind.bloom;
}

/// レシピから作る抽出設計図。
///
/// 計算のルール（README にも記載）:
/// - 蒸らし湯量 = 豆量 × 2 ml（ただし総湯量から各投与に1mlずつ残す）
/// - 注湯1回あたりの湯量 = (総湯量 − 蒸らし) ÷ 注湯回数、端数は最終投与に寄せる
/// - 蒸らしの長さ = レシピの蒸らし時間
/// - 各投与の長さ = 湯量 ÷ 注湯レート(6 ml/秒)、最低8秒
final class BrewPlan {
  const BrewPlan({
    required this.steps,
    required this.beanAmountG,
    required this.waterMl,
    required this.tempC,
  });

  static const double bloomWaterPerGram = 2.0;
  static const double pourRateMlPerSecond = 6.0;
  static const int minPourSeconds = 8;

  final List<BrewStep> steps;
  final double beanAmountG;
  final int waterMl;
  final int tempC;

  int get totalMs => steps.isEmpty ? 0 : steps.last.endMs;

  /// レシピから設計図を作る。値が荒れていてもステップは最低1つ返す。
  factory BrewPlan.from(Recipe recipe) {
    final int pours = recipe.pours.clamp(1, 9);
    final int total = math.max(pours + 1, recipe.waterMl);
    final int bloomBudget = (recipe.beanAmountG * bloomWaterPerGram).round();
    // 各投与に最低1mlは残す。総湯量に対して蒸らしが大きすぎても破綻しない。
    final int bloomMl = bloomBudget.clamp(1, total - pours);
    final int remainder = total - bloomMl;
    final int base = remainder ~/ pours;
    final List<int> amounts = List<int>.generate(
      pours,
      (int i) => i == pours - 1 ? remainder - base * (pours - 1) : base,
      growable: false,
    );

    int cumulative = 0;
    int cursorMs = 0;
    final List<BrewStep> steps = <BrewStep>[];

    cumulative += bloomMl;
    final int bloomSeconds = recipe.bloomSeconds.clamp(5, 600);
    steps.add(
      BrewStep(
        index: 0,
        kind: BrewStepKind.bloom,
        label: '蒸らし',
        startMs: 0,
        durationMs: bloomSeconds * 1000,
        pourMl: bloomMl,
        targetCumMl: cumulative,
      ),
    );
    cursorMs += bloomSeconds * 1000;

    for (int i = 0; i < pours; i++) {
      final int ml = amounts[i];
      final int seconds = math.max(
        minPourSeconds,
        (ml / pourRateMlPerSecond).ceil(),
      );
      cumulative += ml;
      steps.add(
        BrewStep(
          index: steps.length,
          kind: BrewStepKind.pour,
          label: '${i + 1}投目',
          startMs: cursorMs,
          durationMs: seconds * 1000,
          pourMl: ml,
          targetCumMl: cumulative,
        ),
      );
      cursorMs += seconds * 1000;
    }

    return BrewPlan(
      steps: steps,
      beanAmountG: recipe.beanAmountG,
      waterMl: total,
      tempC: recipe.tempC,
    );
  }

  /// 経過時間時点でのステップ番号。終了後は最後のステップを返す。
  int indexAt(int elapsedMs) {
    for (int i = steps.length - 1; i >= 0; i--) {
      if (elapsedMs >= steps[i].startMs) return i;
    }
    return 0;
  }

  BrewStep stepAt(int elapsedMs) => steps[indexAt(elapsedMs)];

  bool isFinished(int elapsedMs) => elapsedMs >= totalMs;

  /// そのステップの残り時間。完了済みなら 0。
  int remainingMs(int index, int elapsedMs) {
    final BrewStep step = steps[index];
    return math.max(0, step.endMs - elapsedMs);
  }

  /// 経過時間から逆算した、全体の目標累計湯量。
  int targetCumMlAt(int elapsedMs) => stepAt(elapsedMs).targetCumMl;

  Duration get totalDuration => Duration(milliseconds: totalMs);
}

/// 秒数を `m:ss` に整形式化する（タイマー表示用）。
String formatClock(Duration duration) {
  final int total = duration.isNegative ? 0 : duration.inSeconds;
  final String m = (total ~/ 60).toString().padLeft(2, '0');
  final String s = (total % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
