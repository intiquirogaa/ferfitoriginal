import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../form_check/form_check_engine.dart';
import '../form_check/form_check_models.dart';
import '../theme/app_theme.dart';

class FormCheckScreen extends StatefulWidget {
  final String exerciseName;

  const FormCheckScreen({super.key, required this.exerciseName});

  @override
  State<FormCheckScreen> createState() => _FormCheckScreenState();
}

class _FormCheckScreenState extends State<FormCheckScreen> {
  static const captureDuration = 8;
  static const orientations = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  final engine = const FormCheckEngine();
  final detector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.base,
      mode: PoseDetectionMode.stream,
    ),
  );
  final capturedFrames = <PoseFrame>[];

  late final FormCheckDefinition definition;
  CameraController? cameraController;
  Timer? timer;
  bool processing = false;
  bool capturing = false;
  bool initializing = true;
  String? cameraError;
  int secondsRemaining = captureDuration;
  double liveConfidence = 0;
  FormCheckResult? result;

  @override
  void initState() {
    super.initState();
    definition = resolveFormCheckDefinition(widget.exerciseName)!;
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    if (mounted) setState(() => initializing = true);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('no_camera', 'No hay cámara disponible.');
      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      await controller.initialize();
      cameraController = controller;
      await controller.startImageStream(processCameraImage);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => initializing = false);
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        cameraError = error.code == 'CameraAccessDenied'
            ? 'Necesitamos permiso de cámara para revisar tu técnica.'
            : error.description ?? 'No se pudo iniciar la cámara.';
        initializing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        cameraError = 'No se pudo iniciar la cámara: $error';
        initializing = false;
      });
    }
  }

  Future<void> processCameraImage(CameraImage image) async {
    if (processing || !mounted) return;
    processing = true;
    try {
      final input = inputImageFromCamera(image);
      if (input == null) return;
      final poses = await detector.processImage(input);
      if (poses.isEmpty) {
        if (mounted) setState(() => liveConfidence = 0);
        return;
      }
      final frame = PoseFrame(
        capturedAt: DateTime.now(),
        points: {
          for (final entry in poses.first.landmarks.entries)
            entry.key.name: BodyPoint(
              x: entry.value.x,
              y: entry.value.y,
              z: entry.value.z,
              confidence: entry.value.likelihood,
            ),
        },
      );
      const required = [
        'leftShoulder', 'rightShoulder', 'leftElbow', 'rightElbow',
        'leftWrist', 'rightWrist', 'leftHip', 'rightHip',
        'leftKnee', 'rightKnee', 'leftAnkle', 'rightAnkle',
      ];
      final confidence = frame.confidenceFor(required);
      if (capturing && confidence >= 0.35) capturedFrames.add(frame);
      if (mounted) setState(() => liveConfidence = confidence);
    } catch (_) {
      // Saltar un cuadro inválido permite que el stream se recupere solo.
    } finally {
      processing = false;
    }
  }

  InputImage? inputImageFromCamera(CameraImage image) {
    final controller = cameraController;
    if (controller == null || image.planes.length != 1) return null;
    final camera = controller.description;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    } else {
      final compensation = orientations[controller.value.deviceOrientation];
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

  void startCapture() {
    if (capturing || cameraController == null) return;
    capturedFrames.clear();
    timer?.cancel();
    setState(() {
      result = null;
      capturing = true;
      secondsRemaining = captureDuration;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (value) {
      if (!mounted) return;
      if (secondsRemaining <= 1) {
        value.cancel();
        finishCapture();
      } else {
        setState(() => secondsRemaining--);
      }
    });
  }

  void finishCapture() {
    if (!capturing) return;
    final analysis = engine.analyze(definition, List.unmodifiable(capturedFrames));
    if (!mounted) return;
    setState(() {
      capturing = false;
      result = analysis;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    final controller = cameraController;
    if (controller != null) {
      if (controller.value.isStreamingImages) controller.stopImageStream();
      controller.dispose();
    }
    detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Revisar técnica', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: buildCamera()),
            buildPanel(),
          ],
        ),
      ),
    );
  }

  Widget buildCamera() {
    final controller = cameraController;
    if (initializing) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (cameraError != null || controller == null || !controller.value.isInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, color: AppColors.error, size: 52),
              const SizedBox(height: 16),
              Text(cameraError ?? 'Cámara no disponible', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: initializeCamera, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    final detected = liveConfidence >= 0.35;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: capturing ? AppColors.primary : AppColors.borderSolid,
          width: capturing ? 2 : 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.72),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: detected ? AppColors.primary : Colors.orange),
              ),
              child: Text(
                detected
                    ? 'Cuerpo detectado ${(liveConfidence * 100).round()}%'
                    : 'Entrá completo en el encuadre',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: detected ? AppColors.primary : Colors.orange,
                ),
              ),
            ),
          ),
          if (capturing)
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  '$secondsRemaining',
                  style: GoogleFonts.rajdhani(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.cardSolid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: result == null ? buildInstructions() : buildResult(result!),
    );
  }

  Widget buildInstructions() {
    final angle = definition.cameraAngle == FormCheckCameraAngle.side
        ? 'DE PERFIL'
        : 'DE FRENTE';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${definition.title} · CÁMARA $angle',
          style: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          definition.setupInstruction,
          style: GoogleFonts.inter(color: AppColors.mutedForeground, height: 1.35),
        ),
        const SizedBox(height: 8),
        Text(
          'Hacé 2 o 3 repeticiones lentas. FerFit analiza los puntos del cuerpo sin guardar el video.',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: capturing ? null : startCapture,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: Icon(capturing ? Icons.hourglass_top : Icons.videocam_outlined),
            label: Text(
              capturing ? 'ANALIZANDO...' : 'ANALIZAR 8 SEGUNDOS',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildResult(FormCheckResult analysis) {
    final isGood = analysis.status == FormCheckStatus.good;
    final isRetry = analysis.status == FormCheckStatus.retry;
    final color = isGood
        ? AppColors.primary
        : isRetry
            ? Colors.orange
            : AppColors.secondary;
    final title = isGood
        ? 'Buen movimiento general'
        : isRetry
            ? 'Necesito otra toma'
            : 'Hay puntos para ajustar';
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 330),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isGood ? Icons.check_circle : Icons.tune, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.rajdhani(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  '${(analysis.confidence * 100).round()}%',
                  style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              '${analysis.repetitions} repeticiones detectadas · confianza estimada',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 12),
            ...analysis.findings.map(
              (finding) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      finding.isPositive ? Icons.check : Icons.arrow_right,
                      size: 18,
                      color: finding.isPositive ? AppColors.primary : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        finding.message,
                        style: GoogleFonts.inter(fontSize: 13, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              'Orientación técnica, no diagnóstico médico. Si sentís dolor, detené el ejercicio.',
              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: startCapture,
                icon: const Icon(Icons.replay),
                label: const Text('REPETIR ANÁLISIS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
