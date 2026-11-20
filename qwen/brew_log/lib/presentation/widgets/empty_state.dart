import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// データが無いことを伝える画面。
///
/// 「何が無い」だけでなく「次に何をすればいいか」まで出す設計にしている。
/// イラストは外部アセットを使わず、ドリッパーとカップの幾何学図形を
/// CustomPaint で描いたプレースホルダー。
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.description,
    this.action,
    this.secondaryAction,
    super.key,
  });

  final String title;
  final String description;
  final Widget? action;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CustomPaint(
              size: const Size.square(AppSize.emptyArt),
              painter: _DripperPainter(
                lineColor: scheme.onSurfaceVariant,
                accentColor: scheme.primary,
                fillColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: AppSpacing.sm),
              secondaryAction!,
            ],
          ],
        ),
      ),
    );
  }
}

/// ハンドドリップ（ドリッパー + カップ + 湯気）のシンプルな線画。
class _DripperPainter extends CustomPainter {
  _DripperPainter({
    required this.lineColor,
    required this.accentColor,
    required this.fillColor,
  });

  final Color lineColor;
  final Color accentColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = lineColor.withValues(alpha: 0.75);

    final Paint fill = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;

    // ドリッパー（台形）
    final Path cone = Path()
      ..moveTo(w * 0.16, h * 0.30)
      ..lineTo(w * 0.84, h * 0.30)
      ..lineTo(w * 0.63, h * 0.58)
      ..lineTo(w * 0.37, h * 0.58)
      ..close();
    canvas.drawPath(cone, fill);
    canvas.drawPath(cone, stroke);

    // リム
    canvas.drawLine(
      Offset(w * 0.12, h * 0.30),
      Offset(w * 0.88, h * 0.30),
      Paint()
        ..color = accentColor
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round,
    );

    // カップ
    final Rect cup = Rect.fromLTWH(w * 0.27, h * 0.66, w * 0.46, h * 0.26);
    final RRect cupRect = RRect.fromRectAndCorners(
      cup,
      bottomLeft: const Radius.circular(28),
      bottomRight: const Radius.circular(28),
    );
    canvas.drawRRect(cupRect, fill);
    canvas.drawRRect(cupRect, stroke);

    // ハンドル
    final Path handle = Path()
      ..moveTo(w * 0.73, h * 0.72)
      ..arcToPoint(
        Offset(w * 0.73, h * 0.86),
        radius: Radius.circular(w * 0.085),
        clockwise: true,
      );
    canvas.drawPath(handle, stroke);

    // 湯気
    final Paint steam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round
      ..color = lineColor.withValues(alpha: 0.35);
    for (int i = 0; i < 3; i++) {
      final double x = w * (0.38 + i * 0.12);
      final double phase = i.isEven ? 1 : -1;
      final Path path = Path()
        ..moveTo(x, h * 0.22)
        ..cubicTo(
          x + w * 0.05 * phase,
          h * 0.17,
          x - w * 0.05 * phase,
          h * 0.12,
          x,
          h * 0.06,
        );
      canvas.drawPath(path, steam);
    }

    // ドリップの1滴
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.62),
      w * 0.022,
      Paint()..color = accentColor.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _DripperPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.fillColor != fillColor;
}
