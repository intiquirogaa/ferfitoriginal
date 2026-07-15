import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Nombre oficial de la mascota de FerFit.
const String kMascotName = 'Feo';

/// Estados de humor de Feo (rayo vivo del logo).
enum FerFitMascotMood {
  happy,
  missYou,
  streak,
  goal,
  idle,
}

/// Tipo de animación en pantalla.
enum FeoAnim {
  /// Flota suave (default / idle)
  float,
  /// Saludo con balanceo (login, bienvenida)
  wave,
  /// Triste, cabeceo lento
  sad,
  /// Racha: vibra con energía
  pulse,
  /// Objetivo: pop de celebración
  celebrate,
  /// Sin animación
  none,
}

/// Feo — mascota de FerFit (rayo verde antropomorfo).
/// Assets en `assets/mascot/`.
class FerFitMascot extends StatelessWidget {
  final double size;
  final bool glow;
  final FerFitMascotMood mood;
  final FeoAnim anim;
  final bool showName;
  final String? equippedSkin;

  const FerFitMascot({
    super.key,
    this.size = 56,
    this.glow = true,
    this.mood = FerFitMascotMood.happy,
    this.anim = FeoAnim.float,
    this.showName = false,
    this.equippedSkin,
  });

  /// Alias semántico: Feo animado.
  const FerFitMascot.feo({
    super.key,
    this.size = 56,
    this.glow = true,
    this.mood = FerFitMascotMood.happy,
    this.anim = FeoAnim.float,
    this.showName = false,
    this.equippedSkin,
  });

  static const assetHappy = 'assets/mascot/mascot_happy.jpg';
  static const assetMissYou = 'assets/mascot/mascot_miss_you.jpg';
  static const assetStreak = 'assets/mascot/mascot_streak.jpg';
  static const assetGoal = 'assets/mascot/mascot_goal.jpg';
  static const assetIdle = 'assets/mascot/mascot_idle.jpg';
  static const assetDefault = 'assets/mascot/ferfit_mascot.jpg';

  static FerFitMascotMood moodFromAlertType(String? type) {
    switch (type) {
      case 'missed_you':
        return FerFitMascotMood.missYou;
      case 'streak_at_risk':
      case 'keep_streak':
        return FerFitMascotMood.streak;
      case 'close_to_level':
      case 'close_to_streak_goal':
        return FerFitMascotMood.goal;
      case 'no_plan':
      case 'daily_nudge':
        return FerFitMascotMood.idle;
      default:
        return FerFitMascotMood.happy;
    }
  }

  static FeoAnim animFromMood(FerFitMascotMood mood) {
    switch (mood) {
      case FerFitMascotMood.missYou:
        return FeoAnim.sad;
      case FerFitMascotMood.streak:
        return FeoAnim.pulse;
      case FerFitMascotMood.goal:
        return FeoAnim.celebrate;
      case FerFitMascotMood.idle:
        return FeoAnim.wave;
      case FerFitMascotMood.happy:
        return FeoAnim.float;
    }
  }

