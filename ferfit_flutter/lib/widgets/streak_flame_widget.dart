import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Animated streak flame using CustomPainter with organic flickering.
class StreakFlameWidget extends StatefulWidget {
  final int streak;
  final bool isAtRisk;
  final double size;
  final bool showCount;

  const StreakFlameWidget({
    super.key,
    required this.streak,
    this.isAtRisk = false,
    this.size = 60,
    this.showCount = true,
  });

  @override
  State<StreakFlameWidget> createState() => _StreakFlameWidgetState();
}

class _StreakFlameWidgetState extends State<StreakFlameWidget> with TickerProviderStateMixin {
  late AnimationController _flickerController;
  late AnimationController _sparkController;
  late AnimationController _riskController;

  @override
  void initState() {
    super.initState();
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _riskController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (widget.isAtRisk) {
      _riskController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant StreakFlameWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAtRisk != oldWidget.isAtRisk) {
      if (widget.isAtRisk) {
        _riskController.repeat(reverse: true);
      } else {
        _riskController.stop();
        _riskController.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _flickerController.dispose();
    _sparkController.dispose();
    _riskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.isAtRisk ? 0.85 : 1.0;
    final flameColors = widget.isAtRisk
        ? [const Color(0xFF7F1D1D), const Color(0xFFDC2626)]
        : [const Color(0xFFF97316), const Color(0xFFFBBF24)];
    final coreColors = widget.isAtRisk
        ? [const Color(0xFFDC2626), const Color(0xFFF97316)]
        : [const Color(0xFFFBBF24), const Color(0xFFFEF3C7)];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_flickerController, _sparkController, _riskController]),
          builder: (context, _) {
            double riskOpacity = widget.isAtRisk ? 0.6 + (_riskController.value * 0.4) : 1.0;

            return Opacity(
              opacity: riskOpacity,
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size * 1.2,
                  child: CustomPaint(
                    painter: _FlamePainter(
                      flickerValue: _flickerController.value,
                      sparkValue: _sparkController.value,
                      flameColors: flameColors,
                      coreColors: coreColors,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.showCount) ...[
          const SizedBox(height: 4),
          Text(
            '${widget.streak}',
            style: GoogleFonts.rajdhani(
              fontSize: widget.size * 0.35,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          Text(
            'días',
            style: GoogleFonts.inter(
              fontSize: widget.size * 0.18,
              color: AppColors.mutedForeground,
              height: 1.0,
            ),
          ),
        ],
      ],
    );
  }
}

class _FlamePainter extends CustomPainter {
  final double flickerValue;
  final double sparkValue;
  final List<Color> flameColors;
  final List<Color> coreColors;

  _FlamePainter({
    required this.flickerValue,
    required this.sparkValue,
    required this.flameColors,
    required this.coreColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Outer flame
    final flamePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: flameColors,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    // Organic flicker based on sine wave
    final time = flickerValue * math.pi * 2;
    final wobble = math.sin(time) * 4.0;
    
    final Path flamePath = Path();
    flamePath.moveTo(size.width * 0.5, size.height * 0.1 + wobble); // Tip
    
    // Left side curve
    flamePath.cubicTo(
      size.width * 0.1 + (math.sin(time + 1) * 3), size.height * 0.5, // Control 1
      size.width * 0.05, size.height * 0.9,                           // Control 2
      size.width * 0.5, size.height,                                  // Bottom center
    );
    
    // Right side curve
    flamePath.cubicTo(
      size.width * 0.95, size.height * 0.9,                           // Control 1
      size.width * 0.9 + (math.cos(time) * 3), size.height * 0.5,     // Control 2
      size.width * 0.5, size.height * 0.1 + wobble,                   // Back to Tip
    );
    
    canvas.drawPath(flamePath, flamePaint);

    // Inner core
    final corePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: coreColors,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final Path corePath = Path();
    corePath.moveTo(size.width * 0.5, size.height * 0.35 + wobble * 0.5); // Tip of core
    
    corePath.cubicTo(
      size.width * 0.3, size.height * 0.6,
      size.width * 0.25, size.height * 0.9,
      size.width * 0.5, size.height * 0.95,
    );
    
    corePath.cubicTo(
      size.width * 0.75, size.height * 0.9,
      size.width * 0.7, size.height * 0.6,
      size.width * 0.5, size.height * 0.35 + wobble * 0.5,
    );
    
    canvas.drawPath(corePath, corePaint);

    // Sparks
    final sparkPaint = Paint()..style = PaintingStyle.fill;
    final numSparks = 5;
    
    for (int i = 0; i < numSparks; i++) {
      // Offset each spark's phase
      double phase = (sparkValue + (i / numSparks)) % 1.0;
      
      // Rising motion
      double y = size.height * 0.5 - (phase * size.height * 0.6);
      
      // Horizontal drift (pseudo-random based on index)
      double drift = math.sin(phase * math.pi * 2 + i) * 10.0;
      double x = size.width * 0.5 + drift + (i % 2 == 0 ? 5 : -5);
      
      // Fade out as it rises
      double opacity = 1.0 - phase;
      
      // Spark color based on phase (starts yellow, ends red)
      sparkPaint.color = Color.lerp(
        const Color(0xFFFEF3C7), 
        const Color(0xFFDC2626), 
        phase,
      )!.withOpacity(opacity);
      
      canvas.drawCircle(Offset(x, y), 2.0 * (1.0 - phase * 0.5), sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) {
    return flickerValue != oldDelegate.flickerValue || 
           sparkValue != oldDelegate.sparkValue ||
           flameColors != oldDelegate.flameColors;
  }
}
