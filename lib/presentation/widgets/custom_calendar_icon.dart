import 'package:flutter/material.dart';

class CustomCalendarIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const CustomCalendarIcon({
    super.key,
    this.color,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CustomCalendarIconPainter(color: effectiveColor),
      ),
    );
  }
}

class _CustomCalendarIconPainter extends CustomPainter {
  final Color color;

  _CustomCalendarIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 20.0;
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      // M3.33325 6.66699H16.6666
      ..moveTo(3.33325, 6.66699)
      ..lineTo(16.6666, 6.66699)
      // M3.33325 6.66699V14.0005C3.33325 14.9339 3.33325 15.4004 3.51491 15.7569C3.6747 16.0705 3.92948 16.3257 4.24308 16.4855C4.59925 16.667 5.06575 16.667 5.99734 16.667H14.0025C14.9341 16.667 15.3999 16.667 15.7561 16.4855C16.0697 16.3257 16.3253 16.0705 16.4851 15.7569C16.6666 15.4007 16.6666 14.9349 16.6666 14.0033V6.66699
      ..moveTo(3.33325, 6.66699)
      ..lineTo(3.33325, 14.0005)
      ..cubicTo(3.33325, 14.9339, 3.33325, 15.4004, 3.51491, 15.7569)
      ..cubicTo(3.6747, 16.0705, 3.92948, 16.3257, 4.24308, 16.4855)
      ..cubicTo(4.59925, 16.667, 5.06575, 16.667, 5.99734, 16.667)
      ..lineTo(14.0025, 16.667)
      ..cubicTo(14.9341, 16.667, 15.3999, 16.667, 15.7561, 16.4855)
      ..cubicTo(16.0697, 16.3257, 16.3253, 16.0705, 16.4851, 15.7569)
      ..cubicTo(16.6666, 15.4007, 16.6666, 14.9349, 16.6666, 14.0033)
      ..lineTo(16.6666, 6.66699)
      // M3.33325 6.66699V6.00049C3.33325 5.06707 3.33325 4.60001 3.51491 4.24349C3.6747 3.92989 3.92948 3.6751 4.24308 3.51531C4.5996 3.33366 5.06666 3.33366 6.00008 3.33366H6.66659
      ..moveTo(3.33325, 6.66699)
      ..lineTo(3.33325, 6.00049)
      ..cubicTo(3.33325, 5.06707, 3.33325, 4.60001, 3.51491, 4.24349)
      ..cubicTo(3.6747, 3.92989, 3.92948, 3.6751, 4.24308, 3.51531)
      ..cubicTo(4.5996, 3.33366, 5.06666, 3.33366, 6.00008, 3.33366)
      ..lineTo(6.66659, 3.33366)
      // M16.6666 6.66699V5.99775C16.6666 5.06615 16.6666 4.59966 16.4851 4.24349C16.3253 3.92989 16.0697 3.6751 15.7561 3.51531C15.3996 3.33366 14.9335 3.33366 14.0001 3.33366H13.3333
      ..moveTo(16.6666, 6.66699)
      ..lineTo(16.6666, 5.99775)
      ..cubicTo(16.6666, 5.06615, 16.6666, 4.59966, 16.4851, 4.24349)
      ..cubicTo(16.3253, 3.92989, 16.0697, 3.6751, 15.7561, 3.51531)
      ..cubicTo(15.3996, 3.33366, 14.9335, 3.33366, 14.0001, 3.33366)
      ..lineTo(13.3333, 3.33366)
      // M13.3333 1.66699V3.33366
      ..moveTo(13.3333, 1.66699)
      ..lineTo(13.3333, 3.33366)
      // M13.3333 3.33366H6.66659
      ..moveTo(13.3333, 3.33366)
      ..lineTo(6.66659, 3.33366)
      // M6.66659 1.66699V3.33366
      ..moveTo(6.66659, 1.66699)
      ..lineTo(6.66659, 3.33366);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CustomCalendarIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
