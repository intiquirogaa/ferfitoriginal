// Demos Feo: assets/feo_demos/{id}.jpg (+ .mp4 opcional)
// CHEST 14 + BACK 15 (2026-07-09)

enum FeoExerciseDemoKind {
  // CHEST (14)
  benchPress,
  inclineBenchPress,
  declineBenchPress,
  dumbbellBenchPress,
  inclineDumbbellPress,
  declineDumbbellPress,
  dumbbellFlyes,
  cableCrossover,
  pecDeckFly,
  pushUp,
  declinePushUp,
  inclinePushUp,
  diamondPushUp,
  machineChestPress,
  // BACK (15)
  pullUp,
  chinUp,
  latPulldown,
  straightArmPulldown,
  barbellRow,
  dumbbellRow,
  pendlayRow,
  tBarRow,
  seatedCableRow,
  chestSupportedRow,
  deadlift,
  rackPull,
  goodMorning,
  superman,
  invertedRow,
  // otros grupos
  squat,
  plank,
  dumbbellCurl,
  lunge,
  burpee,
  mountainClimber,
  overheadPress,
  lateralRaise,
  tricepsDip,
  crunch,
  jumpingJack,
  standingCalfRaise,
}

class FeoExerciseDemoInfo {
  final FeoExerciseDemoKind kind;
  final String titleEs;
  final String cue;
  final String poseAsset;
  final String? videoAsset;

  const FeoExerciseDemoInfo({
    required this.kind,
    required this.titleEs,
    required this.cue,
    required this.poseAsset,
    this.videoAsset,
  });
}

/// Lookup por nombre EN/ES (plan puede traer name, nameEn, nameEs).
FeoExerciseDemoInfo? resolveFeoExerciseDemo({
  String? name,
  String? nameEn,
  String? nameEs,
}) {
  final keys = <String>[
    if (name != null) name,
    if (nameEn != null) nameEn,
    if (nameEs != null) nameEs,
  ];
  for (final k in keys) {
    final hit = _match(k);
    if (hit != null) return hit;
  }
  return null;
}

