import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'ferfit_mascot.dart';

/// Diálogo dramático cuando la racha está en riesgo.
///
/// Muestra a Feo temblando con partículas de brasas ascendentes, el número de
/// racha en grande y un CTA pulsante para salvarla.
class FeoStreakFreezeDialog {
  FeoStreakFreezeDialog._();

  /// Muestra el diálogo de racha en riesgo.
  ///
  /// [streak] — cantidad de días de racha actual.
  /// [daysLeft] — días restantes antes de perder la racha.
  /// [onSave] — callback al presionar "Salvar racha".
  static Future<void> show(
    BuildContext context, {
    required int streak,
    required int daysLeft,
    required VoidCallback onSave,
  }) async {
    HapticFeedback.heavyImpact();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar diálogo de racha',
      barrierColor: Colors.black.withOpacity(0.78),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim, secondary) {
        return SafeArea(
          child: Center(
            child: _StreakFreezeCard(
              streak: streak,
              daysLeft: daysLeft,
              onSave: () {
                Navigator.of(ctx).pop();
                onSave();
              },
              onDismiss: () {
                if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
              },
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, secondary, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widget interno: tarjeta del diálogo
// ---------------------------------------------------------------------------

class _StreakFreezeCard extends StatefulWidget {
  final int streak;
  final int daysLeft;
  final VoidCallback onSave;
  final VoidCallback onDismiss;

  const _StreakFreezeCard({
    required this.streak,
    required this.daysLeft,
    required this.onSave,
    required this.onDismiss,
  });

  @override
  State<_StreakFreezeCard> createState() => _StreakFreezeCardState();
}

class _StreakFreezeCardState extends State<_StreakFreezeCard>
    with TickerProviderStateMixin {
  static const _orange = Color(0xFFF97316);
  static const _red = Color(0xFFEF4444);

  /// Shake de Feo: lateral rápido
  late final AnimationController _shakeController;

  /// Pulsación del botón CTA
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  /// Partículas (brasas)
  late final AnimationController _particlesController;
  late final List<_Ember> _embers;

  @override
  void initState() {
    super.initState();

    // Shake: oscilación lateral ±2.5px, 100ms por ciclo completo
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);

    // Pulso del CTA: 1.0 → 1.04, 800ms
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Partículas de brasas
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    final rng = math.Random();
    _embers = List.generate(18, (_) => _Ember.random(rng));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cardSolid,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _orange.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _orange.withOpacity(0.25),
              blurRadius: 32,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: _red.withOpacity(0.12),
              blurRadius: 48,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Fondo: partículas de brasas
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particlesController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _EmberPainter(
                      embers: _embers,
                      progress: _particlesController.value,
                    ),
                  );
                },
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Feo con shake
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      // Interpolar de -2.5 a +2.5
                      final dx =
                          -2.5 + (_shakeController.value * 5.0);
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: const FerFitMascot(
                      size: 90,
                      mood: FerFitMascotMood.missYou,
                      anim: FeoAnim.sad,
                      glow: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Número de racha gigante
                  Text(
                    '${widget.streak}',
                    style: GoogleFonts.rajdhani(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 🔥 racha de X días
                  Text(
                    '🔥 racha de ${widget.streak} días',
                    style: GoogleFonts.rajdhani(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _orange,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Advertencia
                  Text(
                    'Te queda${widget.daysLeft == 1 ? '' : 'n'} '
                    '${widget.daysLeft} día${widget.daysLeft == 1 ? '' : 's'} '
                    'para no perderla',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CTA: Salvar racha 💪 (pulsante)
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [_orange, _red],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _orange.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: MaterialButton(
                          onPressed: widget.onSave,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.zero,
                          child: Text(
                            'Salvar racha 💪',
                            style: GoogleFonts.rajdhani(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Después
                  TextButton(
                    onPressed: widget.onDismiss,
                    child: Text(
                      'Después',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sistema de partículas: brasas ascendentes
// ---------------------------------------------------------------------------

/// Datos de una brasa individual.
class _Ember {
  /// Posición X relativa (0.0 – 1.0)
  final double x;

  /// Desfase inicial en el ciclo de vida (0.0 – 1.0)
  final double phaseOffset;

  /// Radio de la brasa (2 – 5 px)
  final double radius;

  /// Velocidad relativa (0.5 – 1.5)
  final double speed;

  /// Color de la brasa (naranja o rojo)
  final Color color;

  /// Oscilación horizontal
  final double wobbleAmplitude;
  final double wobbleFrequency;

  const _Ember({
    required this.x,
    required this.phaseOffset,
    required this.radius,
    required this.speed,
    required this.color,
    required this.wobbleAmplitude,
    required this.wobbleFrequency,
  });

  static _Ember random(math.Random rng) {
    final colors = [
      const Color(0xFFF97316),
      const Color(0xFFEF4444),
      const Color(0xFFFBBF24),
      const Color(0xFFFF6B35),
      const Color(0xFFE8590C),
    ];
    return _Ember(
      x: rng.nextDouble(),
      phaseOffset: rng.nextDouble(),
      radius: 2.0 + rng.nextDouble() * 3.0,
      speed: 0.5 + rng.nextDouble(),
      color: colors[rng.nextInt(colors.length)],
      wobbleAmplitude: 3.0 + rng.nextDouble() * 6.0,
      wobbleFrequency: 1.0 + rng.nextDouble() * 2.0,
    );
  }
}

class _EmberPainter extends CustomPainter {
  final List<_Ember> embers;
  final double progress;

  _EmberPainter({required this.embers, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final ember in embers) {
      // Fase cíclica individual: combina progreso global + offset propio
      final t = ((progress * ember.speed) + ember.phaseOffset) % 1.0;

      // Posición Y: de abajo (1.0) hacia arriba (-0.1), ciclo completo
      final y = size.height * (1.1 - t * 1.2);

      // Posición X: base + oscilación sinusoidal
      final x = ember.x * size.width +
          math.sin(t * math.pi * 2 * ember.wobbleFrequency) *
              ember.wobbleAmplitude;

      // Opacidad: fade in al principio, fade out al final
      double opacity;
      if (t < 0.15) {
        opacity = t / 0.15;
      } else if (t > 0.75) {
        opacity = (1.0 - t) / 0.25;
      } else {
        opacity = 1.0;
      }
      opacity = opacity.clamp(0.0, 1.0) * 0.7;

      final paint = Paint()
        ..color = ember.color.withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ember.radius * 0.6);

      canvas.drawCircle(Offset(x, y), ember.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
