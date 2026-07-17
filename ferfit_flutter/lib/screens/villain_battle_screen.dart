import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_player/video_player.dart';

import '../form_check/form_check_engine.dart';
import '../form_check/form_check_models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/quest_celebration.dart';

enum _BattlePhase { intro, attack, defend, challenge, grading, result }

/// Combate animado: clip de pelea in-app + desafío filmado (reps + IA).
class VillainBattleScreen extends StatefulWidget {
  final int questId;
  final String villainId;
  final String villainName;
  final String? portraitAsset;
  final String? fightClipAsset;
  final Map<String, dynamic>? battle;
  final String? coachNote;

  const VillainBattleScreen({
    super.key,
    required this.questId,
    required this.villainId,
    required this.villainName,
    this.portraitAsset,
    this.fightClipAsset,
    this.battle,
    this.coachNote,
  });

  @override
  State<VillainBattleScreen> createState() => _VillainBattleScreenState();
}

class _VillainBattleScreenState extends State<VillainBattleScreen>
    with TickerProviderStateMixin {
  _BattlePhase _phase = _BattlePhase.intro;
  late final AnimationController _pulseCtrl;

  VideoPlayerController? _fightVideo;
  VideoPlayerController? _victoryVideo;
  bool _fightVideoReady = false;
  bool _victoryVideoReady = false;
  bool _fightClipFinished = false;

  CameraController? _camera;
  PoseDetector? _detector;
  bool _cameraReady = false;
  bool _processing = false;
  bool _challengeActive = false;
  bool _submitting = false;
  String? _cameraError;

  final _engine = const FormCheckEngine();
  final _poseFrames = <PoseFrame>[];
  FormCheckDefinition? _definition;
  int _liveReps = 0;
  int _seconds = 0;
  Timer? _timer;

  Map<String, dynamic>? _grade;
  String _narration = '';

  int get _targetReps {
    final b = widget.battle;
    if (b == null) return 20;
    return (b['targetReps'] is num) ? (b['targetReps'] as num).toInt() : 20;
  }

  String get _exerciseEs {
    final b = widget.battle;
    return b?['exerciseNameEs']?.toString() ?? 'Abdominales';
  }

  String get _exerciseEn {
    final b = widget.battle;
    return b?['exerciseNameEn']?.toString() ?? 'Crunch';
  }

  String get _portrait {
    final p = widget.portraitAsset;
    if (p != null && p.isNotEmpty) return p;
    return 'assets/villains/${widget.villainId}.jpg';
  }

  String get _fightClip {
    final c = widget.fightClipAsset;
    if (c != null && c.isNotEmpty) return c;
    return 'assets/battle/fight_${widget.villainId}.mp4';
  }

  static const _victoryClip = 'assets/battle/fight_victory.mp4';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _definition = resolveFormCheckDefinition(_exerciseEn) ??
        resolveFormCheckDefinition(_exerciseEs) ??
        resolveFormCheckDefinition('crunch');

    _narration = widget.battle?['attackLine']?.toString() ??
        '${widget.villainName} se prepara para atacar…';
    _initFightVideos();
  }

  Future<void> _initFightVideos() async {
    try {
      final fight = VideoPlayerController.asset(_fightClip);
      await fight.initialize();
      fight.setLooping(false);
      fight.setVolume(0);
      fight.addListener(_onFightVideoTick);
      if (!mounted) {
        await fight.dispose();
        return;
      }
      setState(() {
        _fightVideo = fight;
        _fightVideoReady = true;
      });
    } catch (e) {
      debugPrint('[battle] fight clip missing: $e');
    }

    try {
      final win = VideoPlayerController.asset(_victoryClip);
      await win.initialize();
      win.setLooping(true);
      win.setVolume(0);
      if (!mounted) {
        await win.dispose();
        return;
      }
      setState(() {
        _victoryVideo = win;
        _victoryVideoReady = true;
      });
    } catch (e) {
      debugPrint('[battle] victory clip missing: $e');
    }

    if (mounted) await _runCinematic();
  }

  void _onFightVideoTick() {
    final v = _fightVideo;
    if (v == null || !v.value.isInitialized) return;
    final pos = v.value.position;
    final dur = v.value.duration;
    if (dur.inMilliseconds > 0 &&
        pos >= dur - const Duration(milliseconds: 200) &&
        !_fightClipFinished) {
      _fightClipFinished = true;
      if (mounted &&
          (_phase == _BattlePhase.attack || _phase == _BattlePhase.intro)) {
        setState(() {
          _phase = _BattlePhase.defend;
          _narration = widget.battle?['defenseLine']?.toString() ??
              'Feo resiste el golpe. Completá el desafío para cerrar la defensa.';
        });
      }
    }
  }

  Future<void> _runCinematic() async {
    if (!mounted) return;
    setState(() {
      _phase = _BattlePhase.attack;
      _narration = widget.battle?['attackLine']?.toString() ??
          '${widget.villainName} lanza un ataque…';
      _fightClipFinished = false;
    });
    final v = _fightVideo;
    if (v != null && v.value.isInitialized) {
      await v.seekTo(Duration.zero);
      await v.play();
      // Safety: si el listener no dispara, pasar a defensa al terminar
      await Future.delayed(v.value.duration + const Duration(milliseconds: 300));
      if (mounted && _phase == _BattlePhase.attack) {
        setState(() {
          _phase = _BattlePhase.defend;
          _narration = widget.battle?['defenseLine']?.toString() ??
              'Feo se defiende. Completá el desafío para sostener el bloqueo.';
        });
      }
    } else {
      // Fallback sin clip
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      setState(() {
        _phase = _BattlePhase.defend;
        _narration = widget.battle?['defenseLine']?.toString() ??
            'Feo se defiende. Completá el desafío para sostener el bloqueo.';
      });
    }
  }

  Future<void> _startChallenge() async {
    if (kIsWeb) {
      setState(() => _cameraError = 'El combate con cámara no está disponible en web.');
      return;
    }
    setState(() {
      _phase = _BattlePhase.challenge;
      _challengeActive = true;
      _liveReps = 0;
      _seconds = 0;
      _poseFrames.clear();
      _narration =
          'Desafío: $_targetReps $_exerciseEs. Mantené el cuerpo a la vista.';
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('Sin cámara');
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
      );
      await controller.initialize();
      _detector = PoseDetector(
        options: PoseDetectorOptions(
          model: PoseDetectionModel.base,
          mode: PoseDetectionMode.stream,
        ),
      );
      await controller.startImageStream(_onCameraImage);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _cameraReady = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_challengeActive) return;
        setState(() => _seconds++);
      });
    } catch (e) {
      setState(() => _cameraError = 'Cámara: $e');
    }
  }

  static const _orientations = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Future<void> _onCameraImage(CameraImage image) async {
    if (_processing || !_challengeActive || _definition == null) return;
    _processing = true;
    try {
      final input = _inputImageFromCamera(image);
      if (input == null) return;
      final poses = await _detector!.processImage(input);
      if (poses.isEmpty) return;
      final pose = poses.first;
      final points = <String, BodyPoint>{
        for (final e in pose.landmarks.entries)
          e.key.name: BodyPoint(
            x: e.value.x,
            y: e.value.y,
            z: e.value.z,
            confidence: e.value.likelihood,
          ),
      };
      _poseFrames.add(PoseFrame(capturedAt: DateTime.now(), points: points));
      if (_poseFrames.length > 120) {
        _poseFrames.removeRange(0, _poseFrames.length - 120);
      }
      final result = _engine.analyze(_definition!, List.from(_poseFrames));
      if (mounted && result.repetitions != _liveReps) {
        setState(() => _liveReps = result.repetitions);
        if (_liveReps > 0 && _liveReps % 5 == 0) {
          HapticFeedback.lightImpact();
        }
      }
    } catch (_) {
      // ignore frame errors
    } finally {
      _processing = false;
    }
  }

  InputImage? _inputImageFromCamera(CameraImage image) {
    final controller = _camera;
    if (controller == null || image.planes.length != 1) return null;
    final camera = controller.description;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    } else {
      final compensation = _orientations[controller.value.deviceOrientation];
      if (compensation == null) return null;
      final value = camera.lensDirection == CameraLensDirection.front
          ? (camera.sensorOrientation + compensation) % 360
          : (camera.sensorOrientation - compensation + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(value);
    }
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (rotation == null || format == null) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: ui.Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _finishAndGrade() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _challengeActive = false;
      _phase = _BattlePhase.grading;
      _narration = 'Feo analiza tu ejecución con IA…';
    });
    _timer?.cancel();
    try {
      await _camera?.stopImageStream();
    } catch (_) {}

    // Intentar 2 fotos para la IA
    final frames = <String>[];
    try {
      final cam = _camera;
      if (cam != null && cam.value.isInitialized) {
        for (var i = 0; i < 2; i++) {
          final shot = await cam.takePicture();
          final bytes = await File(shot.path).readAsBytes();
          // Comprimir: si es grande, solo primeros ~200KB no - send full if reasonable
          if (bytes.lengthInBytes < 900000) {
            frames.add(base64Encode(bytes));
          }
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    } catch (_) {
      // sin frames: el backend usa deviceReps
    }

    final res = await ApiService.gradeBattleChallenge(
      questId: widget.questId,
      villainId: widget.villainId,
      deviceReps: _liveReps,
      durationSec: _seconds,
      framesBase64: frames,
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _grade = res;
      _phase = _BattlePhase.result;
      final passed = res?['passed'] == true;
      _narration = res?['coachFeedback']?.toString() ??
          (passed
              ? 'Defensa exitosa. El villano cae.'
              : 'No alcanzó. Reintentá el desafío.');
    });

    if (res?['passed'] == true) {
      HapticFeedback.heavyImpact();
      final coins = (res?['coinsHint'] is num)
          ? (res!['coinsHint'] as num).toInt()
          : 30;
      // Clip de victoria in-app
      try {
        await _fightVideo?.pause();
        final win = _victoryVideo;
        if (win != null && win.value.isInitialized) {
          await win.seekTo(Duration.zero);
          await win.play();
        }
      } catch (_) {}
      QuestCelebration.show(context, coinsEarned: coins);
      await ApiService.claimQuest(widget.questId);
    }
  }

  Future<void> _disposeCamera() async {
    _timer?.cancel();
    try {
      await _camera?.stopImageStream();
    } catch (_) {}
    await _camera?.dispose();
    _camera = null;
    await _detector?.close();
    _detector = null;
  }

  Future<void> _disposeVideos() async {
    final f = _fightVideo;
    final w = _victoryVideo;
    _fightVideo = null;
    _victoryVideo = null;
    f?.removeListener(_onFightVideoTick);
    await f?.dispose();
    await w?.dispose();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _disposeCamera();
    _disposeVideos();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Combate · ${widget.villainName}',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildArena()),
            _buildNarration(),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildArena() {
    if (_phase == _BattlePhase.challenge || _phase == _BattlePhase.grading) {
      return _buildChallengeView();
    }

    // Clip de pelea (ataque) o victoria — se reproduce dentro de la app
    final showVictoryClip =
        _phase == _BattlePhase.result && _grade?['passed'] == true;
    final activeVideo = showVictoryClip ? _victoryVideo : _fightVideo;
    final videoReady =
        showVictoryClip ? _victoryVideoReady : _fightVideoReady;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.14),
                  Colors.black,
                ],
              ),
            ),
          ),
        ),
        // Video cinemático de pelea
        if (videoReady &&
            activeVideo != null &&
            activeVideo.value.isInitialized)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: activeVideo.value.size.width,
                    height: activeVideo.value.size.height,
                    child: VideoPlayer(activeVideo),
                  ),
                ),
              ),
            ),
          )
        else
          // Fallback estático si no hay MP4
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _portraitImage('assets/battle/feo_defend.jpg', size: 140),
              const SizedBox(width: 16),
              _portraitImage(_portrait, size: 150),
            ],
          ),
        if (_phase == _BattlePhase.attack || _phase == _BattlePhase.intro)
          Positioned(
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepOrangeAccent.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'CLIP DE COMBATE',
                style: GoogleFonts.rajdhani(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        if (_phase == _BattlePhase.defend)
          Positioned(
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'FEO SE DEFIENDE',
                style: GoogleFonts.rajdhani(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        if (_phase == _BattlePhase.result)
          Positioned(
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: (_grade?['passed'] == true
                        ? Colors.greenAccent
                        : Colors.orangeAccent)
                    .withOpacity(0.92),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _grade?['passed'] == true ? 'VICTORIA' : 'REINTENTAR',
                style: GoogleFonts.rajdhani(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        // Mini Feo pulse en fase defensa (overlay)
        if (_phase == _BattlePhase.defend)
          Positioned(
            bottom: 12,
            left: 20,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final s = 0.92 + 0.08 * _pulseCtrl.value;
                return Transform.scale(
                  scale: s,
                  child: _portraitImage('assets/battle/feo_defend.jpg', size: 72),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _portraitImage(String asset, {double size = 160}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.cardSolid,
          alignment: Alignment.center,
          child: Text(widget.villainName, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _buildChallengeView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$_exerciseEs',
                  style: GoogleFonts.rajdhani(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Text(
                  '$_liveReps / $_targetReps',
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.black,
              child: _cameraError != null
                  ? Center(
                      child: Text(
                        _cameraError!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : !_cameraReady
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(_camera!),
                            if (_phase == _BattlePhase.grading)
                              Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'IA del coach evaluando…',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Text(
                                '${_seconds}s',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNarration() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSolid,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSolid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FEO · ENTRENADOR',
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _narration,
            style: GoogleFonts.inter(
              color: AppColors.foreground,
              height: 1.35,
              fontSize: 14,
            ),
          ),
          if (_grade != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reps estimadas: ${_grade!['estimatedReps'] ?? '-'} · '
              'Técnica: ${_grade!['formScore'] ?? '-'}%',
              style: GoogleFonts.inter(
                color: AppColors.mutedForeground,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          if (_phase == _BattlePhase.intro ||
              _phase == _BattlePhase.attack ||
              _phase == _BattlePhase.defend)
            Expanded(
              child: ElevatedButton(
                onPressed: _phase == _BattlePhase.defend ||
                        _phase == _BattlePhase.intro
                    ? _startChallenge
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Defender a Feo',
                  style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          if (_phase == _BattlePhase.challenge) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _finishAndGrade,
                icon: const Icon(Icons.cloud_done_outlined),
                label: Text(
                  _liveReps >= _targetReps
                      ? 'Enviar a la IA'
                      : 'Enviar igual ($_liveReps)',
                  style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
          if (_phase == _BattlePhase.result) ...[
            if (_grade?['passed'] != true)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _grade = null;
                      _phase = _BattlePhase.defend;
                      _narration = widget.battle?['defenseLine']?.toString() ??
                          'Reintentemos la defensa con mejor control.';
                    });
                  },
                  child: Text(
                    'Reintentar',
                    style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (_grade?['passed'] != true) const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_grade?['passed'] == true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _grade?['passed'] == true ? 'Cerrar victoria' : 'Salir',
                  style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
