import 'package:flutter/material.dart';

class CustomSettingsIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const CustomSettingsIcon({
    super.key,
    this.color,
    this.size = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CustomSettingsIconPainter(color: effectiveColor),
      ),
    );
  }
}

class _CustomSettingsIconPainter extends CustomPainter {
  final Color color;

  _CustomSettingsIconPainter({required this.color});

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

    // Path 1 (gear outer outline)
    final path1 = Path()
      ..moveTo(21.3175, 7.14139)
      ..lineTo(20.8239, 6.28479)
      ..cubicTo(20.4506, 5.63696, 20.264, 5.31305, 19.9464, 5.18388)
      ..cubicTo(19.6288, 5.05472, 19.2696, 5.15664, 18.5513, 5.36048)
      ..lineTo(17.3311, 5.70418)
      ..cubicTo(16.8725, 5.80994, 16.3913, 5.74994, 15.9726, 5.53479)
      ..lineTo(15.6357, 5.34042)
      ..cubicTo(15.2766, 5.11043, 15.0004, 4.77133, 14.8475, 4.37274)
      ..lineTo(14.5136, 3.37536)
      ..cubicTo(14.294, 2.71534, 14.1842, 2.38533, 13.9228, 2.19657)
      ..cubicTo(13.6615, 2.00781, 13.3143, 2.00781, 12.6199, 2.00781)
      ..lineTo(11.5051, 2.00781)
      ..cubicTo(10.8108, 2.00781, 10.4636, 2.00781, 10.2022, 2.19657)
      ..cubicTo(9.94085, 2.38533, 9.83106, 2.71534, 9.61149, 3.37536)
      ..lineTo(9.27753, 4.37274)
      ..cubicTo(9.12465, 4.77133, 8.84845, 5.11043, 8.48937, 5.34042)
      ..lineTo(8.15249, 5.53479)
      ..cubicTo(7.73374, 5.74994, 7.25259, 5.80994, 6.79398, 5.70418)
      ..lineTo(5.57375, 5.36048)
      ..cubicTo(4.85541, 5.15664, 4.49625, 5.05472, 4.17867, 5.18388)
      ..cubicTo(3.86109, 5.31305, 3.67445, 5.63696, 3.30115, 6.28479)
      ..lineTo(2.80757, 7.14139)
      ..cubicTo(2.45766, 7.74864, 2.2827, 8.05227, 2.31666, 8.37549)
      ..cubicTo(2.35061, 8.69871, 2.58483, 8.95918, 3.05326, 9.48012)
      ..lineTo(4.0843, 10.6328)
      ..cubicTo(4.3363, 10.9518, 4.51521, 11.5078, 4.51521, 12.0077)
      ..cubicTo(4.51521, 12.5078, 4.33636, 13.0636, 4.08433, 13.3827)
      ..lineTo(3.05326, 14.5354)
      ..cubicTo(2.58483, 15.0564, 2.35062, 15.3168, 2.31666, 15.6401)
      ..cubicTo(2.2827, 15.9633, 2.45766, 16.2669, 2.80757, 16.8741)
      ..lineTo(3.30114, 17.7307)
      ..cubicTo(3.67443, 18.3785, 3.86109, 18.7025, 4.17867, 18.8316)
      ..cubicTo(4.49625, 18.9608, 4.85542, 18.8589, 5.57377, 18.655)
      ..lineTo(6.79394, 18.3113)
      ..cubicTo(7.25263, 18.2055, 7.73387, 18.2656, 8.15267, 18.4808)
      ..lineTo(8.4895, 18.6752)
      ..cubicTo(8.84851, 18.9052, 9.12464, 19.2442, 9.2775, 19.6428)
      ..lineTo(9.61149, 20.6403)
      ..cubicTo(9.83106, 21.3003, 9.94085, 21.6303, 10.2022, 21.8191)
      ..cubicTo(10.4636, 22.0078, 10.8108, 22.0078, 11.5051, 22.0078)
      ..lineTo(12.6199, 22.0078)
      ..cubicTo(13.3143, 22.0078, 13.6615, 22.0078, 13.9228, 21.8191)
      ..cubicTo(14.1842, 21.6303, 14.294, 21.3003, 14.5136, 20.6403)
      ..lineTo(14.8476, 19.6428)
      ..cubicTo(15.0004, 19.2442, 15.2765, 18.9052, 15.6356, 18.6752)
      ..lineTo(15.9724, 18.4808)
      ..cubicTo(16.3912, 18.2656, 16.8724, 18.2055, 17.3311, 18.3113)
      ..lineTo(18.5513, 18.655)
      ..cubicTo(19.2696, 18.8589, 19.6288, 18.9608, 19.9464, 18.8316)
      ..cubicTo(20.264, 18.7025, 20.4506, 18.3785, 20.8239, 17.7307)
      ..lineTo(21.3175, 16.8741)
      ..cubicTo(21.6674, 16.2669, 21.8423, 15.9633, 21.8084, 15.6401)
      ..cubicTo(21.7744, 15.3168, 21.5402, 15.0564, 21.0718, 14.5354)
      ..lineTo(20.0407, 13.3827)
      ..cubicTo(19.7887, 13.0636, 19.6098, 12.5078, 19.6098, 12.0077)
      ..cubicTo(19.6098, 11.5078, 19.7888, 10.9518, 20.0407, 10.6328)
      ..lineTo(21.0718, 9.48012)
      ..cubicTo(21.5402, 8.95918, 21.7744, 8.69871, 21.8084, 8.37549)
      ..cubicTo(21.8423, 8.05227, 21.6674, 7.74864, 21.3175, 7.14139)
      ..close();
    canvas.drawPath(path1, paint);

    // Path 2 (inner circle)
    final path2 = Path()
      ..moveTo(15.5195, 12)
      ..cubicTo(15.5195, 13.933, 13.9525, 15.5, 12.0195, 15.5)
      ..cubicTo(10.0865, 15.5, 8.51953, 13.933, 8.51953, 12)
      ..cubicTo(8.51953, 10.067, 10.0865, 8.5, 12.0195, 8.5)
      ..cubicTo(13.9525, 8.5, 15.5195, 10.067, 15.5195, 12)
      ..close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant _CustomSettingsIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
