import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';

/// 日ごとの抽出回数の棒グラフ（外部パッケージを使わない CustomPaint 製）。
class DailyBarChart extends StatelessWidget {
  const DailyBarChart({
    super.key,
    required this.counts,
    required this.firstDay,
    this.height = 140,
  });

  final List<int> counts;
  final DateTime firstDay;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = counts.fold<int>(0, (a, b) => a + b);
    return Semantics(
      label: '直近${counts.length}日の抽出回数のグラフ。合計$total回。',
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _BarChartPainter(
              counts: counts,
              firstDay: firstDay,
              bar: scheme.primary,
              today: scheme.tertiary,
              empty: scheme.surfaceContainerHighest,
              grid: scheme.outlineVariant,
              labelStyle: theme.textTheme.labelSmall!.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.counts,
    required this.firstDay,
    required this.bar,
    required this.today,
    required this.empty,
    required this.grid,
    required this.labelStyle,
  });

  final List<int> counts;
  final DateTime firstDay;
  final Color bar;
  final Color today;
  final Color empty;
  final Color grid;
  final TextStyle labelStyle;

  static const double _labelHeight = 20;

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty) return;
    final chartHeight = size.height - _labelHeight;
    final maxCount = math.max(1, counts.reduce(math.max));
    final slot = size.width / counts.length;
    final barWidth = math.max(2.0, slot * 0.6);

    // 基準線
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      Paint()
        ..color = grid
        ..strokeWidth = 1,
    );

    // 最大値の目盛り（点線ではなく細い線で控えめに）
    _drawText(canvas, '$maxCount回', size.width, 0, _Align.end);
    canvas.drawLine(
      const Offset(0, AppSpace.lg),
      Offset(size.width - 36, AppSpace.lg),
      Paint()
        ..color = grid.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    final usable = chartHeight - AppSpace.lg;
    for (var i = 0; i < counts.length; i++) {
      final x = slot * i + (slot - barWidth) / 2;
      final c = counts[i];
      final isToday = i == counts.length - 1;
      if (c == 0) {
        // 0 回の日も小さな点で「日がある」ことを示す
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, chartHeight - 3, barWidth, 3),
            const Radius.circular(2),
          ),
          Paint()..color = empty,
        );
        continue;
      }
      final h = usable * c / maxCount;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, chartHeight - h, barWidth, h),
          topLeft: Radius.circular(barWidth / 2),
          topRight: Radius.circular(barWidth / 2),
        ),
        Paint()..color = isToday ? today : bar,
      );
    }

    // 日付ラベル: 先頭・中間・今日
    for (final i in [0, counts.length ~/ 2, counts.length - 1]) {
      final day = DateTime(firstDay.year, firstDay.month, firstDay.day + i);
      final label = i == counts.length - 1 ? '今日' : '${day.month}/${day.day}';
      final last = i == counts.length - 1;
      if (i == 0) {
        _drawText(canvas, label, 0, chartHeight + 4, _Align.start);
      } else if (last) {
        _drawText(canvas, label, size.width, chartHeight + 4, _Align.end);
      } else {
        final cx = slot * i + slot / 2;
        _drawText(canvas, label, cx, chartHeight + 4, _Align.center);
      }
    }
  }

  /// [x] を基準に、左揃え・中央・右揃えでテキストを描く。
  void _drawText(Canvas canvas, String text, double x, double y, _Align align) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      _Align.start => x,
      _Align.center => x - tp.width / 2,
      _Align.end => x - tp.width,
    };
    tp.paint(canvas, Offset(dx, y));
    tp.dispose();
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      !listEquals(old.counts, counts) ||
      old.bar != bar ||
      old.today != today ||
      old.empty != empty ||
      old.grid != grid ||
      old.labelStyle != labelStyle;
}

enum _Align { start, center, end }
