import 'dart:math' as math;

import 'form_check_models.dart';

class FormCheckEngine {
  const FormCheckEngine();

  FormCheckResult analyze(FormCheckDefinition definition, List<PoseFrame> frames) {
    if (frames.length < 6) {
      return const FormCheckResult(
        status: FormCheckStatus.retry,
        confidence: 0,
        repetitions: 0,
        findings: [
          FormCheckFinding(
            area: 'cámara',
            message: 'No pude ver suficientes posiciones. Repetí la toma con todo el cuerpo visible.',
          ),
        ],
      );
    }

    switch (definition.movement) {
      case FormCheckMovement.squat:
        return _analyzeSquat(frames);
      case FormCheckMovement.pushUp:
        return _analyzePushUp(frames);
      case FormCheckMovement.bicepsCurl:
        return _analyzeCurl(frames);
      case FormCheckMovement.lateralRaise:
        return _analyzeLateralRaise(frames);
      case FormCheckMovement.crunch:
        return _analyzeCrunch(frames);
      case FormCheckMovement.jumpingJack:
        return _analyzeJumpingJack(frames);
    }
  }

  FormCheckResult _analyzeCrunch(List<PoseFrame> frames) {
    final side = _bestSide(frames, const ['shoulder', 'hip', 'knee']);
    final names = ['${side}Shoulder', '${side}Hip', '${side}Knee'];
    final valid = _validFrames(frames, names);
    if (valid.length < 6) return _retry(names, valid.length);

    // Ángulo hombro-cadera-rodilla: más cerrado al hacer crunch
    final torsoAngles = <double>[];
    for (final frame in valid) {
      torsoAngles.add(jointAngle(
        frame.point('${side}Shoulder')!,
        frame.point('${side}Hip')!,
        frame.point('${side}Knee')!,
      ));
    }
    final minA = torsoAngles.reduce(math.min);
    final maxA = torsoAngles.reduce(math.max);
    final findings = <FormCheckFinding>[];
    findings.add(maxA - minA >= 12
        ? const FormCheckFinding(
            area: 'recorrido',
            message: 'Hay flexión de tronco detectable en el crunch.',
            isPositive: true,
          )
        : const FormCheckFinding(
            area: 'recorrido',
            message: 'Marcá un poco más el enrosque del torso, sin tirar del cuello.',
          ));
    findings.add(const FormCheckFinding(
      area: 'técnica',
      message: 'Exhalá al subir y controlá la bajada. No uses impulso de cadera.',
      isPositive: true,
    ));

    return _result(
      frames: valid,
      names: names,
      repetitions: _countCycles(torsoAngles, low: minA + 8, high: maxA - 4, inverted: true),
      findings: findings,
      metrics: {'torsoMin': minA, 'torsoMax': maxA},
    );
  }

  FormCheckResult _analyzeJumpingJack(List<PoseFrame> frames) {
    final required = const [
      'leftWrist',
      'rightWrist',
      'leftAnkle',
      'rightAnkle',
      'leftShoulder',
      'rightShoulder',
    ];
    final valid = _validFrames(frames, required);
    if (valid.length < 6) return _retry(required, valid.length);

    final spreads = <double>[];
    for (final frame in valid) {
      final lw = frame.point('leftWrist')!;
      final rw = frame.point('rightWrist')!;
      final la = frame.point('leftAnkle')!;
      final ra = frame.point('rightAnkle')!;
      final handSpread = (lw.x - rw.x).abs();
      final footSpread = (la.x - ra.x).abs();
      spreads.add(handSpread + footSpread);
    }
    final minS = spreads.reduce(math.min);
    final maxS = spreads.reduce(math.max);
    final findings = <FormCheckFinding>[
      maxS - minS > 0.08
          ? const FormCheckFinding(
              area: 'apertura',
              message: 'Detecté apertura y cierre de brazos/piernas.',
              isPositive: true,
            )
          : const FormCheckFinding(
              area: 'apertura',
              message: 'Amplía un poco más el movimiento de brazos y piernas.',
            ),
    ];
    final mid = (minS + maxS) / 2;
    return _result(
      frames: valid,
      names: required,
      repetitions: _countCycles(spreads, low: mid * 0.9, high: mid * 1.1, inverted: false),
      findings: findings,
      metrics: {'spreadMin': minS, 'spreadMax': maxS},
    );
  }

