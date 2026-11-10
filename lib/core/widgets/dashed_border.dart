import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Envuelve [child] con un borde discontinuo de esquinas redondeadas (la
/// tarjeta "Añadir hijo/a" del diseño). Flutter no trae borde punteado, por
/// eso se dibuja con un `CustomPainter`.
class DashedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gap;

  const DashedBorder({
    super.key,
    required this.child,
    this.color = AppColors.secondary500,
    this.strokeWidth = 2,
    this.radius = 22,
    this.dashLength = 7,
    this.gap = 5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        radius: radius,
        dashLength: dashLength,
        gap: gap,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gap;

  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius ||
      old.dashLength != dashLength ||
      old.gap != gap;
}
