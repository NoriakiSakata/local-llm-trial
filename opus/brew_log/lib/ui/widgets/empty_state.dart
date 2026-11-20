import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';

/// データが0件のときの画面。何をすればいいかを1行で示し、必要なら操作ボタンを置く。
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.actionLabel, this.onAction});

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(dimension: 120, child: CustomPaint(painter: _CupPainter(theme.colorScheme))),
            const SizedBox(height: Space.lg),
            Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: Space.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: Space.lg),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 湯気の立つカップ
class _CupPainter extends CustomPainter {
  _CupPainter(this.scheme);
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, Paint()..color = scheme.surfaceContainerHigh);

    final stroke = Paint()
      ..color = scheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;

    final cup = Path()
      ..moveTo(w * 0.28, h * 0.46)
      ..lineTo(w * 0.66, h * 0.46)
      ..quadraticBezierTo(w * 0.66, h * 0.76, w * 0.47, h * 0.76)
      ..quadraticBezierTo(w * 0.28, h * 0.76, w * 0.28, h * 0.46)
      ..close();
    canvas.drawPath(cup, Paint()..color = scheme.primaryContainer);
    canvas.drawPath(cup, stroke);
    canvas.drawArc(Rect.fromLTWH(w * 0.6, h * 0.5, w * 0.14, h * 0.13), -1.4, 2.8, false, stroke);
    canvas.drawLine(Offset(w * 0.24, h * 0.82), Offset(w * 0.72, h * 0.82), stroke);

    for (final x in [0.4, 0.54]) {
      final steam = Path()
        ..moveTo(w * x, h * 0.38)
        ..cubicTo(w * (x - 0.05), h * 0.32, w * (x + 0.05), h * 0.28, w * x, h * 0.22);
      canvas.drawPath(steam, stroke..color = scheme.tertiary);
    }
  }

  @override
  bool shouldRepaint(_CupPainter old) => old.scheme != scheme;
}
