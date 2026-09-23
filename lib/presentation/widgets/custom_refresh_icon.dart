import 'package:flutter/material.dart';

class CustomRefreshIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const CustomRefreshIcon({
    super.key,
    this.color,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color ?? const Color(0xFF585858);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CustomRefreshIconPainter(color: effectiveColor),
      ),
    );
  }
}

class _CustomRefreshIconPainter extends CustomPainter {
  final Color color;

  _CustomRefreshIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      // M14 16H19V21
      ..moveTo(14, 16)
      ..lineTo(19, 16)
      ..lineTo(19, 21)
      // M10 8H5V3
      ..moveTo(10, 8)
      ..lineTo(5, 8)
      ..lineTo(5, 3)
      // M19.4176 9.0034 C...
      ..moveTo(19.4176, 9.0034)
      ..cubicTo(18.8569, 7.61566, 17.9181, 6.41304, 16.708, 5.53223)
      ..cubicTo(15.4979, 4.65141, 14.0652, 4.12752, 12.5723, 4.02051)
      ..cubicTo(11.0794, 3.9135, 9.58606, 4.2274, 8.2627, 4.92661)
      ..cubicTo(6.93933, 5.62582, 5.83882, 6.68254, 5.08594, 7.97612)
      // M4.58203 14.9971 C...
      ..moveTo(4.58203, 14.9971)
      ..cubicTo(5.14272, 16.3848, 6.08146, 17.5874, 7.29157, 18.4682)
      ..cubicTo(8.50169, 19.3491, 9.93588, 19.8723, 11.4288, 19.9793)
      ..cubicTo(12.9217, 20.0863, 14.4138, 19.7725, 15.7371, 19.0732)
      ..cubicTo(17.0605, 18.374, 18.1603, 17.3175, 18.9131, 16.0239);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CustomRefreshIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
