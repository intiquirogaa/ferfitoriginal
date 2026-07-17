import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Grabación corta para validar un desafío del coach (evidencia de ejecución).
class ChallengeProofScreen extends StatefulWidget {
  final int questId;
  final String title;
  final String coachNote;
  final String? exerciseHint;

  const ChallengeProofScreen({
    super.key,
    required this.questId,
    required this.title,
    this.coachNote = '',
    this.exerciseHint,
  });

  @override
  State<ChallengeProofScreen> createState() => _ChallengeProofScreenState();
}

class _ChallengeProofScreenState extends State<ChallengeProofScreen> {
  CameraController? _controller;
  bool _initializing = true;
  bool _recording = false;
  bool _submitting = false;
  String? _error;
  int _seconds = 0;
  Timer? _timer;
  String? _videoPath;

  static const int minSeconds = 3;
  static const int maxSeconds = 15;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      setState(() {
        _initializing = false;
        _error = 'La evidencia por cámara no está disponible en web.';
      });
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No hay cámara disponible.');
      final selected = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = 'No se pudo iniciar la cámara: $e';
        });
      }
    }
  }

  Future<void> _toggleRecord() async {
    final cam = _controller;
    if (cam == null || !cam.value.isInitialized || _submitting) return;

    if (_recording) {
      try {
        final file = await cam.stopVideoRecording();
        _timer?.cancel();
        setState(() {
          _recording = false;
          _videoPath = file.path;
        });
      } catch (e) {
        setState(() {
          _recording = false;
          _error = 'Error al detener la grabación: $e';
        });
      }
      return;
    }

    try {
      await cam.startVideoRecording();
      setState(() {
        _recording = true;
        _seconds = 0;
        _videoPath = null;
        _error = null;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= maxSeconds) {
          t.cancel();
          await _toggleRecord();
        }
      });
    } catch (e) {
      setState(() => _error = 'No se pudo grabar: $e');
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_seconds < minSeconds && (_videoPath == null || _seconds < minSeconds)) {
      setState(() {
        _error = 'Grabá al menos $minSeconds segundos de ejecución limpia.';
      });
      return;
    }
    setState(() => _submitting = true);
    final res = await ApiService.submitQuestProof(
      questId: widget.questId,
      durationSec: _seconds.clamp(minSeconds, maxSeconds),
      note: _videoPath != null ? 'local_clip' : 'client_verified',
      clientVerified: true,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res != null && res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ??
                'Evidencia registrada. Buen trabajo.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = res?['error']?.toString() ??
            'No se pudo enviar la evidencia. Reintentá.';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Evidencia de sesión',
          style: GoogleFonts.rajdhani(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundDeep,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
                if (widget.coachNote.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.coachNote,
                    style: GoogleFonts.inter(
                      color: AppColors.mutedForeground,
                      height: 1.4,
                    ),
                  ),
                ],
                if (widget.exerciseHint != null &&
                    widget.exerciseHint!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Sugerencia: ${widget.exerciseHint}',
                    style: GoogleFonts.inter(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: _error != null && _controller == null
                        ? Container(
                            color: AppColors.cardSolid,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          )
                        : _controller != null &&
                                _controller!.value.isInitialized
                            ? CameraPreview(_controller!)
                            : Container(color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _recording
                      ? 'Grabando… ${_seconds}s / ${maxSeconds}s'
                      : _videoPath != null
                          ? 'Clip listo (${_seconds}s). Enviá la evidencia.'
                          : 'Grabá de $minSeconds a $maxSeconds s. Cuerpo completo a la vista.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppColors.mutedForeground),
                ),
                if (_error != null && _controller != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _toggleRecord,
                        icon: Icon(
                          _recording ? Icons.stop : Icons.videocam,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          _recording ? 'Detener' : 'Grabar',
                          style: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_submitting || _recording)
                            ? null
                            : (_videoPath != null || _seconds >= minSeconds)
                                ? _submit
                                : null,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          'Enviar',
                          style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Feo — entrenador personal: no necesitamos un video perfecto. '
                  'Necesitamos evidencia de que ejecutaste el movimiento con control.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                    height: 1.35,
                  ),
                ),
              ],
            ),
    );
  }
}
