import 'dart:math';

final _random = Random();

/// 端末内で一意であれば十分な ID（時刻 + 乱数）。
String newId() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final rand = _random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
  return '$time-$rand';
}
