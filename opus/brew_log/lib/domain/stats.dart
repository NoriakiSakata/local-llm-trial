import '../data/models.dart';

class DailyCount {
  const DailyCount(this.day, this.count);
  final DateTime day;
  final int count;
}

class BeanScore {
  const BeanScore({required this.beanName, required this.averageRating, required this.count});
  final String beanName;
  final double averageRating;
  final int count;
}

/// 振り返り画面に出す集計。対象はすべて「直近30日（今日を含む）」。
class BrewStats {
  const BrewStats({required this.daily, required this.count, required this.averageRating, required this.ranking});

  static const windowDays = 30;

  /// 古い日 → 今日 の順に30件
  final List<DailyCount> daily;
  final int count;

  /// 記録がなければ null
  final double? averageRating;

  /// 平均評価の高い順。同点なら回数の多い順
  final List<BeanScore> ranking;

  factory BrewStats.compute(List<BrewRecord> records, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(today.year, today.month, today.day - (windowDays - 1));
    final end = DateTime(today.year, today.month, today.day + 1);
    final inWindow = [
      for (final r in records)
        if (!r.brewedAt.isBefore(first) && r.brewedAt.isBefore(end)) r,
    ];

    final counts = <DateTime, int>{};
    for (final r in inWindow) {
      final d = DateTime(r.brewedAt.year, r.brewedAt.month, r.brewedAt.day);
      counts[d] = (counts[d] ?? 0) + 1;
    }
    final daily = [
      for (var i = 0; i < windowDays; i++)
        () {
          final d = DateTime(first.year, first.month, first.day + i);
          return DailyCount(d, counts[d] ?? 0);
        }(),
    ];

    final byBean = <String, List<BrewRecord>>{};
    for (final r in inWindow) {
      (byBean[r.beanId ?? 'name:${r.beanName}'] ??= []).add(r);
    }
    final ranking =
        [
          for (final list in byBean.values)
            BeanScore(
              // 同じ豆の名前が途中で変わった場合は、新しい記録の名前を使う
              beanName: (list.toList()..sort((a, b) => b.brewedAt.compareTo(a.brewedAt))).first.beanName,
              averageRating: list.map((r) => r.rating).reduce((a, b) => a + b) / list.length,
              count: list.length,
            ),
        ]..sort((a, b) {
          final byRating = b.averageRating.compareTo(a.averageRating);
          return byRating != 0 ? byRating : b.count.compareTo(a.count);
        });

    return BrewStats(
      daily: daily,
      count: inWindow.length,
      averageRating: inWindow.isEmpty ? null : inWindow.map((r) => r.rating).reduce((a, b) => a + b) / inWindow.length,
      ranking: ranking,
    );
  }
}
