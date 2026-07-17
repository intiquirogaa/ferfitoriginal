/**
 * Villanos de entrenamiento — combate animado + desafío con evidencia.
 * Feo (entrenador personal) se defiende cuando el usuario supera el reto.
 */

export type BattleChallenge = {
  /** id de ejercicio demo Feo / form-check */
  exerciseId: string;
  exerciseNameEn: string;
  exerciseNameEs: string;
  targetReps: number;
  /** Requiere video + calificación IA */
  requiresVideo: boolean;
  attackLine: string;
  defenseLine: string;
  successLine: string;
  failLine: string;
};

export type VillainDef = {
  id: string;
  name: string;
  epithet: string;
  coachBrief: string;
  defeatLine: string;
  exerciseKeywords: string[];
  seriesRequired: number;
  rewardCoins: number;
  icon: string;
  /** Asset Flutter relativo */
  portraitAsset: string;
  /** Clip de pelea in-app (ataque del villano vs Feo) */
  fightClipAsset: string;
  battle: BattleChallenge;
};

export const VILLAINS: VillainDef[] = [
  {
    id: "sedentario",
    name: "El Sedentario",
    epithet: "Señor del sillón",
    coachBrief:
      "Ataca con inercia. Feo se defiende si activás piernas con intención.",
    defeatLine: "El Sedentario se retrae. Buena activación de tren inferior.",
    exerciseKeywords: [
      "squat", "sentadilla", "lunge", "zancada", "leg press", "prensa",
      "calf", "gemelo", "glute", "hip thrust", "puente",
    ],
    seriesRequired: 8,
    rewardCoins: 35,
    icon: "🛋️",
    portraitAsset: "assets/villains/sedentario.jpg",
    fightClipAsset: "assets/battle/fight_sedentario.mp4",
    battle: {
      exerciseId: "bodyweight_squat",
      exerciseNameEn: "Bodyweight Squat",
      exerciseNameEs: "Sentadillas",
      targetReps: 15,
      requiresVideo: true,
      attackLine: "El Sedentario lanza un golpe de pereza hacia Feo…",
      defenseLine:
        "Feo bloquea. Para cerrar la defensa: 15 sentadillas con video. Técnica controlada.",
      successLine: "Defensa exitosa. Feo sostiene la posición. Villano debilitado.",
      failLine: "El ataque pasó. Reintentá el desafío con mejor rango y control.",
    },
  },
  {
    id: "postura_rota",
    name: "La Postura Rota",
    epithet: "Ladrona de hombros",
    coachBrief: "Presiona la postura. Defendé con tirones limpios y hombros estables.",
    defeatLine: "Postura restaurada. El tren superior respondió.",
    exerciseKeywords: [
      "row", "remo", "pull", "dominada", "pulldown", "jalon", "jalón",
      "face pull", "lateral raise", "elevacion", "elevación", "shoulder",
      "overhead press", "press militar", "shrug", "encogimiento",
    ],
    seriesRequired: 8,
    rewardCoins: 40,
    icon: "🦴",
    portraitAsset: "assets/villains/postura_rota.jpg",
    fightClipAsset: "assets/battle/fight_postura_rota.mp4",
    battle: {
      exerciseId: "lateral_raise",
      exerciseNameEn: "Lateral Raise",
      exerciseNameEs: "Elevaciones laterales",
      targetReps: 12,
      requiresVideo: true,
      attackLine: "La Postura Rota intenta hundir los hombros de Feo…",
      defenseLine:
        "Feo resiste. Completá 12 elevaciones laterales y enviá el video para validar.",
      successLine: "Hombros firmes. El ataque se disuelve.",
      failLine: "La postura cede un poco. Ajustá la técnica y reintentá.",
    },
  },
  {
    id: "pecho_de_piedra",
    name: "El Pecho de Piedra",
    epithet: "Bloqueador de empuje",
    coachBrief: "Bloquea el empuje. Respondé con flexiones de calidad.",
    defeatLine: "La piedra se rajar. Empuje controlado y efectivo.",
    exerciseKeywords: [
      "bench", "banca", "push", "flexion", "flexión", "chest", "pecho",
      "fly", "apertura", "dip", "fondo", "tricep", "trícep", "press",
    ],
    seriesRequired: 8,
    rewardCoins: 40,
    icon: "🗿",
    portraitAsset: "assets/villains/pecho_de_piedra.jpg",
    fightClipAsset: "assets/battle/fight_pecho_de_piedra.mp4",
    battle: {
      exerciseId: "push_up",
      exerciseNameEn: "Push-up",
      exerciseNameEs: "Flexiones",
      targetReps: 12,
      requiresVideo: true,
      attackLine: "El Pecho de Piedra avanza con un bloqueo pesado…",
      defenseLine:
        "Feo se defiende. Necesita 12 flexiones validadas por video e IA.",
      successLine: "Bloqueo roto. Feo recupera el control del combate.",
      failLine: "El bloqueo se mantiene. Más control en el descenso y reintentá.",
    },
  },
  {
    id: "core_flojo",
    name: "El Core Flojo",
    epithet: "Enemigo del centro",
    coachBrief: "Ataca el centro. Defendé con abdominales limpios — sin rebotes.",
    defeatLine: "Centro firme. El Core Flojo pierde fuerza.",
    exerciseKeywords: [
      "plank", "plancha", "crunch", "abdominal", "twist", "giro",
      "dead bug", "bird dog", "leg raise", "elevacion de piernas",
      "mountain climber", "escalador", "ab wheel", "rueda",
    ],
    seriesRequired: 6,
    rewardCoins: 40,
    icon: "🌀",
    portraitAsset: "assets/villains/core_flojo.jpg",
    fightClipAsset: "assets/battle/fight_core_flojo.mp4",
    battle: {
      exerciseId: "crunch",
      exerciseNameEn: "Crunch",
      exerciseNameEs: "Abdominales (crunch)",
      targetReps: 20,
      requiresVideo: true,
      attackLine: "El Core Flojo lanza una onda blanda al tronco de Feo…",
      defenseLine:
        "Feo se defiende. Completá 20 abdominales (crunch), grabá el video y la IA evaluará si cumpliste.",
      successLine: "Defensa perfecta. El centro aguanta y el villano cae.",
      failLine: "No alcanzó la calidad/cantidad. Revisá el feedback y reintentá.",
    },
  },
  {
    id: "excusas",
    name: "Las Excusas",
    epithet: "Maestras del aplazamiento",
    coachBrief: "Atacan con dilación. Defendé ejecutando cardio simple y real.",
    defeatLine: "Sin vueltas: cumpliste. Las Excusas se quedan sin material.",
    exerciseKeywords: [
      "burpee", "jumping", "tijera", "high knee", "rodilla", "jump rope",
      "soga", "box jump", "cajon", "cajón", "kettlebell", "swing",
      "cat cow", "gato", "hip rotation", "torso twist",
    ],
    seriesRequired: 5,
    rewardCoins: 30,
    icon: "💬",
    portraitAsset: "assets/villains/excusas.jpg",
    fightClipAsset: "assets/battle/fight_excusas.mp4",
    battle: {
      exerciseId: "jumping_jack",
      exerciseNameEn: "Jumping Jack",
      exerciseNameEs: "Jumping jacks",
      targetReps: 20,
      requiresVideo: true,
      attackLine: "Las Excusas intentan congelar a Feo con “después lo hago”…",
      defenseLine:
        "Feo necesita acción ya: 20 jumping jacks con video validado.",
      successLine: "Acción > excusa. Feo avanza y el villano se desvanece.",
      failLine: "Todavía hay espacio para excusas. Reintentá con más intención.",
    },
  },
];

export function getVillainById(id: string): VillainDef | undefined {
  return VILLAINS.find((v) => v.id === id);
}

export function pickVillainForDay(userId: number, daySeed: string): VillainDef {
  let hash = userId;
  for (let i = 0; i < daySeed.length; i++) {
    hash = (hash * 31 + daySeed.charCodeAt(i)) >>> 0;
  }
  return VILLAINS[hash % VILLAINS.length];
}

export function exerciseMatchesVillain(
  exerciseName: string,
  villain: VillainDef
): boolean {
  const n = exerciseName
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{M}/gu, "");
  return villain.exerciseKeywords.some((kw) => {
    const k = kw
      .toLowerCase()
      .normalize("NFD")
      .replace(/\p{M}/gu, "");
    return n.includes(k);
  });
}

export function publicVillain(v: VillainDef) {
  return {
    id: v.id,
    name: v.name,
    epithet: v.epithet,
    coachBrief: v.coachBrief,
    defeatLine: v.defeatLine,
    icon: v.icon,
    portraitAsset: v.portraitAsset,
    fightClipAsset: v.fightClipAsset,
    seriesRequired: v.seriesRequired,
    rewardCoins: v.rewardCoins,
    battle: v.battle,
  };
}
