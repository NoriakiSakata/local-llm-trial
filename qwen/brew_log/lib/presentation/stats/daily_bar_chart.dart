import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/stats.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../format.dart';

/// 日別の抽出本数を描く棒グラフ。外部パッケージに依存しない自作描画。
class DailyBarChart extends StatelessWidget {
  const DailyBarChart({
    required this.daily,
    required this.max,
    this.height = 148,
    super.key,
  });

  final List<DayCount> daily;
  final double max;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle axisStyle = AppTypography.numeric(
      Theme.of(context).textTheme.labelSmall!,
    ).copyWith(color: scheme.onSurfaceVariant);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarPainter(
          daily: daily,
          max: max,
          barColor: scheme.primary,
          todayColor: scheme.tertiary,
          trackColor: scheme.surfaceContainerHighest,
          labelColor: scheme.onSurfaceVariant,
          axisStyle: axisStyle,
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.daily,
    required this.max,
    required this.barColor,
    required this.todayColor,
    required this.trackColor,
    required this.labelColor,
    required this.axisStyle,
  });

  final List<DayCount> daily;
  final double max;
  final Color barColor;
  final Color todayColor;
  final Color trackColor;
  final Color labelColor;
  final TextStyle axisStyle;

  static const double _labelBand = AppSpacing.lg + 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (daily.isEmpty) return;

    final double plotHeight = size.height - _labelBand;
    final double slot = size.width / daily.length;
    final double barWidth = math.max(3, slot * 0.55);

    // ベースライン
    canvas.drawLine(
      Offset(0, plotHeight),
      Offset(size.width, plotHeight),
      Paint()
        ..color = trackColor
        ..strokeWidth = 1,
    );

    for (int i = 0; i < daily.length; i++) {
      final DayCount day = daily[i];
      final double ratio = max == 0 ? 0 : (day.count / max).clamp(0.0, 1.0);
      final double barHeight = day.count == 0
          ? 0
          : math.max(3, ratio * plotHeight);
      final double left = slot * i + (slot - barWidth) / 2;
      final Rect rect = Rect.fromLTWH(
        left,
        plotHeight - barHeight,
        barWidth,
        barHeight,
      );
      final bool isToday = i == daily.length - 1;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        Paint()
          ..color = day.count == 0
              ? Colors.transparent
              : (isToday ? todayColor : barColor).withValues(
                  alpha: day.count == 0 ? 0 : 1,
                ),
      );

      // 件数の多い日は数值を小さく添える。
      if (day.count >= 3 && barHeight > 22) {
        _drawText(
          canvas,
          '${day.count}',
          Offset(rect.center.dx, rect.top - 12),
          size.width,
        );
      }
    }

    // 日付ラベル。等間隔 + 末尾（今日）を候補にし、右から詰めて
    // 重なる手前を落としていく（360dp幅でも衝突しない）。
    final int step = daily.length > 14 ? 7 : 1;
    final List<int> candidates = <int>{
      for (int i = 0; i < daily.length; i += step) i,
      daily.length - 1,
    }.toList()..sort();

    const double minGap = 46;
    double nextAllowed = double.infinity;
    for (int k = candidates.length - 1; k >= 0; k--) {
      final int i = candidates[k];
      final double centerX = slot * i + slot / 2;
      if (centerX > nextAllowed) continue;
      _drawText(
        canvas,
        formatMonthDay(daily[i].day),
        Offset(centerX, plotHeight + 2),
        size.width,
      );
      nextAllowed = centerX - minGap;
    }
  }

  void _drawText(Canvas canvas, String text, Offset at, double maxWidth) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: axisStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final double x = (at.dx - painter.width / 2).clamp(
      0.0,
      math.max(0, maxWidth - painter.width),
    );
    painter.paint(canvas, Offset(x, at.dy));
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) =>
      oldDelegate.max != max ||
      oldDelegate.daily != daily ||
      oldDelegate.barColor != barColor ||
      oldDelegate.todayColor != todayColor ||
      oldDelegate.axisStyle != axisStyle;
}
