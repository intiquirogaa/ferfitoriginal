import 'dart:math' as math;

enum FormCheckMovement { squat, pushUp, bicepsCurl, lateralRaise, crunch, jumpingJack }

enum FormCheckCameraAngle { side, front }

enum FormCheckStatus { good, needsAdjustment, retry }

class FormCheckDefinition {
  final FormCheckMovement movement;
  final String title;
  final FormCheckCameraAngle cameraAngle;
  final String setupInstruction;

  const FormCheckDefinition({
    required this.movement,
    required this.title,
    required this.cameraAngle,
    required this.setupInstruction,
  });
}

class BodyPoint {
  final double x;
  final double y;
  final double z;
  final double confidence;

  const BodyPoint({
    required this.x,
    required this.y,
    this.z = 0,
    required this.confidence,
  });
}

class PoseFrame {
  final DateTime capturedAt;
  final Map<String, BodyPoint> points;

  const PoseFrame({required this.capturedAt, required this.points});

  BodyPoint? point(String name, {double minimumConfidence = 0.35}) {
    final value = points[name];
    if (value == null || value.confidence < minimumConfidence) return null;
    return value;
  }

  double confidenceFor(Iterable<String> names) {
    final values = names.map((name) => points[name]?.confidence ?? 0).toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

class FormCheckFinding {
  final String area;
  final String message;
  final bool isPositive;

  const FormCheckFinding({
    required this.area,
    required this.message,
    this.isPositive = false,
  });
}

class FormCheckResult {
  final FormCheckStatus status;
  final double confidence;
  final int repetitions;
  final List<FormCheckFinding> findings;
  final Map<String, double> metrics;

  const FormCheckResult({
    required this.status,
    required this.confidence,
    required this.repetitions,
    required this.findings,
    this.metrics = const {},
  });
}

FormCheckDefinition? resolveFormCheckDefinition(String? exerciseName) {
  final name = _normalize(exerciseName ?? '');
  if (name.contains('squat') || name.contains('sentadilla')) {
    return const FormCheckDefinition(
      movement: FormCheckMovement.squat,
      title: 'Sentadilla',
      cameraAngle: FormCheckCameraAngle.side,
      setupInstruction: 'Poné el celular de perfil y asegurate de que se vea todo tu cuerpo.',
    );
  }
  if (name.contains('push up') || name.contains('pushup') || name.contains('flexion')) {
    return const FormCheckDefinition(
      movement: FormCheckMovement.pushUp,
      title: 'Flexiones',
      cameraAngle: FormCheckCameraAngle.side,
      setupInstruction: 'Poné el celular de perfil, a la altura del torso, con manos y pies visibles.',
    );
  }
  final isLegCurl = name.contains('leg curl') || name.contains('femoral');
  if (!isLegCurl &&
      (name.contains('biceps curl') ||
          name.contains('bicep curl') ||
          name.contains('dumbbell curl') ||
          name.contains('barbell curl') ||
          name.contains('hammer curl') ||
          name.contains('curl de biceps') ||
          name.contains('curl con mancuerna'))) {
    return const FormCheckDefinition(
      movement: FormCheckMovement.bicepsCurl,
      title: 'Curl de bíceps',
      cameraAngle: FormCheckCameraAngle.side,
      setupInstruction: 'Grabate de perfil, con hombro, codo y muñeca completamente visibles.',
    );
  }
  if (name.contains('lateral raise') || name.contains('elevacion lateral')) {
    return const FormCheckDefinition(
      movement: FormCheckMovement.lateralRaise,
      title: 'Elevaciones laterales',
      cameraAngle: FormCheckCameraAngle.front,
      setupInstruction: 'Poné el celular de frente y dejá espacio para ver ambas manos al subir.',
    );
  }
  if (name.contains('crunch') ||
      name.contains('abdominal') ||
      name.contains('sit up') ||
      name.contains('situp')) {
    return const FormCheckDefinition(
      movement: FormCheckMovement.crunch,
      title: 'Abdominales (crunch)',
      cameraAngle: FormCheckCameraAngle.side,
      setupInstruction:
          'Celular de perfil. Acostate, se deben ver hombros, cadera y rodillas.',
    );
  }
  if (name.contains('jumping jack') ||
      name.contains('saltos de tijera') ||
      name.contains('jumpingjack')) {
    return const FormCheckDefinition(
      movement: FormCheckMovement.jumpingJack,
      title: 'Jumping jacks',
      cameraAngle: FormCheckCameraAngle.front,
      setupInstruction: 'Celular de frente, cuerpo completo visible.',
    );
  }
  return null;
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll(RegExp(r'[-_/]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

double jointAngle(BodyPoint a, BodyPoint vertex, BodyPoint c) {
  final abX = a.x - vertex.x;
  final abY = a.y - vertex.y;
  final cbX = c.x - vertex.x;
  final cbY = c.y - vertex.y;
  final denominator = math.sqrt(abX * abX + abY * abY) *
      math.sqrt(cbX * cbX + cbY * cbY);
  if (denominator == 0) return 0;
  final cosine = ((abX * cbX + abY * cbY) / denominator).clamp(-1.0, 1.0);
  return math.acos(cosine) * 180 / math.pi;
}

double segmentAngleFromVertical(BodyPoint top, BodyPoint bottom) {
  final dx = top.x - bottom.x;
  final dy = top.y - bottom.y;
  return math.atan2(dx.abs(), dy.abs()) * 180 / math.pi;
}
