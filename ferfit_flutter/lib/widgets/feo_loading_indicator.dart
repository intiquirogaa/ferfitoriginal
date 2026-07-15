import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'ferfit_mascot.dart';

/// Custom loading indicator featuring the Feo mascot.
///
/// Shows Feo in the center with a pulsing green glow ring,
/// orbiting dots, cycling moods, and motivational messages.
/// Optionally shows a determinate progress arc.
class FeoLoadingIndicator extends StatefulWidget {
  final double size;

  /// Override the default cycling messages with a single message.
  final String? message;

  /// If provided (0.0–1.0), renders a determinate arc instead of orbiting dots.
  final double? progress;

  /// Whether to show the motivational text below the indicator.
  final bool showText;

  const FeoLoadingIndicator({
    super.key,
    this.size = 80,
    this.message,
    this.progress,
    this.showText = true,
  });

  @override
  State<FeoLoadingIndicator> createState() => _FeoLoadingIndicatorState();
}

class _FeoLoadingIndicatorState extends State<FeoLoadingIndicator>
    with TickerProviderStateMixin {
  // ── Orbit / arc rotation ───────────────────────────────────────────────────
  late final AnimationController _orbitCtrl;

  // ── Glow pulse ─────────────────────────────────────────────────────────────
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowValue;

  // ── Mood cycling ───────────────────────────────────────────────────────────
  Timer? _moodTimer;
  int _moodIndex = 0;

  static const List<FerFitMascotMood> _moods = [
    FerFitMascotMood.happy,
    FerFitMascotMood.streak,
    FerFitMascotMood.goal,
    FerFitMascotMood.idle,
    FerFitMascotMood.missYou,
  ];

  // ── Motivational messages ──────────────────────────────────────────────────
  Timer? _msgTimer;
  int _msgIndex = 0;

  static const List<String> _defaultMessages = [
    'Feo prepara tu rutina...',
    'Cargando tu progreso...',
    'Un momento, campeón...',
    'Feo calcula tu plan...',
  ];

  @override
  void initState() {
    super.initState();

    // Orbit rotation – continuous 1.5 s loop
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Glow pulse – 2 s loop
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowValue = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Mood cycling – every 2.5 s
    _moodTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        setState(() {
          _moodIndex = (_moodIndex + 1) % _moods.length;
        });
      }
    });

    // Message cycling – every 3 s
    _msgTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _msgIndex = (_msgIndex + 1) % _defaultMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _glowCtrl.dispose();
    _moodTimer?.cancel();
    _msgTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSize = widget.size * 2.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: totalSize,
          height: totalSize,
          child: AnimatedBuilder(
            animation: Listenable.merge([_orbitCtrl, _glowCtrl]),
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Glow ring
                  CustomPaint(
                    size: Size(totalSize, totalSize),
                    painter: _GlowRingPainter(
                      glowOpacity: _glowValue.value,
                      mascotSize: widget.size,
                    ),
                  ),

                  // Orbiting dots or progress arc
                  if (widget.progress != null)
                    CustomPaint(
                      size: Size(totalSize, totalSize),
                      painter: _ProgressArcPainter(
                        progress: widget.progress!.clamp(0.0, 1.0),
                        mascotSize: widget.size,
                      ),
                    )
                  else
                    CustomPaint(
                      size: Size(totalSize, totalSize),
                      painter: _OrbitDotsPainter(
                        rotation: _orbitCtrl.value * math.pi * 2,
                        mascotSize: widget.size,
                      ),
                    ),

                  // Feo mascot in center with mood crossfade
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: FerFitMascot(
                      key: ValueKey<int>(_moodIndex),
                      size: widget.size,
                      mood: _moods[_moodIndex],
                      anim: FeoAnim.none,
                      glow: false,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Motivational messages
        if (widget.showText) ...[
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: Text(
              widget.message ?? _defaultMessages[_msgIndex],
              key: ValueKey<String>(
                widget.message ?? _defaultMessages[_msgIndex],
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Custom painters
// ════════════════════════════════════════════════════════════════════════════════

/// Pulsing green glow ring around Feo.
class _GlowRingPainter extends CustomPainter {
  final double glowOpacity;
  final double mascotSize;

  _GlowRingPainter({required this.glowOpacity, required this.mascotSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = mascotSize / 2 + 10;

    final paint = Paint()
      ..color = AppColors.primary.withOpacity(glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center, radius, paint);

    // Sharper inner ring
    final innerPaint = Paint()
      ..color = AppColors.primary.withOpacity(glowOpacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, innerPaint);
  }

  @override
  bool shouldRepaint(_GlowRingPainter oldDelegate) =>
      oldDelegate.glowOpacity != glowOpacity;
}

/// Three small green dots orbiting around Feo, 120° apart.
class _OrbitDotsPainter extends CustomPainter {
  final double rotation;
  final double mascotSize;

  _OrbitDotsPainter({required this.rotation, required this.mascotSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orbitRadius = mascotSize / 2 + 16;
    const dotRadius = 4.0;
    const dotCount = 3;

    for (int i = 0; i < dotCount; i++) {
      final angle = rotation + (i * math.pi * 2 / dotCount);
      final dx = center.dx + math.cos(angle) * orbitRadius;
      final dy = center.dy + math.sin(angle) * orbitRadius;

      // Subtle size variation based on position
      final scale = 0.7 + 0.3 * ((math.sin(angle) + 1) / 2);

      final paint = Paint()
        ..color = AppColors.primary.withOpacity(0.6 + 0.4 * scale)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), dotRadius * scale, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbitDotsPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

/// Determinate progress arc rendered when [progress] is provided.
class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final double mascotSize;

  _ProgressArcPainter({required this.progress, required this.mascotSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = mascotSize / 2 + 14;

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final arcPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final sweepAngle = progress * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start from top
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
