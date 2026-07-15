import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ferfit_mascot.dart';

/// Premium animated Feo sprite with multi-layer animation effects.
///
/// Composes breathing, bounce entrance, glow pulse, confetti burst,
/// and urgency shake on top of the base [FerFitMascot] widget.
///
/// Use a [GlobalKey<FeoAnimatedSpriteState>] to call
/// [triggerCelebration] and [triggerShake] imperatively.
class FeoAnimatedSprite extends StatefulWidget {
  final double size;
  final FerFitMascotMood mood;
  final bool showName;
  final bool enableBreathing;
  final bool bounceOnAppear;

  const FeoAnimatedSprite({
    super.key,
    this.size = 80,
    this.mood = FerFitMascotMood.happy,
    this.showName = false,
    this.enableBreathing = true,
    this.bounceOnAppear = true,
  });

  @override
  State<FeoAnimatedSprite> createState() => FeoAnimatedSpriteState();
}

class FeoAnimatedSpriteState extends State<FeoAnimatedSprite>
    with TickerProviderStateMixin {
  // ── Breathing ──────────────────────────────────────────────────────────────
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathScale;

  // ── Bounce entrance ────────────────────────────────────────────────────────
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceScale;

  // ── Glow pulse ─────────────────────────────────────────────────────────────
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowOpacity;

  // ── Confetti burst ─────────────────────────────────────────────────────────
  late final AnimationController _confettiCtrl;
  late List<_ConfettiParticle> _particles;

  // ── Urgency shake ──────────────────────────────────────────────────────────
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeDx;

  final math.Random _rng = math.Random();

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Breathing – subtle 0.97‥1.03 oscillation every 3 s
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _breathScale = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
    if (widget.enableBreathing) {
      _breathCtrl.repeat(reverse: true);
    }

    // Bounce entrance – elastic out over 800 ms, plays once
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bounceScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut),
    );
    if (widget.bounceOnAppear) {
      _bounceCtrl.forward();
    } else {
      _bounceCtrl.value = 1.0;
    }

    // Glow pulse – opacity between 0.15 and 0.4 every 2 s
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowOpacity = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Confetti burst – 2 s forward
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _particles = [];

    // Urgency shake – 600 ms
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeDx = Tween<double>(begin: 0.0, end: 1.0).animate(_shakeCtrl);
  }

  @override
  void didUpdateWidget(covariant FeoAnimatedSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableBreathing != widget.enableBreathing) {
      if (widget.enableBreathing) {
        _breathCtrl.repeat(reverse: true);
      } else {
        _breathCtrl.stop();
        _breathCtrl.value = 0.5; // neutral scale
      }
    }
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _bounceCtrl.dispose();
    _glowCtrl.dispose();
    _confettiCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Triggers a celebratory confetti burst around Feo.
  void triggerCelebration() {
    _particles = List.generate(40, (_) => _ConfettiParticle(_rng, widget.size));
    _confettiCtrl.forward(from: 0.0);
  }

  /// Triggers a rapid lateral shake (urgency / error feedback).
  void triggerShake() {
    _shakeCtrl.forward(from: 0.0);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathCtrl,
        _bounceCtrl,
        _glowCtrl,
        _shakeCtrl,
        _confettiCtrl,
      ]),
      builder: (context, _) {
        // Compute composite scale
        final breathVal = widget.enableBreathing ? _breathScale.value : 1.0;
        final bounceVal = _bounceScale.value;
        final compositeScale = breathVal * bounceVal;

        // Shake dx
        final shakeOffset = _shakeCtrl.isAnimating
            ? math.sin(_shakeDx.value * math.pi * 20) *
                3.0 *
                (1.0 - _shakeDx.value)
            : 0.0;

        final mascot = Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Transform.scale(
            scale: compositeScale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(_glowOpacity.value),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: FerFitMascot(
                size: widget.size,
                mood: widget.mood,
                showName: widget.showName,
                glow: false, // we handle glow externally
                anim: FeoAnim.none, // we handle anim externally
              ),
            ),
          ),
        );

        // Confetti layer
        final confettiActive = _confettiCtrl.isAnimating ||
            _confettiCtrl.status == AnimationStatus.completed;

        if (!confettiActive || _particles.isEmpty) {
          return mascot;
        }

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            mascot,
            Positioned.fill(
              child: CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _confettiCtrl.value,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Confetti internals
// ════════════════════════════════════════════════════════════════════════════════

class _ConfettiParticle {
  final double angle; // radians
  final double speed; // px per unit progress
  final double rotationSpeed;
  final Color color;
  final double radius;

  _ConfettiParticle(math.Random rng, double spriteSize)
      : angle = rng.nextDouble() * math.pi * 2,
        speed = spriteSize * 0.8 + rng.nextDouble() * spriteSize * 1.2,
        rotationSpeed = rng.nextDouble() * math.pi * 4,
        color = _confettiColors[rng.nextInt(_confettiColors.length)],
        radius = 2.0 + rng.nextDouble() * 2.5;

  static const List<Color> _confettiColors = [
    AppColors.primary,
    Color(0xFF4ADE80), // light green
    Color(0xFF22C55E), // mid green
    Color(0xFFFBBF24), // gold
    Color(0xFFFDE68A), // light gold
    Colors.white,
    Color(0xFFD9F99D), // lime
  ];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final gravity = size.height * 0.6;

    for (final p in particles) {
      final t = progress;
      final dx = math.cos(p.angle) * p.speed * t;
      final dy = math.sin(p.angle) * p.speed * t + gravity * t * t;
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(cx + dx, cy + dy), p.radius * (1.0 - t * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
