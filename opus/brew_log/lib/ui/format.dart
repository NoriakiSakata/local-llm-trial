/// 表示用の整形。intl を入れずに済む範囲で自前で書く。
library;

const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

String two(int n) => n.toString().padLeft(2, '0');

/// 2:05 のような分:秒
String formatClock(Duration d) {
  final s = (d.inMilliseconds / 1000).ceil();
  return '${s ~/ 60}:${two(s % 60)}';
}

/// 11/18（火）
String formatDate(DateTime d) => '${d.month}/${d.day}（${_weekdays[d.weekday - 1]}）';

/// 2026/11/18
String formatFullDate(DateTime d) => '${d.year}/${two(d.month)}/${two(d.day)}';

/// 11/18（火） 7:42
String formatDateTime(DateTime d) => '${formatDate(d)} ${d.hour}:${two(d.minute)}';

String formatRating(double? v) => v == null ? '—' : v.toStringAsFixed(1);
