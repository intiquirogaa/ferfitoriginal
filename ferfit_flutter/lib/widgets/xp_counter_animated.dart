
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Animated XP display with count-up animation, progress bar, shimmer, and flying +XP text.
class XpCounterAnimated extends StatefulWidget {
  final int currentXP;
  final int level;
  final int xpForNextLevel;
  final bool showLevel;
  final bool compact;

  const XpCounterAnimated({
    super.key,
    required this.currentXP,
    required this.level,
    this.xpForNextLevel = 500,
    this.showLevel = true,
    this.compact = false,
  });

  @override
  State<XpCounterAnimated> createState() => _XpCounterAnimatedState();
}

class _XpCounterAnimatedState extends State<XpCounterAnimated> with TickerProviderStateMixin {
  late int _displayXP;
  int _xpDiff = 0;
  
  late AnimationController _countController;
  late Animation<int> _countAnimation;
  
  late AnimationController _shimmerController;
  late AnimationController _flyingTextController;

  @override
  void initState() {
    super.initState();
    _displayXP = widget.currentXP;

    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _countAnimation = IntTween(begin: _displayXP, end: _displayXP).animate(
      CurvedAnimation(parent: _countController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _displayXP = _countAnimation.value;
        });
      });

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _flyingTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didUpdateWidget(covariant XpCounterAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentXP != oldWidget.currentXP) {
      _xpDiff = widget.currentXP - oldWidget.currentXP;
      
      _countAnimation = IntTween(
        begin: _displayXP,
        end: widget.currentXP,
      ).animate(
        CurvedAnimation(parent: _countController, curve: Curves.easeOutCubic),
      );
      
      _countController.forward(from: 0);
      
      if (_xpDiff > 0) {
        _flyingTextController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    _shimmerController.dispose();
    _flyingTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_displayXP % widget.xpForNextLevel) / widget.xpForNextLevel;
    final bool isCounting = _countController.isAnimating;

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardSolid,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          boxShadow: isCounting
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, spreadRadius: 1)]
              : [],
        ),
        child: Text(
          'Nv.${widget.level} · $_displayXP XP',
          style: GoogleFonts.rajdhani(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.showLevel) ...[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardSolid,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Text(
                  '${widget.level}',
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    boxShadow: isCounting
                        ? [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 16, spreadRadius: 2)]
                        : [],
                  ),
                  child: Text(
                    '$_displayXP XP',
                    style: GoogleFonts.rajdhani(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    height: 6,
                    width: 120, // Fixed width for progress bar
                    color: AppColors.cardSolid,
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 120 * progress,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, Color(0xFF4ADE80)],
                            ),
                          ),
                        ),
                        // Shimmer overlay
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                -40 + (_shimmerController.value * (120 + 80)),
                                0,
                              ),
                              child: Container(
                                width: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Flying +XP Text
        if (_xpDiff > 0)
          Positioned(
            right: 0,
            top: 0,
            child: AnimatedBuilder(
              animation: _flyingTextController,
              builder: (context, child) {
                final t = _flyingTextController.value;
                if (t == 0.0 || t == 1.0) return const SizedBox.shrink();
                
                final dy = -30 * Curves.easeOutCubic.transform(t);
                final opacity = 1.0 - Curves.easeIn.transform(t);
                
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Opacity(
                    opacity: opacity,
                    child: Text(
                      '+$_xpDiff XP',
                      style: GoogleFonts.rajdhani(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFBBF24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
