/// 表示用の日付・時間フォーマット（intl パッケージを使わない最小実装）。
abstract final class Fmt {
  static const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  /// 2026/11/23
  static String date(DateTime d) => '${d.year}/${d.month}/${d.day}';

  /// 11/23（月）
  static String monthDayWeek(DateTime d) =>
      '${d.month}/${d.day}（${_weekdays[d.weekday - 1]}）';

  /// 11/23（月） 7:05
  static String dateTime(DateTime d) =>
      '${monthDayWeek(d)} ${d.hour}:${_two(d.minute)}';

  /// 2026年11月23日 7:05
  static String fullDateTime(DateTime d) =>
      '${d.year}年${d.month}月${d.day}日 ${d.hour}:${_two(d.minute)}';

  /// 3:05（分:秒）。残り時間表示用に秒は切り上げる。
  static String mmss(Duration d, {bool ceil = false}) {
    var seconds = d.inMilliseconds / 1000;
    final total = ceil ? seconds.ceil() : seconds.floor();
    return '${total ~/ 60}:${_two(total % 60)}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
