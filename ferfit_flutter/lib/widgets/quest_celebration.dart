import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'ferfit_mascot.dart';
import 'dart:math' as math;

class QuestCelebration extends StatefulWidget {
  final int coinsEarned;
  final VoidCallback onFinished;

  const QuestCelebration({
    super.key,
    required this.coinsEarned,
    required this.onFinished,
  });

  static void show(BuildContext context, {required int coinsEarned}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return QuestCelebration(
          coinsEarned: coinsEarned,
          onFinished: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  @override
  State<QuestCelebration> createState() => _QuestCelebrationState();
}

class _QuestCelebrationState extends State<QuestCelebration> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.elasticOut)));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.5, curve: Curves.easeIn)));
    
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) widget.onFinished();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FerFitMascot(
                      size: 120,
                      anim: FeoAnim.celebrate,
                      mood: FerFitMascotMood.goal,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '¡MISIÓN COMPLETADA!',
                      style: GoogleFonts.rajdhani(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: AppColors.primary, blurRadius: 20),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          '+${widget.coinsEarned} FerCoins',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
