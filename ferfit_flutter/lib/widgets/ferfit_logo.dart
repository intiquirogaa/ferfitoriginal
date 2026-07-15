import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FerFitLogo extends StatelessWidget {
  final double size;

  const FerFitLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.2, // El SVG tiene una relación de aspecto de 100x120
      child: CustomPaint(
        painter: _FerFitLogoPainter(),
      ),
    );
  }
}

class _FerFitLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 100.0;
    final scaleY = size.height / 120.0;

    final greenPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final purplePaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    // Camino del rayo verde (forma de "F")
    final greenPath = Path()
      ..moveTo(20 * scaleX, 15 * scaleY)
      ..lineTo(80 * scaleX, 15 * scaleY)
      ..lineTo(72 * scaleX, 37 * scaleY)
      ..lineTo(46 * scaleX, 37 * scaleY)
      ..lineTo(53 * scaleX, 52 * scaleY)
      ..lineTo(75 * scaleX, 52 * scaleY)
      ..lineTo(67 * scaleX, 74 * scaleY)
      ..lineTo(41 * scaleX, 74 * scaleY)
      ..lineTo(27 * scaleX, 105 * scaleY)
      ..lineTo(37 * scaleX, 62 * scaleY)
      ..lineTo(25 * scaleX, 62 * scaleY)
      ..lineTo(32 * scaleX, 37 * scaleY)
      ..lineTo(20 * scaleX, 37 * scaleY)
      ..close();

    // Camino del bloque de acento púrpura en la esquina inferior derecha
    final purplePath = Path()
      ..moveTo(50 * scaleX, 78 * scaleY)
      ..lineTo(75 * scaleX, 78 * scaleY)
      ..lineTo(67 * scaleX, 96 * scaleY)
      ..lineTo(42 * scaleX, 96 * scaleY)
      ..close();

    canvas.drawPath(greenPath, greenPaint);
    canvas.drawPath(purplePath, purplePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
