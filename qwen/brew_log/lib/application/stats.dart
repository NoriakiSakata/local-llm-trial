import '../data/models.dart';

/// 1日分の集計。
final class DayCount {
  const DayCount({
    required this.day,
    required this.count,
    this.ratingTotal = 0,
  });

  final DateTime day;
  final int count;
  final double ratingTotal;

  double? get averageRating => count == 0 ? null : ratingTotal / count;
}

/// 豆ごとの平均評価。
final class BeanRanking {
  const BeanRanking({
    required this.beanName,
    required this.count,
    required this.averageRating,
    this.beanId,
  });

  final String? beanId;
  final String beanName;
  final int count;
  final double averageRating;
}

/// 「振り返り」画面用の集計。純粋関数で、現在時刻を引数に取って決定論的にする。
final class BrewStats {
  const BrewStats({
    required this.daily,
    required this.windowCount,
    required this.totalCount,
    required this.beanCount,
    required this.ranking,
    this.windowAverage,
    this.totalAverage,
    required this.windowDays,
  });

  static const int defaultWindowDays = 30;

  /// 窓期間分の日別件数（古い順、長さ = windowDays）。
  final List<DayCount> daily;
  final int windowCount;
  final double? windowAverage;
  final int totalCount;
  final double? totalAverage;

  /// 登録豆の数。
  final int beanCount;
  final List<BeanRanking> ranking;
  final int windowDays;

  static BrewStats of({
    required List<Extraction> extractions,
    required List<Bean> beans,
    required DateTime now,
    int windowDays = defaultWindowDays,
  }) {
    final DateTime today = dateOnly(now);
    final DateTime windowStart = today.subtract(Duration(days: windowDays - 1));

    // 日付 -> 窓内の番号 の対応を作って O(n) で積む。
    final Map<String, int> keyToIndex = <String, int>{};
    for (int i = 0; i < windowDays; i++) {
      keyToIndex[encodeDate(windowStart.add(Duration(days: i)))] = i;
    }

    final List<int> counts = List<int>.filled(windowDays, 0);
    final List<double> ratingTotals = List<double>.filled(windowDays, 0);

    double windowRatingTotal = 0;
    int windowCount = 0;
    double allRatingTotal = 0;

    final Map<String, List<Extraction>> byBean = <String, List<Extraction>>{};

    for (final Extraction item in extractions) {
      final DateTime day = dateOnly(item.brewedAt);
      final int? index = keyToIndex[encodeDate(day)];
      if (index != null) {
        counts[index] += 1;
        ratingTotals[index] += item.rating;
        windowCount += 1;
        windowRatingTotal += item.rating;
      }
      allRatingTotal += item.rating;

      final String groupKey = item.beanId ?? 'name:${item.beanName}';
      (byBean[groupKey] ??= <Extraction>[]).add(item);
    }

    final List<BeanRanking> ranking =
        byBean.entries.map((MapEntry<String, List<Extraction>> entry) {
          final List<Extraction> items = entry.value;
          final double avg =
              items.fold<double>(
                0,
                (double sum, Extraction e) => sum + e.rating,
              ) /
              items.length;
          final Extraction newest = items.reduce(
            (Extraction a, Extraction b) =>
                a.brewedAt.isAfter(b.brewedAt) ? a : b,
          );
          return BeanRanking(
            beanId: newest.beanId,
            beanName: newest.beanName,
            count: items.length,
            averageRating: avg,
          );
        }).toList()..sort((BeanRanking a, BeanRanking b) {
          final int byRating = b.averageRating.compareTo(a.averageRating);
          if (byRating != 0) return byRating;
          return b.count.compareTo(a.count);
        });

    final List<DayCount> daily = List<DayCount>.generate(
      windowDays,
      (int i) => DayCount(
        day: windowStart.add(Duration(days: i)),
        count: counts[i],
        ratingTotal: ratingTotals[i],
      ),
      growable: false,
    );

    return BrewStats(
      daily: daily,
      windowCount: windowCount,
      windowAverage: windowCount == 0 ? null : windowRatingTotal / windowCount,
      totalCount: extractions.length,
      totalAverage: extractions.isEmpty
          ? null
          : allRatingTotal / extractions.length,
      beanCount: beans.length,
      ranking: ranking,
      windowDays: windowDays,
    );
  }

  /// グラフの縦軸の上限（見栄えのよい最小の「丸い」値）。
  double get dailyMax {
    int max = 0;
    for (final DayCount day in daily) {
      if (day.count > max) max = day.count;
    }
    if (max <= 2) return 2;
    if (max <= 5) return 5;
    return ((max + 4) ~/ 5) * 5.toDouble();
  }
}
