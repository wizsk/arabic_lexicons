import 'package:flutter/material.dart';

class DashedDivider extends StatelessWidget {
  const DashedDivider({
    super.key,
    this.color,
    this.dashWidth = 8,
    this.dashGap = 6,
    this.thickness = 1,
    this.height,
  });

  final Color? color;
  final double dashWidth;
  final double dashGap;
  final double thickness;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.outlineVariant;

    final painter = CustomPaint(
      size: Size(double.infinity, thickness),
      painter: _DashedDividerPainter(
        color: c,
        dashWidth: dashWidth,
        dashGap: dashGap,
        thickness: thickness,
      ),
    );

    return height == null
        ? painter
        : Padding(
            padding: EdgeInsets.symmetric(vertical: height!),
            child: painter,
          );
  }
}

class _DashedDividerPainter extends CustomPainter {
  const _DashedDividerPainter({
    required this.color,
    required this.dashWidth,
    required this.dashGap,
    required this.thickness,
  });

  final Color color;
  final double dashWidth;
  final double dashGap;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    for (double x = 0; x < size.width; x += dashWidth + dashGap) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + dashWidth).clamp(0, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedDividerPainter oldDelegate) =>
      color != oldDelegate.color ||
      dashWidth != oldDelegate.dashWidth ||
      dashGap != oldDelegate.dashGap ||
      thickness != oldDelegate.thickness;
}
