import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [NEW] Para HapticFeedback
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'ferfit_mascot.dart';
import 'feo_animated_sprite.dart'; // [NEW] Para el sprite animado

enum FeoCelebrationLevel {
  /// Una serie completada (toast no bloqueante)
  series,
  /// Todo un ejercicio (overlay)
  exercise,
  /// Todo el día (overlay)
  day,
}

/// Feo celebra al completar series / ejercicio / día.
class FeoCelebration {
  FeoCelebration._();

  static Future<void> show(
    BuildContext context, {
    required FeoCelebrationLevel level,
    String? exerciseName,
    int? xpHint,
  }) async {
    if (!context.mounted) return;

    if (level == FeoCelebrationLevel.series) {
      _showSeriesToast(context, xpHint: xpHint);
      return;
    }

    final config = _configFor(level, exerciseName, xpHint);

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Feo celebra',
      barrierColor: Colors.black.withOpacity(0.72),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim, secondary) {
        return SafeArea(
          child: Center(
            child: _FeoCelebrationCard(
              title: config.title,
              body: config.body,
              mood: config.mood,
              anim: config.anim,
              accent: config.accent,
              autoCloseMs: config.autoCloseMs,
              onClose: () {
                if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
              },
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, secondary, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }

  /// Toast inferior con Feo: no bloquea el entrenamiento.
  static void _showSeriesToast(BuildContext context, {int? xpHint}) {
    HapticFeedback.mediumImpact(); // [NEW] Haptic feedback
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardSolid,
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
        ),
        duration: const Duration(milliseconds: 1400),
        content: Row(
          children: [
            const FeoAnimatedSprite( // [NEW] Usando sprite animado
              size: 44,
              mood: FerFitMascotMood.happy,
              enableBreathing: false,
              bounceOnAppear: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Feo anota la serie!',
                    style: GoogleFonts.rajdhani(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    xpHint != null ? '+$xpHint XP · seguí así' : '¡Seguí así!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
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

  static _FeoConfig _configFor(
    FeoCelebrationLevel level,
    String? exerciseName,
    int? xpHint,
  ) {
    switch (level) {
      case FeoCelebrationLevel.series:
        return _FeoConfig(
          title: '¡Bien ahí!',
          body: 'Feo suma la serie.',
          mood: FerFitMascotMood.happy,
          anim: FeoAnim.celebrate,
          accent: AppColors.primary,
          autoCloseMs: 1600,
        );
      case FeoCelebrationLevel.exercise:
        final name = exerciseName?.trim().isNotEmpty == true
            ? exerciseName!
            : 'el ejercicio';
        return _FeoConfig(
          title: '¡Ejercicio listo!',
          body: 'Feo celebra: completaste $name. ¡Imparable!',
          mood: FerFitMascotMood.goal,
          anim: FeoAnim.celebrate,
          accent: const Color(0xFFFBBF24),
          autoCloseMs: 2200,
        );
      case FeoCelebrationLevel.day:
        return _FeoConfig(
          title: '¡Día completado!',
          body: 'Feo está en llamas 🔥 Racha y XP a full. Mañana te espera.',
          mood: FerFitMascotMood.streak,
          anim: FeoAnim.pulse,
          accent: const Color(0xFFF97316),
          autoCloseMs: 2800,
        );
    }
  }
}

class _FeoConfig {
  final String title;
  final String body;
  final FerFitMascotMood mood;
  final FeoAnim anim;
  final Color accent;
  final int autoCloseMs;

  _FeoConfig({
    required this.title,
    required this.body,
    required this.mood,
    required this.anim,
    required this.accent,
    required this.autoCloseMs,
  });
}

class _FeoCelebrationCard extends StatefulWidget {
  final String title;
  final String body;
  final FerFitMascotMood mood;
  final FeoAnim anim;
  final Color accent;
  final int autoCloseMs;
  final VoidCallback onClose;

  const _FeoCelebrationCard({
    required this.title,
    required this.body,
    required this.mood,
    required this.anim,
    required this.accent,
    required this.autoCloseMs,
    required this.onClose,
  });

  @override
  State<_FeoCelebrationCard> createState() => _FeoCelebrationCardState();
}

class _FeoCelebrationCardState extends State<_FeoCelebrationCard> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.autoCloseMs), () {
      if (mounted) widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        decoration: BoxDecoration(
          color: AppColors.cardSolid,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: widget.accent.withOpacity(0.45), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: widget.accent.withOpacity(0.25),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FerFitMascot(
              size: 120,
              mood: widget.mood,
              anim: widget.anim,
              showName: true,
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.body,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.75),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: widget.onClose,
              child: Text(
                'Seguir',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: widget.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
