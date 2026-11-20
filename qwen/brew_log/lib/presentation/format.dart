/// 表示用の日付・時刻フォーマット（intl に依存しない）。
library;

const String _weekdays = '日月火水木金土';

/// `2026年10月30日`
String formatDateJa(DateTime value) =>
    '${value.year}年${value.month}月${value.day}日';

/// `10/30`
String formatMonthDay(DateTime value) => '${value.month}/${value.day}';

/// `9:15`（分だけ2桁に揃える）
String formatTimeJa(DateTime value) =>
    '${value.hour}:${value.minute.toString().padLeft(2, '0')}';

/// `10月30日(金) 9:15`
String formatDateTimeJa(DateTime value) =>
    '${value.month}月${value.day}日(${weekdayJa(value)}) ${formatTimeJa(value)}';

/// `2026年10月30日（金）9:15`
String formatFullDateTimeJa(DateTime value) =>
    '${formatDateJa(value)}（${_weekdays[value.weekday - 1]}）${formatTimeJa(value)}';

/// 曜日の1文字。
String weekdayJa(DateTime value) => _weekdays[value.weekday - 1];

/// 秒数を `1分20秒` のように自然な日本語時間へ整形する。
String formatDurationJa(Duration duration) {
  final int total = duration.inSeconds;
  if (total < 60) return '$total秒';
  final int m = total ~/ 60;
  final int s = total % 60;
  return s == 0 ? '$m分' : '$m分$s秒';
}
