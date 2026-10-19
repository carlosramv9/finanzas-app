import 'package:flutter/material.dart';

/// Cuadro redondeado con línea ascendente (logo del diseño).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Finanzas',
        child: CustomPaint(size: Size.square(size), painter: _LogoPainter(color)),
      );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 36;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2 * s, 2 * s, 32 * s, 32 * s),
        Radius.circular(9 * s),
      ),
      paint,
    );
    final path = Path()
      ..moveTo(11 * s, 23 * s)
      ..lineTo(16 * s, 17 * s)
      ..lineTo(20 * s, 20 * s)
      ..lineTo(26 * s, 12 * s);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color;
}