  FormCheckResult _analyzeSquat(List<PoseFrame> frames) {
    final side = _bestSide(frames, const ['shoulder', 'hip', 'knee', 'ankle']);
    final names = ['${side}Shoulder', '${side}Hip', '${side}Knee', '${side}Ankle'];
    final valid = _validFrames(frames, names);
    if (valid.length < 6) return _retry(names, valid.length);

    final kneeAngles = <double>[];
    final torsoLeans = <double>[];
    for (final frame in valid) {
      kneeAngles.add(jointAngle(
        frame.point('${side}Hip')!,
        frame.point('${side}Knee')!,
        frame.point('${side}Ankle')!,
      ));
      torsoLeans.add(segmentAngleFromVertical(
        frame.point('${side}Shoulder')!,
        frame.point('${side}Hip')!,
      ));
    }

    final minKnee = kneeAngles.reduce(math.min);
    final maxKnee = kneeAngles.reduce(math.max);
    final maxLean = torsoLeans.reduce(math.max);
    final findings = <FormCheckFinding>[];
    if (minKnee <= 115) {
      findings.add(const FormCheckFinding(
        area: 'profundidad',
        message: 'Alcanzaste una profundidad útil y controlable.',
        isPositive: true,
      ));
    } else {
      findings.add(const FormCheckFinding(
        area: 'profundidad',
        message: 'Probá bajar un poco más, solo si podés mantener los talones apoyados y sin dolor.',
      ));
    }
    if (maxLean <= 48) {
      findings.add(const FormCheckFinding(
        area: 'torso',
        message: 'El torso se mantuvo estable durante el recorrido.',
        isPositive: true,
      ));
    } else {
      findings.add(const FormCheckFinding(
        area: 'torso',
        message: 'El torso se inclina bastante. Reducí profundidad y mantené el pecho firme.',
      ));
    }
    if (maxKnee - minKnee < 30) {
      findings.add(const FormCheckFinding(
        area: 'recorrido',
        message: 'No detecté un recorrido completo. Hacé repeticiones más marcadas y lentas.',
      ));
    }

    return _result(
      frames: valid,
      names: names,
      repetitions: _countCycles(kneeAngles, low: 120, high: 145, inverted: true),
      findings: findings,
      metrics: {'rodillaMin': minKnee, 'torsoMax': maxLean},
    );
  }

  FormCheckResult _analyzePushUp(List<PoseFrame> frames) {
    final side = _bestSide(frames, const ['shoulder', 'elbow', 'wrist', 'hip', 'ankle']);
    final names = ['${side}Shoulder', '${side}Elbow', '${side}Wrist', '${side}Hip', '${side}Ankle'];
    final valid = _validFrames(frames, names);
    if (valid.length < 6) return _retry(names, valid.length);

    final elbowAngles = <double>[];
    final bodyAngles = <double>[];
    for (final frame in valid) {
      elbowAngles.add(jointAngle(
        frame.point('${side}Shoulder')!,
        frame.point('${side}Elbow')!,
        frame.point('${side}Wrist')!,
      ));
      bodyAngles.add(jointAngle(
        frame.point('${side}Shoulder')!,
        frame.point('${side}Hip')!,
        frame.point('${side}Ankle')!,
      ));
    }
    final minElbow = elbowAngles.reduce(math.min);
    final minBody = bodyAngles.reduce(math.min);
    final findings = <FormCheckFinding>[];
    findings.add(minElbow <= 115
        ? const FormCheckFinding(area: 'codos', message: 'La flexión de brazos tiene buen recorrido.', isPositive: true)
        : const FormCheckFinding(area: 'codos', message: 'Bajá un poco más el pecho manteniendo el control.'));
    findings.add(minBody >= 155
        ? const FormCheckFinding(area: 'línea corporal', message: 'Mantuviste hombros, cadera y tobillos alineados.', isPositive: true)
        : const FormCheckFinding(area: 'línea corporal', message: 'Evitá que la cadera caiga o se eleve; activá abdomen y glúteos.'));

    return _result(
      frames: valid,
      names: names,
      repetitions: _countCycles(elbowAngles, low: 115, high: 150, inverted: true),
      findings: findings,
      metrics: {'codoMin': minElbow, 'alineacionMin': minBody},
    );
  }

