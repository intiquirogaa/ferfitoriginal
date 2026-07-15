import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'ferfit_mascot.dart';

/// Full-screen celebration overlay when user levels up.
class LevelUpCelebration extends StatefulWidget {
  final int level;
  final int? xpEarned;
  final VoidCallback onClose;

  const LevelUpCelebration({
    super.key,
    required this.level,
    this.xpEarned,
    required this.onClose,
  });

  static Future<void> show(BuildContext context, {required int level, int? xpEarned}) async {
    await showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.82),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return LevelUpCelebration(
          level: level,
          xpEarned: xpEarned,
          onClose: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration> with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _numberController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(); // Runs continuously for 60fps paint updates

    _numberController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _startAnimations();

    // Auto close
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _numberController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _fadeController.forward();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _numberController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Confetti overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    time: DateTime.now().millisecondsSinceEpoch / 1000.0,
                  ),
                );
              },
            ),
          ),
          
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FerFitMascot(
                  size: 100,
                  mood: FerFitMascotMood.goal,
                  anim: FeoAnim.celebrate,
                  showName: true,
                ),
                const SizedBox(height: 20),
                
                // Animated level number
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _numberController,
                    curve: Curves.elasticOut,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '¡NIVEL ${widget.level}!',
                      style: GoogleFonts.rajdhani(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: AppColors.primary,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                if (widget.xpEarned != null) ...[
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _fadeController,
                      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
                    ),
                    child: Text(
                      '+${widget.xpEarned} XP',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFBBF24),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _fadeController,
                    curve: const Interval(0.25, 1.0, curve: Curves.easeIn),
                  ),
                  child: Text(
                    'Seguí así, ¡sos imparable!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  final double speed;
  final Color color;
  final double width;
  final double height;
  final double rotationSpeed;
  final double drift;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.color,
    required this.width,
    required this.height,
    required this.rotationSpeed,
    required this.drift,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double time;
  static List<_Particle>? _particles;
  static double _lastTime = 0;

  _ConfettiPainter({required this.time});

  void _initParticles(Size size) {
    if (_particles != null) return;
    
    final colors = [
      AppColors.primary,
      const Color(0xFFFBBF24),
      Colors.white,
      AppColors.secondary,
      const Color(0xFF4ADE80)
    ];
    
    final random = math.Random();
    _particles = List.generate(50, (index) {
      return _Particle(
        x: random.nextDouble() * size.width,
        y: -20.0 - random.nextDouble() * size.height, // Staggered starts
        speed: 100.0 + random.nextDouble() * 200.0,
        color: colors[random.nextInt(colors.length)],
        width: 4.0 + random.nextDouble() * 4.0,
        height: 6.0 + random.nextDouble() * 6.0,
        rotationSpeed: (random.nextDouble() - 0.5) * 10.0,
        drift: (random.nextDouble() - 0.5) * 2.0,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    _initParticles(size);
    
    final dt = time - _lastTime;
    _lastTime = time;
    
    // Safety check for large dt (e.g., app backgrounded)
    final safeDt = dt > 0.1 ? 0.016 : dt;

    final paint = Paint()..style = PaintingStyle.fill;
    
    for (var p in _particles!) {
      // Update position
      p.y += p.speed * safeDt;
      p.x += math.sin(time * p.drift) * 50 * safeDt; // Sine drift
      
      // Recycle if below screen
      if (p.y > size.height + 20) {
        p.y = -20;
        p.x = math.Random().nextDouble() * size.width;
      }

      // Draw particle with rotation
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(time * p.rotationSpeed);
      
      paint.color = p.color;
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.width, height: p.height), paint);
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return time != oldDelegate.time;
  }
}
