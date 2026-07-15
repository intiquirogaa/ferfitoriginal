import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../services/feo_exercise_catalog.dart';
import '../theme/app_theme.dart';

/// Demo de Feo: preferencia video MP4 generado → pose JPG generada.
class FeoExerciseDemo extends StatefulWidget {
  final FeoExerciseDemoInfo info;
  final double height;

  const FeoExerciseDemo({
    super.key,
    required this.info,
    this.height = 220,
  });

  @override
  State<FeoExerciseDemo> createState() => _FeoExerciseDemoState();
}

class _FeoExerciseDemoState extends State<FeoExerciseDemo> {
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant FeoExerciseDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.info.videoAsset != widget.info.videoAsset ||
        oldWidget.info.poseAsset != widget.info.poseAsset) {
      _disposeVideo();
      _videoReady = false;
      _videoFailed = false;
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final path = widget.info.videoAsset;
    if (path == null) return;
    try {
      final c = VideoPlayerController.asset(path);
      _video = c;
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (!mounted) return;
      setState(() => _videoReady = true);
    } catch (_) {
      await _disposeVideo();
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  Future<void> _disposeVideo() async {
    final c = _video;
    _video = null;
    if (c != null) {
      await c.pause();
      await c.dispose();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final showVideo = _videoReady && _video != null && !_videoFailed;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showVideo)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _video!.value.size.width,
                height: _video!.value.size.height,
                child: VideoPlayer(_video!),
              ),
            )
          else
            Image.asset(
              info.poseAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(Icons.image_not_supported, color: Colors.grey[600], size: 40),
              ),
            ),
          // gradient legible para labels
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 28, 12, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.55)),
                        ),
                        child: Text(
                          showVideo ? 'FEO VIDEO' : 'FEO DEMO',
                          style: GoogleFonts.rajdhani(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          info.titleEs,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.cue,
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[300]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
