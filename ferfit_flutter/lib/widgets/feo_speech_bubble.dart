import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Animated speech bubble that appears with slide-in + typewriter text.
///
/// Designed to sit next to Feo in a Row or Stack. The triangular tail
/// points left toward the mascot.
class FeoSpeechBubble extends StatefulWidget {
  /// The message to display with typewriter animation.
  final String message;

  /// How long the bubble stays visible after the typewriter finishes.
  final Duration duration;

  /// Optional callback for the CTA button.
  final VoidCallback? onCta;

  /// Text label for the CTA pill button.
  final String? ctaText;

  /// Called when the bubble finishes its dismiss animation.
  final VoidCallback? onDismissed;

  const FeoSpeechBubble({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 4),
    this.onCta,
    this.ctaText,
    this.onDismissed,
  });

  @override
  State<FeoSpeechBubble> createState() => _FeoSpeechBubbleState();
}

class _FeoSpeechBubbleState extends State<FeoSpeechBubble>
    with TickerProviderStateMixin {
  // ── Slide-in / fade ────────────────────────────────────────────────────────
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideOffset;
  late final Animation<double> _fadeIn;

  // ── Typewriter ─────────────────────────────────────────────────────────────
  late final AnimationController _typeCtrl;
  late final Animation<int> _charCount;

  // ── Dismiss fade-out ───────────────────────────────────────────────────────
  late final AnimationController _dismissCtrl;
  late final Animation<double> _dismissOpacity;

  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    // Slide-in from bottom with fade (300 ms)
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideOffset = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic),
    );

    // Typewriter – 35 ms per character
    final totalChars = widget.message.length;
    final typewriterDuration = Duration(milliseconds: totalChars * 35);
    _typeCtrl = AnimationController(
      vsync: this,
      duration: typewriterDuration,
    );
    _charCount = IntTween(begin: 0, end: totalChars).animate(_typeCtrl);

    // Dismiss fade-out (300 ms)
    _dismissCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dismissOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _dismissCtrl, curve: Curves.easeIn),
    );
    _dismissCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismissed?.call();
      }
    });

    // Chain: slide-in → typewriter → wait → dismiss
    _slideCtrl.forward().then((_) {
      _typeCtrl.forward().then((_) {
        Future.delayed(widget.duration, () {
          if (mounted && !_dismissed) {
            _dismissed = true;
            _dismissCtrl.forward();
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _typeCtrl.dispose();
    _dismissCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideCtrl, _typeCtrl, _dismissCtrl]),
      builder: (context, _) {
        return FadeTransition(
          opacity: _dismissCtrl.isAnimating || _dismissCtrl.isCompleted
              ? _dismissOpacity
              : _fadeIn,
          child: SlideTransition(
            position: _slideOffset,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Triangular tail pointing left toward Feo
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: CustomPaint(
                    size: const Size(10, 16),
                    painter: _TailPainter(),
                  ),
                ),
                // Bubble body
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardSolid.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.message.substring(0, _charCount.value),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.foreground.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                        if (widget.ctaText != null && widget.onCta != null) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: widget.onCta,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.ctaText!,
                                style: GoogleFonts.rajdhani(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Paints the small triangular tail that points left toward Feo.
class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cardSolid.withOpacity(0.92)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0) // top-right
      ..lineTo(0, size.height * 0.5) // left tip
      ..lineTo(size.width, size.height) // bottom-right
      ..close();

    canvas.drawPath(path, paint);

    // Border stroke on the tail edges
    final borderPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final borderPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height * 0.5)
      ..lineTo(size.width, size.height);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => false;
}
