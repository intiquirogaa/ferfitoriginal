import 'dart:math' as math;

import 'package:ferfit_flutter/form_check/form_check_engine.dart';
import 'package:ferfit_flutter/form_check/form_check_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resuelve únicamente los cuatro movimientos soportados', () {
    expect(resolveFormCheckDefinition('Barbell Squat')?.movement, FormCheckMovement.squat);
    expect(resolveFormCheckDefinition('Push-up')?.movement, FormCheckMovement.pushUp);
    expect(resolveFormCheckDefinition('Dumbbell Curl')?.movement, FormCheckMovement.bicepsCurl);
    expect(resolveFormCheckDefinition('Cable Lateral Raise')?.movement, FormCheckMovement.lateralRaise);
    expect(resolveFormCheckDefinition('Lying Leg Curl'), isNull);
    expect(resolveFormCheckDefinition('Bench Press'), isNull);
  });

  test('calcula un ángulo articular en grados', () {
    const vertex = BodyPoint(x: 0, y: 0, confidence: 1);
    const a = BodyPoint(x: 0, y: -1, confidence: 1);
    const c = BodyPoint(x: 1, y: 0, confidence: 1);
    expect(jointAngle(a, vertex, c), closeTo(90, 0.001));
  });

  test('detecta repeticiones completas de sentadilla', () {
    final definition = resolveFormCheckDefinition('Sentadilla')!;
    final frames = <PoseFrame>[];
    for (final angle in [170.0, 170.0, 100.0, 100.0, 170.0, 170.0, 100.0, 100.0, 170.0]) {
      frames.add(_squatFrame(angle));
    }

    final result = const FormCheckEngine().analyze(definition, frames);

    expect(result.status, FormCheckStatus.good);
    expect(result.repetitions, 2);
    expect(result.confidence, closeTo(1, 0.001));
  });

  test('pide repetir cuando no hay suficientes cuadros', () {
    final definition = resolveFormCheckDefinition('Push-up')!;
    final result = const FormCheckEngine().analyze(definition, const []);
    expect(result.status, FormCheckStatus.retry);
  });
}

PoseFrame _squatFrame(double kneeAngle) {
  final radians = kneeAngle * math.pi / 180;
  final ankle = BodyPoint(
    x: math.sin(radians),
    y: -math.cos(radians),
    confidence: 1,
  );
  return PoseFrame(
    capturedAt: DateTime(2026, 7, 16),
    points: {
      'leftShoulder': const BodyPoint(x: 0, y: -2, confidence: 1),
      'leftHip': const BodyPoint(x: 0, y: -1, confidence: 1),
      'leftKnee': const BodyPoint(x: 0, y: 0, confidence: 1),
      'leftAnkle': ankle,
    },
  );
}