  static String assetForMood(FerFitMascotMood mood) {
    switch (mood) {
      case FerFitMascotMood.happy:
        return assetHappy;
      case FerFitMascotMood.missYou:
        return assetMissYou;
      case FerFitMascotMood.streak:
        return assetStreak;
      case FerFitMascotMood.goal:
        return assetGoal;
      case FerFitMascotMood.idle:
        return assetIdle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAnim = anim == FeoAnim.float && mood != FerFitMascotMood.happy
        ? animFromMood(mood)
        : anim;

    final child = _FeoAnimated(
      size: size,
      glow: glow,
      mood: mood,
      anim: effectiveAnim,
      equippedSkin: equippedSkin,
    );

    if (!showName) return child;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 6),
        Text(
          kMascotName,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.18,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _FeoAnimated extends StatefulWidget {
  final double size;
  final bool glow;
  final FerFitMascotMood mood;
  final FeoAnim anim;
  final String? equippedSkin;

  const _FeoAnimated({
    required this.size,
    required this.glow,
    required this.mood,
    required this.anim,
    this.equippedSkin,
  });

  @override
  State<_FeoAnimated> createState() => _FeoAnimatedState();
}

class _FeoAnimatedState extends State<_FeoAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.anim),
    );
    if (widget.anim != FeoAnim.none) {
      _controller.repeat(reverse: widget.anim != FeoAnim.celebrate);
      if (widget.anim == FeoAnim.celebrate) {
        _controller.forward();
      }
    }
  }

  @override
  void didUpdateWidget(covariant _FeoAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anim != widget.anim || oldWidget.mood != widget.mood) {
      _controller.duration = _durationFor(widget.anim);
      _controller.reset();
      if (widget.anim == FeoAnim.none) {
        _controller.stop();
      } else if (widget.anim == FeoAnim.celebrate) {
        _controller.forward(from: 0);
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  Duration _durationFor(FeoAnim anim) {
    switch (anim) {
      case FeoAnim.float:
        return const Duration(milliseconds: 1800);
      case FeoAnim.wave:
        return const Duration(milliseconds: 1400);
      case FeoAnim.sad:
        return const Duration(milliseconds: 2200);
      case FeoAnim.pulse:
        return const Duration(milliseconds: 500);
      case FeoAnim.celebrate:
        return const Duration(milliseconds: 900);
      case FeoAnim.none:
        return const Duration(milliseconds: 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = FerFitMascot.assetForMood(widget.mood);

    final image = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0A0A0C),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
        boxShadow: widget.glow
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.28),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        semanticLabel: kMascotName,
        errorBuilder: (_, __, ___) => Image.asset(
          FerFitMascot.assetDefault,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.bolt,
            color: AppColors.primary,
            size: widget.size * 0.45,
          ),
        ),
      ),
    );

    Widget mascotWithSkin = image;
    
    if (widget.equippedSkin != null) {
      Widget? skinWidget;
      if (widget.equippedSkin == 'skin_headband') {
        skinWidget = Container(
          width: widget.size * 0.7,
          height: widget.size * 0.12,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.9),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      } else if (widget.equippedSkin == 'skin_sunglasses') {
        skinWidget = Text('😎', style: TextStyle(fontSize: widget.size * 0.45));
      } else if (widget.equippedSkin == 'skin_cap') {
        skinWidget = Text('🧢', style: TextStyle(fontSize: widget.size * 0.45));
      }

      if (skinWidget != null) {
        mascotWithSkin = Stack(
          alignment: Alignment.center,
          children: [
            image,
            Positioned(
              top: widget.size * 0.15,
              child: skinWidget,
            ),
          ],
        );
      }
    }

    if (widget.anim == FeoAnim.none) return mascotWithSkin;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        switch (widget.anim) {
          case FeoAnim.float:
            final dy = math.sin(t * math.pi * 2) * 5;
            return Transform.translate(offset: Offset(0, dy), child: child);
          case FeoAnim.wave:
            final dy = math.sin(t * math.pi * 2) * 4;
            final rot = math.sin(t * math.pi * 2) * 0.06;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.rotate(angle: rot, child: child),
            );
          case FeoAnim.sad:
            final dy = math.sin(t * math.pi * 2) * 3;
            final rot = -0.05 + math.sin(t * math.pi * 2) * 0.03;
            return Transform.translate(
              offset: Offset(0, dy + 2),
              child: Transform.rotate(angle: rot, child: child),
            );
          case FeoAnim.pulse:
            final scale = 1.0 + math.sin(t * math.pi * 2) * 0.06;
            final dx = math.sin(t * math.pi * 8) * 1.5;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.scale(scale: scale, child: child),
            );
          case FeoAnim.celebrate:
            final scale = 0.85 + Curves.elasticOut.transform(t.clamp(0.0, 1.0)) * 0.2;
            final rot = math.sin(t * math.pi * 3) * 0.08 * (1 - t);
            return Transform.rotate(
              angle: rot,
              child: Transform.scale(scale: scale, child: child),
            );
          case FeoAnim.none:
            return child!;
        }
      },
      child: mascotWithSkin,
    );
  }
}