  FormCheckResult _analyzeCurl(List<PoseFrame> frames) {
    final side = _bestSide(frames, const ['shoulder', 'elbow', 'wrist', 'hip']);
    final names = ['${side}Shoulder', '${side}Elbow', '${side}Wrist', '${side}Hip'];
    final valid = _validFrames(frames, names);
    if (valid.length < 6) return _retry(names, valid.length);

    final elbowAngles = <double>[];
    final elbowDrift = <double>[];
    for (final frame in valid) {
      final shoulder = frame.point('${side}Shoulder')!;
      final elbow = frame.point('${side}Elbow')!;
      final wrist = frame.point('${side}Wrist')!;
      final hip = frame.point('${side}Hip')!;
      elbowAngles.add(jointAngle(shoulder, elbow, wrist));
      final torsoLength = math.max(1, _distance(shoulder, hip));
      elbowDrift.add((elbow.x - shoulder.x).abs() / torsoLength);
    }
    final minElbow = elbowAngles.reduce(math.min);
    final maxElbow = elbowAngles.reduce(math.max);
    final maxDrift = elbowDrift.reduce(math.max);
    final findings = <FormCheckFinding>[];
    findings.add(minElbow <= 80 && maxElbow >= 130
        ? const FormCheckFinding(area: 'recorrido', message: 'Completaste un buen rango de flexión y extensión.', isPositive: true)
        : const FormCheckFinding(area: 'recorrido', message: 'Extendé y flexioná el codo un poco más, sin perder control.'));
    findings.add(maxDrift <= 0.32
        ? const FormCheckFinding(area: 'codo', message: 'El codo se mantuvo cerca del cuerpo.', isPositive: true)
        : const FormCheckFinding(area: 'codo', message: 'El codo se desplaza hacia adelante. Mantenelo cerca del torso.'));

    return _result(
      frames: valid,
      names: names,
      repetitions: _countCycles(elbowAngles, low: 85, high: 130, inverted: true),
      findings: findings,
      metrics: {'codoMin': minElbow, 'desplazamientoCodo': maxDrift},
    );
  }

  FormCheckResult _analyzeLateralRaise(List<PoseFrame> frames) {
    final required = const [
      'leftShoulder', 'leftElbow', 'leftWrist', 'leftHip',
      'rightShoulder', 'rightElbow', 'rightWrist', 'rightHip',
    ];
    final valid = _validFrames(frames, required);
    if (valid.length < 6) return _retry(required, valid.length);

    final elevations = <double>[];
    final symmetry = <double>[];
    final elbowAngles = <double>[];
    for (final frame in valid) {
      final leftElevation = jointAngle(
        frame.point('leftHip')!,
        frame.point('leftShoulder')!,
        frame.point('leftWrist')!,
      );
      final rightElevation = jointAngle(
        frame.point('rightHip')!,
        frame.point('rightShoulder')!,
        frame.point('rightWrist')!,
      );
      elevations.add((leftElevation + rightElevation) / 2);
      symmetry.add((leftElevation - rightElevation).abs());
      elbowAngles.add((
        jointAngle(frame.point('leftShoulder')!, frame.point('leftElbow')!, frame.point('leftWrist')!) +
        jointAngle(frame.point('rightShoulder')!, frame.point('rightElbow')!, frame.point('rightWrist')!)
      ) / 2);
    }
    final maxElevation = elevations.reduce(math.max);
    final maxSymmetryGap = symmetry.reduce(math.max);
    final minElbow = elbowAngles.reduce(math.min);
    final findings = <FormCheckFinding>[];
    findings.add(maxElevation >= 70 && maxElevation <= 110
        ? const FormCheckFinding(area: 'altura', message: 'Elevaste los brazos hasta una altura adecuada.', isPositive: true)
        : maxElevation < 70
            ? const FormCheckFinding(area: 'altura', message: 'Subí un poco más, hasta aproximarte a la altura de los hombros.')
            : const FormCheckFinding(area: 'altura', message: 'No hace falta subir tanto por encima de los hombros.'));
    findings.add(maxSymmetryGap <= 18
        ? const FormCheckFinding(area: 'simetría', message: 'Ambos brazos se movieron de forma pareja.', isPositive: true)
        : const FormCheckFinding(area: 'simetría', message: 'Un brazo está subiendo antes o más alto que el otro.'));
    if (minElbow < 125) {
      findings.add(const FormCheckFinding(area: 'codos', message: 'Flexionás demasiado los codos. Mantené una curva suave y estable.'));
    }

    return _result(
      frames: valid,
      names: required,
      repetitions: _countCycles(elevations, low: 35, high: 70, inverted: false),
      findings: findings,
      metrics: {'elevacionMax': maxElevation, 'diferenciaBrazos': maxSymmetryGap},
    );
  }

