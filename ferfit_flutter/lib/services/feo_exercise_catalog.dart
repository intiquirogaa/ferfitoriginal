// Demos Feo: assets/feo_demos/{id}.jpg (+ .mp4)
// Catálogo 99 completo: CHEST/BACK/LEGS/SHOULDERS/ARMS/CORE/CARDIO (Feo ref: mascot_happy)

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
  // LEGS (20)
  barbellSquat,
  frontSquat,
  gobletSquat,
  bodyweightSquat,
  legPress,
  hackSquat,
  bulgarianSplitSquat,
  lunges,
  walkingLunges,
  romanianDeadlift,
  stiffLeggedDeadlift,
  legExtension,
  legCurl,
  seatedLegCurl,
  lyingLegCurl,
  hipThrust,
  gluteBridge,
  calfRaise,
  seatedCalfRaise,
  standingCalfRaise,
  // SHOULDERS (14)
  overheadPress,
  dumbbellShoulderPress,
  arnoldPress,
  lateralRaise,
  cableLateralRaise,
  machineLateralRaise,
  frontRaise,
  dumbbellFrontRaise,
  reversePecDeck,
  facePull,
  dumbbellRearDeltRow,
  uprightRow,
  barbellShrug,
  dumbbellShrug,
  // ARMS extras
  closeGripBenchPress,
  // CORE extras
  russianTwist,
  sidePlank,
  abWheelRollout,
  hangingLegRaise,
  deadBug,
  birdDog,
  // CARDIO_MOBILITY
  highKnees,
  jumpRope,
  boxJump,
  kettlebellSwing,
  shoulderDislocates,
  catCow,
  hipRotations,
  torsoTwist,
  // otros
  squat,
  plank,
  dumbbellCurl,
  lunge,
  burpee,
  mountainClimber,
  tricepsDip,
  crunch,
  jumpingJack,
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

  // Close-grip bench (antes del flat genérico)
  if (_containsAny(n, [
    'close grip bench', 'close-grip bench', 'press banca agarre cerrado',
    'press de banca agarre cerrado', 'press agarre cerrado',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.closeGripBenchPress,
      titleEs: 'Press banca agarre cerrado',
      cue: 'Agarre estrecho, codos cerca del torso, empujá con tríceps',
      poseAsset: 'assets/feo_demos/close_grip_bench_press.jpg',
      videoAsset: 'assets/feo_demos/close_grip_bench_press.mp4',
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

  // Deadlift convencional (RDL/SLDL más abajo en LEGS)
  if (_containsAny(n, ['deadlift', 'peso muerto']) &&
      !_containsAny(n, [
        'rack pull', 'romanian', 'stiff', 'rumano', 'piernas rigidas', 'piernas rígidas',
      ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.deadlift,
      titleEs: 'Peso muerto',
      cue: 'Bisagra de cadera, espalda neutra, empujá el piso al subir',
      poseAsset: 'assets/feo_demos/deadlift.jpg',
      videoAsset: 'assets/feo_demos/deadlift.mp4',
    );
  }

  // ─── LEGS (20) ───

  if (_containsAny(n, [
    'bulgarian split squat', 'bulgarian', 'sentadilla bulgara', 'sentadilla búlgara',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.bulgarianSplitSquat,
      titleEs: 'Sentadilla búlgara',
      cue: 'Pie de atrás elevado; bajá la rodilla delantera controlado',
      poseAsset: 'assets/feo_demos/bulgarian_split_squat.jpg',
      videoAsset: 'assets/feo_demos/bulgarian_split_squat.mp4',
    );
  }

  if (_containsAny(n, ['hack squat', 'sentadilla hack'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.hackSquat,
      titleEs: 'Hack squat',
      cue: 'Espalda en el respaldo; empujá el piso con los talones',
      poseAsset: 'assets/feo_demos/hack_squat.jpg',
      videoAsset: 'assets/feo_demos/hack_squat.mp4',
    );
  }

  if (_containsAny(n, ['front squat', 'sentadilla frontal'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.frontSquat,
      titleEs: 'Sentadilla frontal',
      cue: 'Barra en deltoides; codos altos, torso erguido',
      poseAsset: 'assets/feo_demos/front_squat.jpg',
      videoAsset: 'assets/feo_demos/front_squat.mp4',
    );
  }

  if (_containsAny(n, ['goblet squat', 'sentadilla goblet'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.gobletSquat,
      titleEs: 'Sentadilla goblet',
      cue: 'Mancuerna al pecho; sentate entre los talones',
      poseAsset: 'assets/feo_demos/goblet_squat.jpg',
      videoAsset: 'assets/feo_demos/goblet_squat.mp4',
    );
  }

  if (_containsAny(n, ['barbell squat', 'back squat', 'sentadilla con barra'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.barbellSquat,
      titleEs: 'Sentadilla con barra',
      cue: 'Barra en trapecio; cadera atrás y pecho alto',
      poseAsset: 'assets/feo_demos/barbell_squat.jpg',
      videoAsset: 'assets/feo_demos/barbell_squat.mp4',
    );
  }

  if (_containsAny(n, [
    'bodyweight squat', 'air squat', 'sentadilla libre', 'sentadilla peso corporal',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.bodyweightSquat,
      titleEs: 'Sentadilla (peso corporal)',
      cue: 'Cadera atrás, pecho alto, subí empujando el piso',
      poseAsset: 'assets/feo_demos/bodyweight_squat.jpg',
      videoAsset: 'assets/feo_demos/bodyweight_squat.mp4',
    );
  }

  if (_containsAny(n, ['leg press', 'prensa de piernas', 'prensa piernas'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.legPress,
      titleEs: 'Prensa de piernas',
      cue: 'Pies a la altura de hombros; no bloquees de golpe',
      poseAsset: 'assets/feo_demos/leg_press.jpg',
      videoAsset: 'assets/feo_demos/leg_press.mp4',
    );
  }

  if (_containsAny(n, ['walking lunges', 'walking lunge', 'zancadas caminando'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.walkingLunges,
      titleEs: 'Zancadas caminando',
      cue: 'Paso largo adelante, controlá la bajada y avanzá',
      poseAsset: 'assets/feo_demos/walking_lunges.jpg',
      videoAsset: 'assets/feo_demos/walking_lunges.mp4',
    );
  }

  if (_containsAny(n, ['lunges', 'lunge', 'zancadas', 'zancada'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.lunges,
      titleEs: 'Zancadas',
      cue: 'Paso largo, rodilla atrás casi al piso, pecho erguido',
      poseAsset: 'assets/feo_demos/lunges.jpg',
      videoAsset: 'assets/feo_demos/lunges.mp4',
    );
  }

  if (_containsAny(n, [
    'romanian deadlift', 'peso muerto rumano', 'rdl',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.romanianDeadlift,
      titleEs: 'Peso muerto rumano',
      cue: 'Bisagra de cadera, barra cerca de piernas, ligera flexión de rodillas',
      poseAsset: 'assets/feo_demos/romanian_deadlift.jpg',
      videoAsset: 'assets/feo_demos/romanian_deadlift.mp4',
    );
  }

  if (_containsAny(n, [
    'stiff legged deadlift', 'stiff-legged deadlift',
    'peso muerto piernas rigidas', 'peso muerto piernas rígidas',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.stiffLeggedDeadlift,
      titleEs: 'Peso muerto piernas rígidas',
      cue: 'Piernas casi rectas; sentí el estirón en isquios',
      poseAsset: 'assets/feo_demos/stiff_legged_deadlift.jpg',
      videoAsset: 'assets/feo_demos/stiff_legged_deadlift.mp4',
    );
  }

  if (_containsAny(n, ['leg extension', 'extension de cuádriceps', 'extension de cuadriceps', 'extensión de cuádriceps'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.legExtension,
      titleEs: 'Extensión de cuádriceps',
      cue: 'Extiende rodillas sin rebotar arriba',
      poseAsset: 'assets/feo_demos/leg_extension.jpg',
      videoAsset: 'assets/feo_demos/leg_extension.mp4',
    );
  }

  if (_containsAny(n, ['seated leg curl', 'curl femoral sentado'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.seatedLegCurl,
      titleEs: 'Curl femoral sentado',
      cue: 'Llevá talones hacia el asiento controlado',
      poseAsset: 'assets/feo_demos/seated_leg_curl.jpg',
      videoAsset: 'assets/feo_demos/seated_leg_curl.mp4',
    );
  }

  if (_containsAny(n, ['lying leg curl', 'curl femoral acostado', 'curl femoral tumbado'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.lyingLegCurl,
      titleEs: 'Curl femoral acostado',
      cue: 'Talones hacia glúteos, cadera pegada al banco',
      poseAsset: 'assets/feo_demos/lying_leg_curl.jpg',
      videoAsset: 'assets/feo_demos/lying_leg_curl.mp4',
    );
  }

  if (_containsAny(n, ['leg curl', 'curl femoral', 'femoral'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.legCurl,
      titleEs: 'Curl femoral',
      cue: 'Flexioná rodillas con control, sin balancear',
      poseAsset: 'assets/feo_demos/leg_curl.jpg',
      videoAsset: 'assets/feo_demos/leg_curl.mp4',
    );
  }

  if (_containsAny(n, ['hip thrust', 'empuje de cadera', 'hip thrust'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.hipThrust,
      titleEs: 'Hip thrust',
      cue: 'Empujá cadera arriba, apretá glúteos arriba',
      poseAsset: 'assets/feo_demos/hip_thrust.jpg',
      videoAsset: 'assets/feo_demos/hip_thrust.mp4',
    );
  }

  if (_containsAny(n, ['glute bridge', 'puente de gluteos', 'puente de glúteos'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.gluteBridge,
      titleEs: 'Puente de glúteos',
      cue: 'Hombros en el piso; elevá cadera y apretá arriba',
      poseAsset: 'assets/feo_demos/glute_bridge.jpg',
      videoAsset: 'assets/feo_demos/glute_bridge.mp4',
    );
  }

  if (_containsAny(n, [
    'seated calf raise', 'elevacion de gemelos sentado', 'elevaciones de gemelos sentado',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.seatedCalfRaise,
      titleEs: 'Gemelos sentado',
      cue: 'Subí talones al máximo, pausa y bajá',
      poseAsset: 'assets/feo_demos/seated_calf_raise.jpg',
      videoAsset: 'assets/feo_demos/seated_calf_raise.mp4',
    );
  }

  if (_containsAny(n, [
    'standing calf raise', 'standing calf raises',
    'elevacion de gemelos de pie', 'elevaciones de gemelos de pie',
    'pantorrilla de pie', 'gemelos de pie',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.standingCalfRaise,
      titleEs: 'Gemelos de pie',
      cue: 'Subí los talones, pausa arriba y bajá controlado',
      poseAsset: 'assets/feo_demos/standing_calf_raise.jpg',
      videoAsset: 'assets/feo_demos/standing_calf_raise.mp4',
    );
  }

  if (_containsAny(n, ['calf raise', 'elevacion de gemelos', 'elevaciones de gemelos', 'gemelos', 'pantorrillas'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.calfRaise,
      titleEs: 'Elevación de gemelos',
      cue: 'Subí talones al máximo sin rebotar',
      poseAsset: 'assets/feo_demos/calf_raise.jpg',
      videoAsset: 'assets/feo_demos/calf_raise.mp4',
    );
  }

  // squat genérico (fallback)
  if (_containsAny(n, ['sentadilla', 'squat']) &&
      !_containsAny(n, ['split squat', 'hack squat', 'bulgarian', 'goblet', 'front'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.squat,
      titleEs: 'Sentadilla',
      cue: 'Cadera atrás, pecho alto, subí empujando el piso',
      poseAsset: 'assets/feo_demos/bodyweight_squat.jpg',
      videoAsset: 'assets/feo_demos/bodyweight_squat.mp4',
    );
  }

  // ─── SHOULDERS (14) ───

  if (_containsAny(n, ['arnold press', 'press arnold'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.arnoldPress,
      titleEs: 'Press Arnold',
      cue: 'Rotá palmas al subir; controlá la bajada',
      poseAsset: 'assets/feo_demos/arnold_press.jpg',
      videoAsset: 'assets/feo_demos/arnold_press.mp4',
    );
  }

  if (_containsAny(n, [
    'dumbbell shoulder press', 'press de hombro con mancuernas', 'press hombro mancuernas',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.dumbbellShoulderPress,
      titleEs: 'Press de hombro con mancuernas',
      cue: 'Empujá vertical sin arquear la lumbar',
      poseAsset: 'assets/feo_demos/dumbbell_shoulder_press.jpg',
      videoAsset: 'assets/feo_demos/dumbbell_shoulder_press.mp4',
    );
  }

  if (_containsAny(n, [
    'overhead press', 'military press', 'press militar', 'press overhead', 'shoulder press',
    'press de hombro',
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
    'cable lateral raise', 'elevacion lateral en polea', 'elevaciones laterales en polea',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.cableLateralRaise,
      titleEs: 'Elevación lateral en polea',
      cue: 'Codo levemente flexionado; subí a la altura del hombro',
      poseAsset: 'assets/feo_demos/cable_lateral_raise.jpg',
      videoAsset: 'assets/feo_demos/cable_lateral_raise.mp4',
    );
  }

  if (_containsAny(n, [
    'machine lateral raise', 'elevacion lateral en maquina', 'elevación lateral en máquina',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.machineLateralRaise,
      titleEs: 'Elevación lateral en máquina',
      cue: 'Empujá los pads hacia afuera con control',
      poseAsset: 'assets/feo_demos/machine_lateral_raise.jpg',
      videoAsset: 'assets/feo_demos/machine_lateral_raise.mp4',
    );
  }

  if (_containsAny(n, [
    'lateral raise', 'elevaciones laterales', 'elevacion lateral',
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
    'dumbbell front raise', 'front raise', 'elevacion frontal', 'elevaciones frontales',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.frontRaise,
      titleEs: 'Elevaciones frontales',
      cue: 'Subí brazos al frente hasta la altura de hombros',
      poseAsset: 'assets/feo_demos/front_raise.jpg',
      videoAsset: 'assets/feo_demos/front_raise.mp4',
    );
  }

  if (_containsAny(n, [
    'reverse pec deck', 'pec deck reverse', 'aperturas inversas', 'mariposa inversa',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.reversePecDeck,
      titleEs: 'Pec deck inverso',
      cue: 'Abrí brazos atrás enfocando deltoides posteriores',
      poseAsset: 'assets/feo_demos/reverse_pec_deck.jpg',
      videoAsset: 'assets/feo_demos/reverse_pec_deck.mp4',
    );
  }

  if (_containsAny(n, ['face pull', 'jalon a la cara', 'jalón a la cara'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.facePull,
      titleEs: 'Face pull',
      cue: 'Tirones a la cara, codos altos, rotación externa',
      poseAsset: 'assets/feo_demos/face_pull.jpg',
      videoAsset: 'assets/feo_demos/face_pull.mp4',
    );
  }

  if (_containsAny(n, [
    'dumbbell rear delt row', 'rear delt row', 'remo deltoides posterior',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.dumbbellRearDeltRow,
      titleEs: 'Remo deltoides posterior',
      cue: 'Tirones abiertos hacia afuera, no al codo del torso',
      poseAsset: 'assets/feo_demos/dumbbell_rear_delt_row.jpg',
      videoAsset: 'assets/feo_demos/dumbbell_rear_delt_row.mp4',
    );
  }

  if (_containsAny(n, ['upright row', 'remo al menton', 'remo al mentón', 'remo vertical'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.uprightRow,
      titleEs: 'Remo al mentón',
      cue: 'Codos altos; subí la barra hasta el pecho alto',
      poseAsset: 'assets/feo_demos/upright_row.jpg',
      videoAsset: 'assets/feo_demos/upright_row.mp4',
    );
  }

  if (_containsAny(n, ['barbell shrug', 'encogimientos con barra', 'encogimiento con barra'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.barbellShrug,
      titleEs: 'Encogimientos con barra',
      cue: 'Subí hombros a las orejas sin girar el cuello',
      poseAsset: 'assets/feo_demos/barbell_shrug.jpg',
      videoAsset: 'assets/feo_demos/barbell_shrug.mp4',
    );
  }

  if (_containsAny(n, [
    'dumbbell shrug', 'encogimientos con mancuernas', 'encogimiento de hombros', 'shrugs', 'shrug',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.dumbbellShrug,
      titleEs: 'Encogimientos con mancuernas',
      cue: 'Subí hombros vertical, pausa y bajá',
      poseAsset: 'assets/feo_demos/dumbbell_shrug.jpg',
      videoAsset: 'assets/feo_demos/dumbbell_shrug.mp4',
    );
  }

  // ─── CARDIO / MOVILIDAD ───

  if (_containsAny(n, ['jumping jack', 'jumping jacks', 'saltos de tijera', 'jumpingjack'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.jumpingJack,
      titleEs: 'Jumping jacks',
      cue: 'Abrí y cerrá piernas y brazos al mismo tiempo',
      poseAsset: 'assets/feo_demos/jumping_jack.jpg',
      videoAsset: 'assets/feo_demos/jumping_jack.mp4',
    );
  }

  if (_containsAny(n, ['high knees', 'high knee', 'rodillas altas', 'elevacion de rodillas', 'elevación de rodillas'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.highKnees,
      titleEs: 'Rodillas altas',
      cue: 'Corré en el lugar llevando las rodillas al pecho',
      poseAsset: 'assets/feo_demos/high_knees.jpg',
      videoAsset: 'assets/feo_demos/high_knees.mp4',
    );
  }

  if (_containsAny(n, ['jump rope', 'jumping rope', 'saltar la soga', 'cuerda', 'comba'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.jumpRope,
      titleEs: 'Saltar la soga',
      cue: 'Saltos chicos, muñecas fluidas, ritmo constante',
      poseAsset: 'assets/feo_demos/jump_rope.jpg',
      videoAsset: 'assets/feo_demos/jump_rope.mp4',
    );
  }

  if (_containsAny(n, ['box jump', 'box jumps', 'salto al cajon', 'salto al cajón', 'saltos al cajon'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.boxJump,
      titleEs: 'Salto al cajón',
      cue: 'Impulsá con cadera y aterrizá suave sobre el cajón',
      poseAsset: 'assets/feo_demos/box_jump.jpg',
      videoAsset: 'assets/feo_demos/box_jump.mp4',
    );
  }

  if (_containsAny(n, ['kettlebell swing', 'kb swing', 'swing con kettlebell', 'balanceo de kettlebell', 'swing kettlebell'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.kettlebellSwing,
      titleEs: 'Kettlebell swing',
      cue: 'Bisagra de cadera, no sentadilla; empuje explosivo de glúteos',
      poseAsset: 'assets/feo_demos/kettlebell_swing.jpg',
      videoAsset: 'assets/feo_demos/kettlebell_swing.mp4',
    );
  }

  if (_containsAny(n, [
    'shoulder dislocates', 'shoulder dislocate', 'dislocaciones de hombro',
    'dislocacion de hombros', 'dislocación de hombros', 'pass through',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.shoulderDislocates,
      titleEs: 'Dislocaciones de hombro',
      cue: 'Palo con agarre amplio; pasalo por arriba sin forzar',
      poseAsset: 'assets/feo_demos/shoulder_dislocates.jpg',
      videoAsset: 'assets/feo_demos/shoulder_dislocates.mp4',
    );
  }

  if (_containsAny(n, ['cat cow', 'cat-cow', 'gato gato', 'gato-vaca', 'gato vaca'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.catCow,
      titleEs: 'Gato-vaca',
      cue: 'En cuatro apoyos, alterná arquear y redondear la espalda',
      poseAsset: 'assets/feo_demos/cat_cow.jpg',
      videoAsset: 'assets/feo_demos/cat_cow.mp4',
    );
  }

  if (_containsAny(n, ['hip rotations', 'hip rotation', 'rotaciones de cadera', 'rotacion de cadera', 'rotación de cadera'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.hipRotations,
      titleEs: 'Rotaciones de cadera',
      cue: 'Círculos controlados de cadera, tronco estable',
      poseAsset: 'assets/feo_demos/hip_rotations.jpg',
      videoAsset: 'assets/feo_demos/hip_rotations.mp4',
    );
  }

  if (_containsAny(n, ['torso twist', 'torso twists', 'giros de torso', 'rotacion de torso', 'rotación de torso'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.torsoTwist,
      titleEs: 'Giro de torso',
      cue: 'Girás el tronco manteniendo cadera al frente',
      poseAsset: 'assets/feo_demos/torso_twist.jpg',
      videoAsset: 'assets/feo_demos/torso_twist.mp4',
    );
  }

  if (_containsAny(n, ['mountain climber', 'mountain climbers', 'escalador', 'escaladores'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.mountainClimber,
      titleEs: 'Escaladores',
      cue: 'En plancha, llevá las rodillas al pecho en alternancia',
      poseAsset: 'assets/feo_demos/mountain_climber.jpg',
      videoAsset: 'assets/feo_demos/mountain_climber.mp4',
    );
  }

  if (_containsAny(n, ['burpee', 'burpees'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.burpee,
      titleEs: 'Burpees',
      cue: 'Agachate, plancha, pecho al piso y saltá arriba',
      poseAsset: 'assets/feo_demos/burpee.jpg',
      videoAsset: 'assets/feo_demos/burpee.mp4',
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
      videoAsset: 'assets/feo_demos/triceps_dip.mp4',
    );
  }

  if (_containsAny(n, ['russian twist', 'russian twists', 'giro ruso', 'giros rusos'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.russianTwist,
      titleEs: 'Giro ruso',
      cue: 'Torso inclinado, girá de lado a lado sin redondear la espalda',
      poseAsset: 'assets/feo_demos/russian_twist.jpg',
      videoAsset: 'assets/feo_demos/russian_twist.mp4',
    );
  }

  if (_containsAny(n, ['side plank', 'plancha lateral', 'plancha de lado'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.sidePlank,
      titleEs: 'Plancha lateral',
      cue: 'Cuerpo en línea, cadera arriba, no dejes caer el tronco',
      poseAsset: 'assets/feo_demos/side_plank.jpg',
      videoAsset: 'assets/feo_demos/side_plank.mp4',
    );
  }

  if (_containsAny(n, [
    'ab wheel', 'ab wheel rollout', 'rueda abdominal', 'rollout',
    'rueda de abdominales',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.abWheelRollout,
      titleEs: 'Rueda abdominal',
      cue: 'Rodá hacia adelante con control y volvé sin arquear la lumbar',
      poseAsset: 'assets/feo_demos/ab_wheel_rollout.jpg',
      videoAsset: 'assets/feo_demos/ab_wheel_rollout.mp4',
    );
  }

  if (_containsAny(n, [
    'hanging leg raise', 'hanging leg raises', 'elevacion de piernas colgado',
    'elevación de piernas colgado', 'elevaciones de piernas en barra',
  ])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.hangingLegRaise,
      titleEs: 'Elevación de piernas colgado',
      cue: 'Subí las piernas con el abdomen, sin balancear el cuerpo',
      poseAsset: 'assets/feo_demos/hanging_leg_raise.jpg',
      videoAsset: 'assets/feo_demos/hanging_leg_raise.mp4',
    );
  }

  if (_containsAny(n, ['dead bug', 'deadbug', 'bicho muerto'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.deadBug,
      titleEs: 'Dead bug',
      cue: 'Espalda pegada al piso, extendé brazo y pierna opuestos',
      poseAsset: 'assets/feo_demos/dead_bug.jpg',
      videoAsset: 'assets/feo_demos/dead_bug.mp4',
    );
  }

  if (_containsAny(n, ['bird dog', 'bird-dog', 'perro de caza', 'cuadrupedia'])) {
    return const FeoExerciseDemoInfo(
      kind: FeoExerciseDemoKind.birdDog,
      titleEs: 'Bird dog',
      cue: 'En cuatro apoyos, extendé brazo y pierna opuestos sin girar la cadera',
      poseAsset: 'assets/feo_demos/bird_dog.jpg',
      videoAsset: 'assets/feo_demos/bird_dog.mp4',
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
      videoAsset: 'assets/feo_demos/crunch.mp4',
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
