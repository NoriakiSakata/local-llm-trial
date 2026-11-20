import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../domain/stats.dart';

/// 日別の棒グラフ。外部パッケージを使わず CustomPaint で描く
class DailyChart extends StatelessWidget {
  const DailyChart({super.key, required this.daily});
  final List<DailyCount> daily;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = daily.fold<int>(0, (a, d) => a + d.count);
    final first = daily.first.day;
    final last = daily.last.day;
    return Semantics(
      label: '${first.month}月${first.day}日から${last.month}月${last.day}日までの日別抽出回数。合計$total杯',
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size.infinite,
          painter: _BarPainter(
            daily: daily,
            bar: theme.colorScheme.primary,
            empty: theme.colorScheme.surfaceContainerHighest,
            grid: theme.colorScheme.outlineVariant,
            label: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({required this.daily, required this.bar, required this.empty, required this.grid, required this.label});

  final List<DailyCount> daily;
  final Color bar;
  final Color empty;
  final Color grid;
  final TextStyle label;

  static const _axisHeight = 20.0;
  static const _leftWidth = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final maxCount = math.max(1, daily.map((d) => d.count).reduce(math.max));
    final chartH = size.height - _axisHeight;
    final chartW = size.width - _leftWidth;
    final slot = chartW / daily.length;
    final barW = math.max(2.0, slot * 0.6);

    // 目盛り（最大値と0）
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(Offset(_leftWidth, 0), Offset(size.width, 0), gridPaint);
    canvas.drawLine(Offset(_leftWidth, chartH), Offset(size.width, chartH), gridPaint);
    _text(canvas, '$maxCount', Offset(0, -6), width: _leftWidth - 4, align: TextAlign.right);

    for (var i = 0; i < daily.length; i++) {
      final d = daily[i];
      final x = _leftWidth + slot * i + (slot - barW) / 2;
      final h = d.count == 0 ? 2.0 : chartH * d.count / maxCount;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, chartH - h, barW, h),
        topLeft: Radius.circular(barW / 2),
        topRight: Radius.circular(barW / 2),
      );
      canvas.drawRRect(rect, Paint()..color = d.count == 0 ? empty : bar);
    }

    // 横軸は最初・中央・今日だけ
    for (final i in [0, daily.length ~/ 2, daily.length - 1]) {
      final d = daily[i].day;
      final cx = _leftWidth + slot * i + slot / 2;
      final text = i == daily.length - 1 ? '今日' : '${d.month}/${d.day}';
      _text(canvas, text, Offset(cx - 30, chartH + 4), width: 60, align: TextAlign.center);
    }
  }

  void _text(Canvas canvas, String s, Offset at, {required double width, required TextAlign align}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: label),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.daily != daily || old.bar != bar || old.empty != empty || old.label != label;
}
