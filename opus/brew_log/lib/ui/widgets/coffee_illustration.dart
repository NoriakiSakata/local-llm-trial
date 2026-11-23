import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

enum CoffeeIllustrationKind { cup, bean, chart }

/// 空状態用の線画イラスト。画像アセットを持たず、テーマ色で描くのでダークでも馴染む。
class CoffeeIllustration extends StatelessWidget {
  const CoffeeIllustration({super.key, required this.kind, this.size = 120});

  final CoffeeIllustrationKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _IllustrationPainter(
          kind: kind,
          background: scheme.surfaceContainerHigh,
          stroke: scheme.primary,
          accent: scheme.tertiary,
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter({
    required this.kind,
    required this.background,
    required this.stroke,
    required this.accent,
  });

  final CoffeeIllustrationKind kind;
  final Color background;
  final Color stroke;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    canvas.drawCircle(c, s / 2, Paint()..color = background);

    final line = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final accentLine = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025
      ..strokeCap = StrokeCap.round;

    switch (kind) {
      case CoffeeIllustrationKind.cup:
        _cup(canvas, s, line, accentLine);
      case CoffeeIllustrationKind.bean:
        _bean(canvas, s, line, accentLine);
      case CoffeeIllustrationKind.chart:
        _chart(canvas, s, line, accentLine);
    }
  }

  void _cup(Canvas canvas, double s, Paint line, Paint accentLine) {
    // カップ本体
    final body = Path()
      ..moveTo(s * 0.28, s * 0.42)
      ..lineTo(s * 0.66, s * 0.42)
      ..lineTo(s * 0.62, s * 0.70)
      ..quadraticBezierTo(s * 0.61, s * 0.74, s * 0.57, s * 0.74)
      ..lineTo(s * 0.37, s * 0.74)
      ..quadraticBezierTo(s * 0.33, s * 0.74, s * 0.32, s * 0.70)
      ..close();
    canvas.drawPath(body, line);
    // 取っ手
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(s * 0.67, s * 0.53),
        width: s * 0.16,
        height: s * 0.16,
      ),
      -math.pi / 2,
      math.pi,
      false,
      line,
    );
    // ソーサー
    canvas.drawLine(
      Offset(s * 0.22, s * 0.80),
      Offset(s * 0.72, s * 0.80),
      line,
    );
    // 湯気
    for (final x in [0.40, 0.54]) {
      final steam = Path()
        ..moveTo(s * x, s * 0.34)
        ..cubicTo(
          s * (x - 0.04),
          s * 0.29,
          s * (x + 0.04),
          s * 0.25,
          s * x,
          s * 0.20,
        );
      canvas.drawPath(steam, accentLine);
    }
  }

  void _bean(Canvas canvas, double s, Paint line, Paint accentLine) {
    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.rotate(-math.pi / 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 0.40, height: s * 0.56),
      line,
    );
    final crease = Path()
      ..moveTo(0, -s * 0.24)
      ..cubicTo(s * 0.08, -s * 0.08, -s * 0.08, s * 0.08, 0, s * 0.24);
    canvas.drawPath(crease, accentLine);
    canvas.restore();
  }

  void _chart(Canvas canvas, double s, Paint line, Paint accentLine) {
    canvas.drawLine(
      Offset(s * 0.26, s * 0.74),
      Offset(s * 0.76, s * 0.74),
      line,
    );
    final bars = [0.18, 0.30, 0.22, 0.38];
    for (var i = 0; i < bars.length; i++) {
      final x = s * (0.32 + i * 0.12);
      canvas.drawLine(
        Offset(x, s * 0.68),
        Offset(x, s * (0.68 - bars[i])),
        i == bars.length - 1 ? accentLine : line,
      );
    }
  }

  @override
  bool shouldRepaint(_IllustrationPainter old) =>
      old.kind != kind ||
      old.background != background ||
      old.stroke != stroke ||
      old.accent != accent;
}