  List<PoseFrame> _validFrames(List<PoseFrame> frames, List<String> names) {
    return frames.where((frame) => names.every((name) => frame.point(name) != null)).toList();
  }

  String _bestSide(List<PoseFrame> frames, List<String> joints) {
    double score(String side) => frames.fold<double>(
      0,
      (sum, frame) => sum + frame.confidenceFor(joints.map((joint) => '$side${_capitalize(joint)}')),
    );
    return score('left') >= score('right') ? 'left' : 'right';
  }

  FormCheckResult _retry(List<String> names, int validFrames) {
    return FormCheckResult(
      status: FormCheckStatus.retry,
      confidence: 0,
      repetitions: 0,
      findings: [
        FormCheckFinding(
          area: 'cámara',
          message: 'Solo detecté $validFrames cuadros útiles. Alejá el celular y evitá salir del encuadre.',
        ),
      ],
      metrics: {'cuadrosValidos': validFrames.toDouble(), 'puntosRequeridos': names.length.toDouble()},
    );
  }

  FormCheckResult _result({
    required List<PoseFrame> frames,
    required List<String> names,
    required int repetitions,
    required List<FormCheckFinding> findings,
    required Map<String, double> metrics,
  }) {
    final confidence = frames
            .map((frame) => frame.confidenceFor(names))
            .reduce((a, b) => a + b) /
        frames.length;
    final corrections = findings.where((finding) => !finding.isPositive).length;
    final status = repetitions == 0
        ? FormCheckStatus.retry
        : corrections <= 1
            ? FormCheckStatus.good
            : FormCheckStatus.needsAdjustment;
    final finalFindings = repetitions == 0
        ? [
            ...findings,
            const FormCheckFinding(
              area: 'repeticiones',
              message: 'No detecté una repetición completa. Hacé el recorrido más lento y marcado.',
            ),
          ]
        : findings;
    return FormCheckResult(
      status: status,
      confidence: confidence.clamp(0, 1),
      repetitions: repetitions,
      findings: finalFindings,
      metrics: metrics,
    );
  }

  int _countCycles(List<double> values, {
    required double low,
    required double high,
    required bool inverted,
  }) {
    var repetitions = 0;
    var reachedFirst = false;
    for (final value in values) {
      final first = inverted ? value <= low : value >= high;
      final second = inverted ? value >= high : value <= low;
      if (!reachedFirst && first) reachedFirst = true;
      if (reachedFirst && second) {
        repetitions++;
        reachedFirst = false;
      }
    }
    return repetitions;
  }

  double _distance(BodyPoint a, BodyPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  String _capitalize(String value) => '${value[0].toUpperCase()}${value.substring(1)}';
}