FeoExerciseDemoInfo? _match(String raw) {
  final n = _normalize(raw);
  if (n.isEmpty) return null;

  // ─── CHEST: más específico primero ───

  // Diamond push-up (antes que push-up genérico)
  if (_containsAny(n, [
    'diamond push up', 'diamond pushup', 'flexiones diamante', 'flexion diamante',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.diamondPushUp,
      titleEs: 'Flexiones diamante',
      cue: 'Manos juntas bajo el pecho formando un diamante; codos cerca del cuerpo',
      poseAsset: 'assets/feo_demos/diamond_push_up.jpg',
      videoAsset: 'assets/feo_demos/diamond_push_up.mp4',
    );
  }

  // Incline push-up
  if (_containsAny(n, [
    'incline push up', 'incline pushup', 'flexiones inclinadas', 'flexion inclinada',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.inclinePushUp,
      titleEs: 'Flexiones inclinadas',
      cue: 'Manos elevadas en banco; más fácil que la flexión al piso',
      poseAsset: 'assets/feo_demos/incline_push_up.jpg',
      videoAsset: 'assets/feo_demos/incline_push_up.mp4',
    );
  }

  // Decline push-up
  if (_containsAny(n, [
    'decline push up', 'decline pushup', 'flexiones declinadas', 'flexion declinada',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.declinePushUp,
      titleEs: 'Flexiones declinadas',
      cue: 'Pies elevados en banco; más énfasis en pecho superior',
      poseAsset: 'assets/feo_demos/decline_push_up.jpg',
      videoAsset: 'assets/feo_demos/decline_push_up.mp4',
    );
  }

  // Standard push-up
  if (_containsAny(n, [
    'push up', 'pushup', 'push ups',
    'flexiones de brazos', 'flexion de brazos', 'flexiones', 'flexion',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.pushUp,
      titleEs: 'Flexiones',
      cue: 'Cuerpo recto, bajá el pecho y empujá hacia arriba',
      poseAsset: 'assets/feo_demos/push_up.jpg',
      videoAsset: 'assets/feo_demos/push_up.mp4',
    );
  }

  // Decline dumbbell press
  if (_containsAny(n, [
    'decline dumbbell press', 'decline dumbbell bench',
    'press declinado con mancuernas', 'press declinado mancuernas',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.declineDumbbellPress,
      titleEs: 'Press declinado con mancuernas',
      cue: 'Banco declinado; empujá las mancuernas sobre el pecho bajo',
      poseAsset: 'assets/feo_demos/decline_dumbbell_press.jpg',
      videoAsset: 'assets/feo_demos/decline_dumbbell_press.mp4',
    );
  }

  // Incline dumbbell press
  if (_containsAny(n, [
    'incline dumbbell press', 'incline dumbbell bench',
    'press inclinado con mancuernas', 'press inclinado mancuernas',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.inclineDumbbellPress,
      titleEs: 'Press inclinado con mancuernas',
      cue: 'Banco 30–45°; empujá hacia arriba sobre pecho alto',
      poseAsset: 'assets/feo_demos/incline_dumbbell_press.jpg',
      videoAsset: 'assets/feo_demos/incline_dumbbell_press.mp4',
    );
  }

  // Flat dumbbell bench press
  if (_containsAny(n, [
    'dumbbell bench press', 'dumbbell press',
    'press de banca con mancuernas', 'press con mancuernas',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.dumbbellBenchPress,
      titleEs: 'Press banca con mancuernas',
      cue: 'Banco plano; bajá controlado y empujá sin chocar las mancuernas',
      poseAsset: 'assets/feo_demos/dumbbell_bench_press.jpg',
      videoAsset: 'assets/feo_demos/dumbbell_bench_press.mp4',
    );
  }

  // Decline barbell bench
  if (_containsAny(n, [
    'decline bench press', 'decline barbell',
    'press de banca declinado', 'press declinado',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.declineBenchPress,
      titleEs: 'Press banca declinado',
      cue: 'Banco declinado; barra hacia pecho bajo, sin rebotar',
      poseAsset: 'assets/feo_demos/decline_bench_press.jpg',
      videoAsset: 'assets/feo_demos/decline_bench_press.mp4',
    );
  }

  // Incline barbell bench
  if (_containsAny(n, [
    'incline bench press', 'incline barbell',
    'press de banca inclinado', 'press inclinado',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.inclineBenchPress,
      titleEs: 'Press banca inclinado',
      cue: 'Banco 30–45°; barra al pecho superior',
      poseAsset: 'assets/feo_demos/incline_bench_press.jpg',
      videoAsset: 'assets/feo_demos/incline_bench_press.mp4',
    );
  }

  // Machine chest press
  if (_containsAny(n, [
    'machine chest press', 'chest press machine',
    'press de pecho en maquina', 'press de pecho en máquina', 'press pecho maquina',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.machineChestPress,
      titleEs: 'Press pecho en máquina',
      cue: 'Espalda apoyada; empujá los agarres sin bloquear los codos de golpe',
      poseAsset: 'assets/feo_demos/machine_chest_press.jpg',
      videoAsset: 'assets/feo_demos/machine_chest_press.mp4',
    );
  }

  // Flat barbell bench press (después de incline/decline)
  if (_containsAny(n, [
    'bench press', 'barbell bench press',
    'press de banca', 'press banca',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.benchPress,
      titleEs: 'Press de banca',
      cue: 'Bajá controlado al pecho y empujá sin rebotar',
      poseAsset: 'assets/feo_demos/bench_press.jpg',
      videoAsset: 'assets/feo_demos/bench_press.mp4',
    );
  }

  // Dumbbell flyes
  if (_containsAny(n, [
    'dumbbell flyes', 'dumbbell fly', 'dumbbell flies', 'chest fly',
    'aperturas con mancuernas', 'aperturas de pecho', 'aperturas',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.dumbbellFlyes,
      titleEs: 'Aperturas con mancuernas',
      cue: 'Codos semifijos; abrí en arco y cerrá como un abrazo',
      poseAsset: 'assets/feo_demos/dumbbell_flyes.jpg',
      videoAsset: 'assets/feo_demos/dumbbell_flyes.mp4',
    );
  }

  // Cable crossover
  if (_containsAny(n, [
    'cable crossover', 'cable cross over', 'cable flyes', 'cable fly',
    'cruce de poleas', 'cruces de polea', 'cruce de polea',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.cableCrossover,
      titleEs: 'Cruce de poleas',
      cue: 'Desde poleas altas, juntá las manos al frente con pecho apretado',
      poseAsset: 'assets/feo_demos/cable_crossover.jpg',
      videoAsset: 'assets/feo_demos/cable_crossover.mp4',
    );
  }

  // Pec deck
  if (_containsAny(n, [
    'pec deck fly', 'pec deck', 'pec fly machine',
    'pec deck', 'mariposa pecho', 'contractora de pecho',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.pecDeckFly,
      titleEs: 'Pec deck / mariposa',
      cue: 'Brazos en los pads; juntá al frente apretando el pecho',
      poseAsset: 'assets/feo_demos/pec_deck_fly.jpg',
      videoAsset: 'assets/feo_demos/pec_deck_fly.mp4',
    );
  }

  // ─── BACK (15) — más específico primero ───

  if (_containsAny(n, [
    'straight arm pulldown', 'straight-arm pulldown',
    'jalon brazos extendidos', 'jalón brazos extendidos',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.straightArmPulldown,
      titleEs: 'Jalón brazos extendidos',
      cue: 'Brazos casi rectos; llevá la barra de arriba a los muslos con el dorsal',
      poseAsset: 'assets/feo_demos/straight_arm_pulldown.jpg',
      videoAsset: 'assets/feo_demos/straight_arm_pulldown.mp4',
    );
  }

  if (_containsAny(n, [
    'lat pulldown', 'lat pull down', 'jalon al pecho', 'jalón al pecho', 'jalon polea',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.latPulldown,
      titleEs: 'Jalón al pecho',
      cue: 'Tirones al pecho alto, pecho afuera, sin balancear el torso',
      poseAsset: 'assets/feo_demos/lat_pulldown.jpg',
      videoAsset: 'assets/feo_demos/lat_pulldown.mp4',
    );
  }

  if (_containsAny(n, [
    'chest supported row', 'chest-supported row', 'remo con apoyo', 'remo pecho apoyado',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.chestSupportedRow,
      titleEs: 'Remo con apoyo de pecho',
      cue: 'Pecho en el banco; remá sin usar impulso de la cadera',
      poseAsset: 'assets/feo_demos/chest_supported_row.jpg',
      videoAsset: 'assets/feo_demos/chest_supported_row.mp4',
    );
  }

  if (_containsAny(n, [
    'seated cable row', 'cable row', 'remo en polea', 'remo sentado', 'remo polea baja',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.seatedCableRow,
      titleEs: 'Remo en polea sentado',
      cue: 'Tirones al abdomen, codos cerca del cuerpo, torso estable',
      poseAsset: 'assets/feo_demos/seated_cable_row.jpg',
      videoAsset: 'assets/feo_demos/seated_cable_row.mp4',
    );
  }

  if (_containsAny(n, ['t bar row', 't-bar row', 'remo en t', 'remo t bar'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.tBarRow,
      titleEs: 'Remo en T',
      cue: 'Tirones a la caja torácica con espalda neutra',
      poseAsset: 'assets/feo_demos/t_bar_row.jpg',
      videoAsset: 'assets/feo_demos/t_bar_row.mp4',
    );
  }

  if (_containsAny(n, ['pendlay row', 'pendlay'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.pendlayRow,
      titleEs: 'Pendlay row',
      cue: 'Cada rep arranca del piso; tirón explosivo al pecho bajo',
      poseAsset: 'assets/feo_demos/pendlay_row.jpg',
      videoAsset: 'assets/feo_demos/pendlay_row.mp4',
    );
  }

  if (_containsAny(n, [
    'dumbbell row', 'one arm row', 'single arm row',
    'remo con mancuerna', 'remo mancuerna',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.dumbbellRow,
      titleEs: 'Remo con mancuerna',
      cue: 'Apoyá rodilla y mano; remá la mancuerna al costado de la cadera',
      poseAsset: 'assets/feo_demos/dumbbell_row.jpg',
      videoAsset: 'assets/feo_demos/dumbbell_row.mp4',
    );
  }

  if (_containsAny(n, [
    'barbell row', 'bent over row', 'bent-over row',
    'remo con barra', 'remo barra',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.barbellRow,
      titleEs: 'Remo con barra',
      cue: 'Bisagra de cadera; tirones a la costilla baja sin redondear la espalda',
      poseAsset: 'assets/feo_demos/barbell_row.jpg',
      videoAsset: 'assets/feo_demos/barbell_row.mp4',
    );
  }

  if (_containsAny(n, [
    'inverted row', 'bodyweight row', 'remo invertido', 'remo australiano',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.invertedRow,
      titleEs: 'Remo invertido',
      cue: 'Cuerpo recto bajo la barra; pecho hacia el agarre',
      poseAsset: 'assets/feo_demos/inverted_row.jpg',
      videoAsset: 'assets/feo_demos/inverted_row.mp4',
    );
  }

  if (_containsAny(n, ['rack pull', 'rack pulls', 'peso muerto parcial', 'rack pulls'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.rackPull,
      titleEs: 'Rack pull',
      cue: 'Barra a la altura de rodillas; lockout fuerte sin hiperextender',
      poseAsset: 'assets/feo_demos/rack_pull.jpg',
      videoAsset: 'assets/feo_demos/rack_pull.mp4',
    );
  }

  if (_containsAny(n, ['good morning', 'buenos dias', 'buenos días'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.goodMorning,
      titleEs: 'Good morning',
      cue: 'Barra en espalda alta; bisagra de cadera con rodillas blandas',
      poseAsset: 'assets/feo_demos/good_morning.jpg',
      videoAsset: 'assets/feo_demos/good_morning.mp4',
    );
  }

  if (_containsAny(n, ['superman', 'super man', 'supermans'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.superman,
      titleEs: 'Superman',
      cue: 'Boca abajo; elevá brazos y piernas sin forzar el cuello',
      poseAsset: 'assets/feo_demos/superman.jpg',
      videoAsset: 'assets/feo_demos/superman.mp4',
    );
  }

  if (_containsAny(n, [
    'chin up', 'chinup', 'chin ups', 'dominadas supinas', 'dominada supina',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.chinUp,
      titleEs: 'Dominadas supinas',
      cue: 'Agarre bajo la barra (supino); tirones hasta la barbilla',
      poseAsset: 'assets/feo_demos/chin_up.jpg',
      videoAsset: 'assets/feo_demos/chin_up.mp4',
    );
  }

  if (_containsAny(n, [
    'pull up', 'pullup', 'pull ups', 'dominadas', 'dominada',
  ]) && !_containsAny(n, ['lat pulldown', 'jalon', 'jalón', 'inverted'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.pullUp,
      titleEs: 'Dominadas',
      cue: 'Tirones con el pecho hacia la barra, controlá la bajada',
      poseAsset: 'assets/feo_demos/pull_up.jpg',
      videoAsset: 'assets/feo_demos/pull_up.mp4',
    );
  }

  // Deadlift (convencional y variantes RDL/SLDL usan mismo clip por ahora)
  if (_containsAny(n, [
    'deadlift', 'romanian deadlift', 'stiff legged deadlift',
    'peso muerto', 'peso muerto rumano',
  ]) && !_containsAny(n, ['rack pull'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.deadlift,
      titleEs: 'Peso muerto',
      cue: 'Bisagra de cadera, espalda neutra, empujá el piso al subir',
      poseAsset: 'assets/feo_demos/deadlift.jpg',
      videoAsset: 'assets/feo_demos/deadlift.mp4',
    );
  }

  // ─── Otros grupos ───

  if (_containsAny(n, ['jumping jack', 'jumping jacks', 'saltos de tijera', 'jumpingjack'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.jumpingJack,
      titleEs: 'Jumping jacks',
      cue: 'Abrí y cerrá piernas y brazos al mismo tiempo',
      poseAsset: 'assets/feo_demos/jumping_jack.jpg',
    );
  }

  if (_containsAny(n, ['mountain climber', 'mountain climbers', 'escalador', 'escaladores'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.mountainClimber,
      titleEs: 'Escaladores',
      cue: 'En plancha, llevá las rodillas al pecho en alternancia',
      poseAsset: 'assets/feo_demos/mountain_climber.jpg',
    );
  }

  if (_containsAny(n, ['burpee', 'burpees'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.burpee,
      titleEs: 'Burpees',
      cue: 'Agachate, plancha, pecho al piso y saltá arriba',
      poseAsset: 'assets/feo_demos/burpee.jpg',
    );
  }

  if (_containsAny(n, [
    'lunges', 'lunge', 'walking lunges', 'walking lunge', 'zancadas', 'zancada',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.lunge,
      titleEs: 'Zancadas',
      cue: 'Paso largo, rodilla atrás casi al piso, pecho erguido',
      poseAsset: 'assets/feo_demos/lunge.jpg',
    );
  }

  if (_containsAny(n, [
    'lateral raise', 'cable lateral raise', 'machine lateral raise',
    'elevaciones laterales', 'elevacion lateral',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.lateralRaise,
      titleEs: 'Elevaciones laterales',
      cue: 'Codos levemente flexionados, subí a la altura de hombros',
      poseAsset: 'assets/feo_demos/lateral_raise.jpg',
      videoAsset: 'assets/feo_demos/lateral_raise.mp4',
    );
  }

  if (_containsAny(n, [
    'overhead press', 'shoulder press', 'military press', 'arnold press',
    'dumbbell shoulder press', 'press militar', 'press de hombro', 'press overhead',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.overheadPress,
      titleEs: 'Press militar',
      cue: 'Empujá la carga por encima de la cabeza sin arquear la lumbar',
      poseAsset: 'assets/feo_demos/overhead_press.jpg',
      videoAsset: 'assets/feo_demos/overhead_press.mp4',
    );
  }

  if (_containsAny(n, [
    'triceps dip', 'bench dip', 'triceps pushdown', 'overhead triceps extension',
    'skullcrusher', 'triceps kickback', 'fondos en paralelas', 'fondos de triceps',
    'fondos de tríceps', 'jalon de triceps', 'jalón de tríceps',
    'extension de triceps', 'extensión de tríceps',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.tricepsDip,
      titleEs: 'Fondos / tríceps',
      cue: 'Codos cerca del cuerpo, bajá y extendé sin bloquear de golpe',
      poseAsset: 'assets/feo_demos/triceps_dip.jpg',
    );
  }

  if (_containsAny(n, [
    'bicycle crunch', 'reverse crunch', 'decline crunch', 'cable crunch',
    'crunch', 'crunches', 'abdominales', 'abdominal',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.crunch,
      titleEs: 'Crunch',
      cue: 'Enroscá el torso, no tires del cuello',
      poseAsset: 'assets/feo_demos/crunch.jpg',
    );
  }

  if (_containsAny(n, [
    'standing calf raise', 'standing calf raises',
    'elevacion de gemelos de pie', 'elevaciones de gemelos de pie',
    'pantorrilla de pie', 'gemelos de pie',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.standingCalfRaise,
      titleEs: 'Elevacion de gemelos de pie',
      cue: 'Subi los talones, pausa arriba y baja controlado sin doblar la rodilla',
      poseAsset: 'assets/feo_demos/standing_calf_raise.jpg',
      videoAsset: 'assets/feo_demos/standing_calf_raise.mp4',
    );
  }

  if (_containsAny(n, [
        'bodyweight squat', 'air squat', 'goblet squat', 'barbell squat',
        'front squat', 'sentadilla', 'squat',
      ]) &&
      !_containsAny(n, ['split squat', 'hack squat', 'bulgarian'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.squat,
      titleEs: 'Sentadilla',
      cue: 'Cadera atrás, pecho alto, subí empujando el piso',
      poseAsset: 'assets/feo_demos/squat.jpg',
      videoAsset: 'assets/feo_demos/squat.mp4',
    );
  }

  if (_containsAny(n, ['plank', 'plancha']) &&
      !_containsAny(n, ['side plank', 'plancha lateral'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.plank,
      titleEs: 'Plancha',
      cue: 'Cuerpo recto, abdomen firme, no dejes caer la cadera',
      poseAsset: 'assets/feo_demos/plank.jpg',
      videoAsset: 'assets/feo_demos/plank.mp4',
    );
  }

  if (_containsAny(n, [
    'dumbbell curl', 'barbell curl', 'hammer curl', 'preacher curl', 'cable curl',
    'concentration curl', 'curl de biceps', 'curl de bíceps', 'curl biceps',
    'curl mancuerna', 'curl con mancuernas',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.dumbbellCurl,
      titleEs: 'Curl de bíceps',
      cue: 'Codos fijos, subí sin balancear el cuerpo',
      poseAsset: 'assets/feo_demos/dumbbell_curl.jpg',
      videoAsset: 'assets/feo_demos/dumbbell_curl.mp4',
    );
  }

  return null;
}

String _normalize(String s) {
  return s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll(RegExp(r'[-_/]+'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9ñ ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _containsAny(String haystack, List<String> needles) {
  for (final n in needles) {
    if (haystack.contains(_normalize(n))) return true;
  }
  return false;
}
