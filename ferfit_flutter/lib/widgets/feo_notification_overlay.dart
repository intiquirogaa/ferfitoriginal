import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'ferfit_mascot.dart';

/// Overlay flotante de notificación con Feo que se desliza desde arriba.
///
/// Solo se muestra una notificación a la vez. Si se invoca [show] mientras
/// otra está visible, la anterior se remueve antes de mostrar la nueva.
class FeoNotificationOverlay {
  FeoNotificationOverlay._();

  static OverlayEntry? _currentEntry;

  /// Muestra una notificación flotante con Feo.
  ///
  /// [title] — título principal (Rajdhani bold).
  /// [body] — texto descriptivo (Inter).
  /// [type] — tipo de alerta para color de acento y mood de Feo.
  /// [cta] — texto del botón CTA (si es `null`, no se muestra).
  /// [onCta] — callback al tocar el CTA.
  /// [onDismiss] — callback al cerrar la notificación.
  /// [autoDismissMs] — ms antes de cerrar automáticamente (default 5000).
  static void show(
    BuildContext context, {
    required String title,
    required String body,
    String? type,
    String? cta,
    VoidCallback? onCta,
    VoidCallback? onDismiss,
    int autoDismissMs = 5000,
  }) {
    // Remover notificación previa si existe
    _dismiss();

    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FeoNotificationCard(
        title: title,
        body: body,
        type: type,
        cta: cta,
        onCta: onCta,
        autoDismissMs: autoDismissMs,
        onDismiss: () {
          _removeEntry(entry);
          onDismiss?.call();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void _dismiss() {
    final entry = _currentEntry;
    if (entry != null) {
      _removeEntry(entry);
    }
  }

  static void _removeEntry(OverlayEntry entry) {
    if (_currentEntry == entry) {
      _currentEntry = null;
    }
    try {
      entry.remove();
    } catch (_) {
      // Ya fue removido
    }
  }

  /// Color de acento según el tipo de alerta.
  static Color accentFor(String? type) {
    switch (type) {
      case 'missed_you':
        return const Color(0xFFF472B6); // rosa
      case 'streak_at_risk':
      case 'keep_streak':
        return const Color(0xFFF97316); // naranja
      case 'close_to_level':
      case 'close_to_streak_goal':
        return const Color(0xFFFBBF24); // dorado
      case 'no_plan':
        return AppColors.secondary; // violeta
      default:
        return AppColors.primary; // verde
    }
  }
}

// ---------------------------------------------------------------------------
// Widget interno: tarjeta animada de la notificación
// ---------------------------------------------------------------------------

class _FeoNotificationCard extends StatefulWidget {
  final String title;
  final String body;
  final String? type;
  final String? cta;
  final VoidCallback? onCta;
  final int autoDismissMs;
  final VoidCallback onDismiss;

  const _FeoNotificationCard({
    required this.title,
    required this.body,
    required this.type,
    required this.cta,
    required this.onCta,
    required this.autoDismissMs,
    required this.onDismiss,
  });

  @override
  State<_FeoNotificationCard> createState() => _FeoNotificationCardState();
}

class _FeoNotificationCardState extends State<_FeoNotificationCard>
    with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  late final AnimationController _progressController;

  bool _dismissed = false;
  double _dragDy = 0;

  @override
  void initState() {
    super.initState();

    // --- Entrada: slide desde arriba + fade ---
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideController.forward();

    // --- Barra de progreso (timer) ---
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.autoDismissMs),
    );

    _progressController.forward();
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_dismissed) {
        _animateDismiss();
      }
    });
  }

  Future<void> _animateDismiss() async {
    if (_dismissed) return;
    _dismissed = true;

    // Animación de salida: slide hacia arriba + fade
    await _slideController.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_dismissed) return;
    setState(() {
      _dragDy += details.delta.dy;
      // Solo permitir arrastrar hacia arriba
      if (_dragDy > 0) _dragDy = 0;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dismissed) return;
    if (_dragDy < -50) {
      _animateDismiss();
    } else {
      setState(() => _dragDy = 0);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = FeoNotificationOverlay.accentFor(widget.type);
    final mood = FerFitMascot.moodFromAlertType(widget.type);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _dragDy),
            child: SafeArea(
              bottom: false,
              child: GestureDetector(
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Material(
                    color: Colors.transparent,
                    child: _buildCard(accent, mood),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Color accent, FerFitMascotMood mood) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSolid,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: accent, width: 3),
          top: BorderSide(color: accent.withOpacity(0.15)),
          right: BorderSide(color: accent.withOpacity(0.15)),
          bottom: BorderSide(color: accent.withOpacity(0.15)),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contenido principal
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feo
                FerFitMascot(
                  size: 48,
                  mood: mood,
                  anim: FerFitMascot.animFromMood(mood),
                  glow: false,
                ),
                const SizedBox(width: 12),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.rajdhani(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.body,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // CTA
                      if (widget.cta != null) ...[
                        const SizedBox(height: 10),
                        _buildCtaButton(accent),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Barra de progreso
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, _) {
              return Container(
                height: 2,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 1.0 - _progressController.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.4)],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton(Color accent) {
    return GestureDetector(
      onTap: () {
        widget.onCta?.call();
        _animateDismiss();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.5), width: 1),
        ),
        child: Text(
          widget.cta!,
          style: GoogleFonts.rajdhani(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ),
    );
  }
}
