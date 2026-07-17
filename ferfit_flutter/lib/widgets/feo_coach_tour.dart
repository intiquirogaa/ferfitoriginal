import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../onboarding/coach_tour_steps.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';

/// Tour estilo Duolingo: Feo habla y señala un componente con spotlight.
class FeoCoachTour extends StatefulWidget {
  final void Function(int tabIndex) onSwitchTab;
  final VoidCallback onFinished;

  const FeoCoachTour({
    super.key,
    required this.onSwitchTab,
    required this.onFinished,
  });

  @override
  State<FeoCoachTour> createState() => _FeoCoachTourState();
}

class _FeoCoachTourState extends State<FeoCoachTour>
    with SingleTickerProviderStateMixin {
  late final List<CoachTourStep> _steps;
  int _index = 0;
  Rect? _hole;
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _steps = buildFeoCoachTourSteps();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _prepareStep(0);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  Future<void> _prepareStep(int i) async {
    if (i < 0 || i >= _steps.length) return;
    final step = _steps[i];
    await OnboardingService.instance.saveStep(i);

    if (step.tabIndex != null) {
      widget.onSwitchTab(step.tabIndex!);
      // Esperar a que el tab y los keys se monten
      await Future<void>.delayed(const Duration(milliseconds: 280));
    }

    if (!mounted) return;
    setState(() {
      _index = i;
      _hole = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 50));
    _measureHole();
    // Reintentos por si el widget aún no tenía tamaño
    for (var attempt = 0; attempt < 4; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      _measureHole();
      if (_hole != null) break;
    }
  }

  void _measureHole() {
    final step = _steps[_index];
    if (step.centerFocus || step.targetKey == null) {
      setState(() => _hole = null);
      return;
    }
    final ctx = step.targetKey!.currentContext;
    if (ctx == null) {
      setState(() => _hole = null);
      return;
    }
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      setState(() => _hole = null);
      return;
    }
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final padding = 10.0;
    setState(() {
      _hole = Rect.fromLTWH(
        offset.dx - padding,
        offset.dy - padding,
        size.width + padding * 2,
        size.height + padding * 2,
      ).inflate(4);
    });
  }

  Future<void> _next() async {
    if (_index >= _steps.length - 1) {
      await OnboardingService.instance.markTourCompleted();
      widget.onFinished();
      return;
    }
    await _prepareStep(_index + 1);
  }

  Future<void> _skip() async {
    await OnboardingService.instance.markTourCompleted();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];
    final media = MediaQuery.of(context);
    final screen = media.size;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Spotlight oscuro
          Positioned.fill(
            child: GestureDetector(
              onTap: () {}, // bloquea toques a la app
              child: CustomPaint(
                painter: _SpotlightPainter(hole: _hole),
              ),
            ),
          ),

          // Anillo del highlight
          if (_hole != null)
            Positioned(
              left: _hole!.left,
              top: _hole!.top,
              width: _hole!.width,
              height: _hole!.height,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.45),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Feo + burbuja
          _buildCoachPanel(step, screen, media.padding),
        ],
      ),
    );
  }

  Widget _buildCoachPanel(
    CoachTourStep step,
    Size screen,
    EdgeInsets safe,
  ) {
    // Posición: debajo del hole si hay espacio, si no abajo de la pantalla
    double top;
    if (_hole != null) {
      final below = _hole!.bottom + 12;
      final above = _hole!.top - 200;
      if (below + 220 < screen.height - safe.bottom) {
        top = below;
      } else if (above > safe.top + 8) {
        top = math.max(safe.top + 8, above);
      } else {
        top = screen.height - safe.bottom - 240;
      }
    } else {
      top = screen.height * 0.38;
    }

    return Positioned(
      left: 12,
      right: 12,
      top: top.clamp(safe.top + 8, screen.height - 230),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedBuilder(
                animation: _bounce,
                builder: (_, __) {
                  final dy = -6 * _bounce.value;
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: _buildFeo(step),
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildBubble(step)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: _skip,
                child: Text(
                  'Saltar intro',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_index + 1} / ${_steps.length}',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  step.nextLabel,
                  style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeo(CoachTourStep step) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 14,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            step.mascotAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.cardSolid,
              alignment: Alignment.center,
              child: const Text('⚡', style: TextStyle(fontSize: 36)),
            ),
          ),
        ),
        // “Señalando” hacia arriba si hay hole
        if (_hole != null)
          Icon(
            Icons.arrow_upward_rounded,
            color: AppColors.primary,
            size: 22,
          ),
      ],
    );
  }

  Widget _buildBubble(CoachTourStep step) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.message,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.4,
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? hole;

  _SpotlightPainter({this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    if (hole != null) {
      final r = RRect.fromRectAndRadius(hole!, const Radius.circular(16));
      final cut = Path()..addRRect(r);
      final dimmed = Path.combine(PathOperation.difference, overlay, cut);
      canvas.drawPath(
        dimmed,
        Paint()..color = Colors.black.withOpacity(0.78),
      );
    } else {
      canvas.drawPath(
        overlay,
        Paint()..color = Colors.black.withOpacity(0.78),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole;
}
