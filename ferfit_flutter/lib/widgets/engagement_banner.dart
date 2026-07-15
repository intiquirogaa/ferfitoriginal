import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'ferfit_mascot.dart';
import 'feo_animated_sprite.dart'; // [NEW] Use animated sprite

/// Banner in-app con Feo animado y transiciones de entrada/salida.
class EngagementBanner extends StatefulWidget {
  final Map<String, dynamic> alert;
  final VoidCallback? onCta;
  final VoidCallback? onDismiss;

  const EngagementBanner({
    super.key,
    required this.alert,
    this.onCta,
    this.onDismiss,
  });

  @override
  State<EngagementBanner> createState() => _EngagementBannerState();
}

class _EngagementBannerState extends State<EngagementBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _controller.forward();
  }

  void _handleDismiss() async {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);
    
    // Animate out (swipe physics)
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0), // Slide to right
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInCubic,
    ));
    
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _accentForType(String type) {
    switch (type) {
      case 'missed_you':
        return const Color(0xFFF472B6);
      case 'streak_at_risk':
      case 'keep_streak':
        return const Color(0xFFF97316);
      case 'close_to_level':
      case 'close_to_streak_goal':
        return const Color(0xFFFBBF24);
      case 'no_plan':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.alert['type']?.toString() ?? '';
    final title = widget.alert['title']?.toString() ?? 'Feo te espera';
    final body = widget.alert['body']?.toString() ?? '';
    final cta = widget.alert['cta']?.toString() ?? 'Abrir';
    final dismissible = widget.alert['dismissible'] != false;
    final accent = _accentForType(type);
    final mood = FerFitMascot.moodFromAlertType(type);
    final isUrgent = type == 'streak_at_risk';

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                accent.withOpacity(0.22),
                AppColors.cardSolid.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: accent.withOpacity(0.45), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.15),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    // [NEW] Usando el sprite animado avanzado
                    FeoAnimatedSprite(
                      size: 76, 
                      mood: mood,
                      enableBreathing: true,
                      bounceOnAppear: false, // Ya hacemos bounce en el contenedor
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kMascotName,
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.rajdhani(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.78),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: accent,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: widget.onCta,
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              cta,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (dismissible)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _handleDismiss,
                    icon: Icon(Icons.close, size: 18, color: Colors.white.withOpacity(0.55)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

