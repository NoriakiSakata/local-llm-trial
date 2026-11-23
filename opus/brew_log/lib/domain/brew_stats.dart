import 'package:flutter/foundation.dart';

import '../data/models/bean.dart';
import '../data/models/brew_record.dart';

/// 直近 N 日のまとめ。
@immutable
class PeriodSummary {
  const PeriodSummary({
    required this.days,
    required this.count,
    required this.averageRating,
    required this.dailyCounts,
    required this.firstDay,
  });

  final int days;
  final int count;

  /// 記録が 0 件なら null
  final double? averageRating;

  /// 古い日 → 今日 の順で、日ごとの抽出回数（長さは [days]）
  final List<int> dailyCounts;

  /// [dailyCounts] の先頭の日
  final DateTime firstDay;
}

/// 豆ごとの平均評価。
@immutable
class BeanRanking {
  const BeanRanking({
    required this.beanId,
    required this.beanName,
    required this.averageRating,
    required this.count,
  });

  final String? beanId;
  final String beanName;
  final double averageRating;
  final int count;
}

abstract final class BrewStats {
  /// 今日を含む直近 [days] 日（暦日）の集計。
  static PeriodSummary recent(
    List<BrewRecord> records,
    DateTime now, {
    int days = 30,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(today.year, today.month, today.day - (days - 1));
    final counts = List<int>.filled(days, 0);
    var ratingSum = 0;
    var count = 0;

    for (final r in records) {
      final d = DateTime(r.brewedAt.year, r.brewedAt.month, r.brewedAt.day);
      if (d.isBefore(firstDay) || d.isAfter(today)) continue;
      final index = Bean.daysBetween(firstDay, d);
      counts[index]++;
      ratingSum += r.rating;
      count++;
    }

    return PeriodSummary(
      days: days,
      count: count,
      averageRating: count == 0 ? null : ratingSum / count,
      dailyCounts: List.unmodifiable(counts),
      firstDay: firstDay,
    );
  }

  /// 豆ごとの平均評価ランキング（全期間）。
  ///
  /// 並び順: 平均評価の高い順 → 同点なら記録数の多い順 → 名前順。
  /// 豆が削除済みでも、記録時の豆名で集計に残す。豆を指定しない抽出は除外する。
  static List<BeanRanking> beanRanking(
    List<BrewRecord> records,
    List<Bean> beans,
  ) {
    final namesById = {for (final b in beans) b.id: b.name};
    final sums = <String, int>{};
    final counts = <String, int>{};
    final names = <String, String>{};

    for (final r in records) {
      final id = r.beanId;
      if (id == null) continue;
      sums[id] = (sums[id] ?? 0) + r.rating;
      counts[id] = (counts[id] ?? 0) + 1;
      names[id] = namesById[id] ?? r.beanName;
    }

    final result = [
      for (final id in sums.keys)
        BeanRanking(
          beanId: id,
          beanName: names[id]!,
          averageRating: sums[id]! / counts[id]!,
          count: counts[id]!,
        ),
    ];
    result.sort((a, b) {
      final byAvg = b.averageRating.compareTo(a.averageRating);
      if (byAvg != 0) return byAvg;
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return a.beanName.compareTo(b.beanName);
    });
    return result;
  }
}
