import 'package:flutter/material.dart';

class CustomSmsIcon extends StatelessWidget {
  final Color color;
  final double size;

  const CustomSmsIcon({
    super.key,
    required this.color,
    this.size = 21.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CustomSmsIconPainter(color: color),
      ),
    );
  }
}

class _CustomSmsIconPainter extends CustomPainter {
  final Color color;

  _CustomSmsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 32.0;
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Path 1 (inner horizontal lines)
    final path1 = Path()
      ..moveTo(10, 16)
      ..lineTo(18, 16)
      ..moveTo(10, 10.6667)
      ..lineTo(14, 10.6667);
    canvas.drawPath(path1, paint);

    // Path 2 (secondary back bubble)
    final path2 = Path()
      ..moveTo(11.3333, 26.667)
      ..cubicTo(12.7338, 27.8266, 14.4193, 28.5654, 16.3513, 28.6921)
      ..cubicTo(17.8735, 28.792, 19.4628, 28.7918, 20.9819, 28.6921)
      ..cubicTo(21.505, 28.6578, 22.0752, 28.5346, 22.5663, 28.335)
      ..cubicTo(23.1126, 28.113, 23.3859, 28.0019, 23.5248, 28.0187)
      ..cubicTo(23.6636, 28.0356, 23.8651, 28.1822, 24.268, 28.4754)
      ..cubicTo(24.9784, 28.9923, 25.8733, 29.3636, 27.2005, 29.3318)
      ..cubicTo(27.8716, 29.3156, 28.2072, 29.3076, 28.3574, 29.0548)
      ..cubicTo(28.5076, 28.8021, 28.3205, 28.4522, 27.9464, 27.7524)
      ..cubicTo(27.4274, 26.7819, 27.0986, 25.6708, 27.5968, 24.7806)
      ..cubicTo(28.4549, 23.509, 29.1838, 22.0031, 29.2903, 20.3767)
      ..cubicTo(29.3476, 19.5028, 29.3476, 18.5978, 29.2903, 17.7239)
      ..cubicTo(29.2194, 16.6402, 28.9563, 15.61, 28.5348, 14.667);
    canvas.drawPath(path2, paint);

    // Path 3 (main front speech bubble)
    final path3 = Path()
      ..moveTo(16.4601, 23.316)
      ..cubicTo(21.2008, 23.0038, 24.9771, 19.2096, 25.2878, 14.4462)
      ..cubicTo(25.3486, 13.5141, 25.3486, 12.5487, 25.2878, 11.6166)
      ..cubicTo(24.9771, 6.85324, 21.2008, 3.059, 16.4601, 2.7468)
      ..cubicTo(14.8427, 2.64028, 13.1541, 2.6405, 11.5401, 2.7468)
      ..cubicTo(6.79932, 3.059, 3.02308, 6.85324, 2.71235, 11.6166)
      ..cubicTo(2.65155, 12.5487, 2.65155, 13.5141, 2.71235, 14.4462)
      ..cubicTo(2.82552, 16.1811, 3.59997, 17.7874, 4.51171, 19.1437)
      ..cubicTo(5.04109, 20.0933, 4.69172, 21.2785, 4.14032, 22.3137)
      ..cubicTo(3.74275, 23.0601, 3.54396, 23.4333, 3.70357, 23.7029)
      ..cubicTo(3.86318, 23.9725, 4.21971, 23.9811, 4.93276, 23.9983)
      ..cubicTo(6.3429, 24.0323, 7.29379, 23.6362, 8.04858, 23.0848)
      ..cubicTo(8.47667, 22.7721, 8.69072, 22.6157, 8.83824, 22.5977)
      ..cubicTo(8.98577, 22.5798, 9.27608, 22.6982, 9.85662, 22.9351)
      ..cubicTo(10.3784, 23.148, 10.9842, 23.2794, 11.5401, 23.316)
      ..cubicTo(13.1541, 23.4223, 14.8427, 23.4225, 16.4601, 23.316)
      ..close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant _CustomSmsIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
