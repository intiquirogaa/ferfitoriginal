import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Circular progress ring for daily workout completion with exercise dots and animations.
class DailyGoalRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final int exerciseCount;
  final int completedExercises;
  final bool showCenter;
  final bool animate;

  const DailyGoalRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 10,
    this.exerciseCount = 0,
    this.completedExercises = 0,
    this.showCenter = true,
    this.animate = true,
  });

  @override
  State<DailyGoalRing> createState() => _DailyGoalRingState();
}

class _DailyGoalRingState extends State<DailyGoalRing> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _progressAnimation = Tween<double>(
      begin: widget.animate ? 0.0 : widget.progress,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    ));

    if (widget.animate) {
      _progressController.forward();
    }

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.progress >= 1.0) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant DailyGoalRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress && widget.animate) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ));
      
      _progressController.forward(from: 0);

      if (widget.progress >= 1.0 && !oldWidget.progress.isNaN) {
        _glowController.repeat(reverse: true);
      } else if (widget.progress < 1.0) {
        _glowController.stop();
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressController, _glowController]),
      builder: (context, child) {
        final currentVal = _progressAnimation.value;
        final glowOpacity = widget.progress >= 1.0 
            ? 0.2 + (_glowController.value * 0.3) 
            : 0.0;

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: glowOpacity > 0 
                ? [BoxShadow(color: AppColors.primary.withOpacity(glowOpacity), blurRadius: 20, spreadRadius: 4)]
                : null,
          ),
          child: CustomPaint(
            painter: _RingPainter(
              progress: currentVal,
              strokeWidth: widget.strokeWidth,
              exerciseCount: widget.exerciseCount,
              completedExercises: widget.completedExercises,
            ),
            child: widget.showCenter ? Center(
              child: currentVal >= 1.0
                  ? Icon(Icons.check_rounded, color: AppColors.primary, size: widget.size * 0.3)
                  : currentVal < 0.5 && currentVal > 0.0 && widget.exerciseCount == 0 // simple fallback if no exercises provided
                      ? Icon(Icons.bolt, color: AppColors.primary, size: widget.size * 0.3)
                      : Text(
                          '${(currentVal * 100).round()}%',
                          style: GoogleFonts.rajdhani(
                            fontSize: widget.size * 0.22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
            ) : null,
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final int exerciseCount;
  final int completedExercises;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.exerciseCount,
    required this.completedExercises,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // 1. Background Track
    final trackPaint = Paint()
      ..color = AppColors.cardSolid.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
      
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Progress Arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = math.max(0.001, progress * 2 * math.pi); // min angle to show cap
    
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.primary, Color(0xFF4ADE80)],
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start at -90 degrees (-pi/2)
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);

    // 3. Exercise Dots
    if (exerciseCount > 0) {
      final dotPaint = Paint()..style = PaintingStyle.fill;
      
      for (int i = 0; i < exerciseCount; i++) {
        // Calculate angle for each dot (evenly spaced)
        final angle = (i / exerciseCount) * 2 * math.pi - (math.pi / 2);
        
        // Calculate position on the ring
        final x = center.dx + radius * math.cos(angle);
        final y = center.dy + radius * math.sin(angle);
        
        // Color based on completion
        if (i < completedExercises) {
          dotPaint.color = AppColors.primary;
        } else {
          dotPaint.color = AppColors.mutedForeground.withOpacity(0.3);
        }
        
        canvas.drawCircle(Offset(x, y), 4.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return progress != oldDelegate.progress || 
           exerciseCount != oldDelegate.exerciseCount ||
           completedExercises != oldDelegate.completedExercises;
  }
}
