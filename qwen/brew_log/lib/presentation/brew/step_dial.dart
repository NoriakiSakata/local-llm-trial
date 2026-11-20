import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 進行状況を示すリング。外部パッケージを使わず CustomPaint で描く。
class StepDial extends StatelessWidget {
  const StepDial({
    required this.progress,
    required this.boundaries,
    required this.child,
    this.paused = false,
    super.key,
  });

  /// 0〜1 の全体進行。
  final double progress;

  /// 各ステップの開始位置（0〜1 の割合）。目印として描く。
  final List<double> boundaries;

  final bool paused;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _DialPainter(
          progress: paused ? 0 : progress,
          holdProgress: paused ? progress : 0,
          boundaries: boundaries,
          trackColor: scheme.surfaceContainerHighest,
          progressColor: scheme.primary,
          pausedColor: scheme.tertiary,
          tickColor: scheme.onSurfaceVariant,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.progress,
    required this.holdProgress,
    required this.boundaries,
    required this.trackColor,
    required this.progressColor,
    required this.pausedColor,
    required this.tickColor,
  });

  final double progress;
  final double holdProgress;
  final List<double> boundaries;
  final Color trackColor;
  final Color progressColor;
  final Color pausedColor;
  final Color tickColor;

  static const double _stroke = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius =
        (math.min(size.width, size.height) - _stroke) / 2 - size.width * 0.04;

    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (holdProgress > 0) {
      // 一時停止中は、進んだ分を別色で薄く残す。
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * holdProgress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.round
          ..color = pausedColor.withValues(alpha: 0.45),
      );
    }

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.round
          ..color = progressColor,
      );
    }

    // ステップ境界の目印（リングを横切る短い線）。
    final Paint tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = tickColor.withValues(alpha: 0.7);
    for (final double fraction in boundaries) {
      final double angle = -math.pi / 2 + 2 * math.pi * fraction;
      final Offset inner =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (radius - _stroke);
      final Offset outer =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (radius + _stroke);
      canvas.drawLine(inner, outer, tick);
    }

    // 現在位置のノブ。
    if (progress > 0) {
      final double angle = -math.pi / 2 + 2 * math.pi * progress;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        _stroke * 0.72,
        Paint()..color = progressColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.progress != progress ||
      old.holdProgress != holdProgress ||
      old.boundaries != boundaries ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.pausedColor != pausedColor ||
      old.tickColor != tickColor;
}
