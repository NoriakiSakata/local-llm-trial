import 'dart:math' as math;

/// 端末内で一意な ID を作る。
///
/// 外部パッケージに依存したくなかったので、マイクロ秒時刻と乱数の組み合わせにした。
/// 記録の件数規模（せいぜい数千）では衝突を実質無視できる。
String newId({math.Random? random}) {
  final math.Random r = random ?? math.Random();
  final String stamp = DateTime.now().microsecondsSinceEpoch
      .toRadixString(36)
      .toUpperCase();
  final String salt = r.nextInt(1 << 30).toRadixString(36).toUpperCase();
  return '$stamp-$salt';
}
