// RAG Catalog of Exercises
// These are known, standard exercise names that resolve well in ExerciseDB API

export const EXERCISE_CATALOG = {
  CHEST: [
    "Bench Press", "Incline Bench Press", "Decline Bench Press",
    "Dumbbell Bench Press", "Incline Dumbbell Press", "Decline Dumbbell Press",
    "Dumbbell Flyes", "Cable Crossover", "Pec Deck Fly", 
    "Push-up", "Decline Push-up", "Incline Push-up", "Diamond Push-up",
    "Machine Chest Press"
  ],
  BACK: [
    "Pull-up", "Chin-up", "Lat Pulldown", "Straight Arm Pulldown",
    "Barbell Row", "Dumbbell Row", "Pendlay Row", "T-Bar Row",
    "Seated Cable Row", "Chest Supported Row", 
    "Deadlift", "Rack Pull", "Good Morning", "Superman", "Inverted Row"
  ],
  LEGS: [
    "Barbell Squat", "Front Squat", "Goblet Squat", "Bodyweight Squat",
    "Leg Press", "Hack Squat", "Bulgarian Split Squat", "Lunges", "Walking Lunges",
    "Romanian Deadlift", "Stiff-Legged Deadlift", "Leg Extension", "Leg Curl", 
    "Seated Leg Curl", "Lying Leg Curl", "Hip Thrust", "Glute Bridge",
    "Calf Raise", "Seated Calf Raise", "Standing Calf Raise"
  ],
  SHOULDERS: [
    "Overhead Press", "Dumbbell Shoulder Press", "Arnold Press",
    "Lateral Raise", "Cable Lateral Raise", "Machine Lateral Raise",
    "Front Raise", "Dumbbell Front Raise",
    "Reverse Pec Deck", "Face Pull", "Dumbbell Rear Delt Row",
    "Upright Row", "Barbell Shrug", "Dumbbell Shrug"
  ],
  ARMS: [
    "Barbell Curl", "Dumbbell Curl", "Hammer Curl", "Preacher Curl", "Cable Curl", "Concentration Curl",
    "Triceps Pushdown", "Overhead Triceps Extension", "Skullcrusher", 
    "Close Grip Bench Press", "Triceps Dip", "Bench Dip", "Triceps Kickback"
  ],
  CORE: [
    "Crunch", "Reverse Crunch", "Bicycle Crunch", "Russian Twist",
    "Plank", "Side Plank", "Ab Wheel Rollout", "Hanging Leg Raise", 
    "Cable Crunch", "Decline Crunch", "Mountain Climber", "Dead Bug", "Bird Dog"
  ],
  CARDIO_MOBILITY: [
    "Burpee", "Jumping Jack", "High Knees", "Jump Rope",
    "Box Jump", "Kettlebell Swing",
    "Shoulder Dislocates", "Cat-Cow", "Hip Rotations", "Torso Twist"
  ]
};

export type MuscleGroup = keyof typeof EXERCISE_CATALOG;

const GROUP_ALIASES: Record<string, MuscleGroup> = {
  chest: "CHEST",
  pecho: "CHEST",
  pectoral: "CHEST",
  pectorals: "CHEST",
  back: "BACK",
  espalda: "BACK",
  lats: "BACK",
  legs: "LEGS",
  leg: "LEGS",
  piernas: "LEGS",
  pierna: "LEGS",
  glutes: "LEGS",
  gluteos: "LEGS",
  quads: "LEGS",
  hamstrings: "LEGS",
  shoulders: "SHOULDERS",
  shoulder: "SHOULDERS",
  hombros: "SHOULDERS",
  hombro: "SHOULDERS",
  delts: "SHOULDERS",
  arms: "ARMS",
  arm: "ARMS",
  brazos: "ARMS",
  biceps: "ARMS",
  triceps: "ARMS",
  core: "CORE",
  abs: "CORE",
  abdomen: "CORE",
  abdominales: "CORE",
  cardio: "CARDIO_MOBILITY",
  mobility: "CARDIO_MOBILITY",
  movilidad: "CARDIO_MOBILITY",
  warmup: "CARDIO_MOBILITY",
  calentamiento: "CARDIO_MOBILITY",
};

function normalizeName(name: string): string {
  return (name || "").toLowerCase().trim().replace(/\s+/g, " ");
}

/** Busca el grupo muscular del catálogo por nombre EN/ES del ejercicio. */
export function findExerciseGroup(name: string): MuscleGroup | null {
  const n = normalizeName(name);
  if (!n) return null;
  for (const [group, exercises] of Object.entries(EXERCISE_CATALOG) as [MuscleGroup, string[]][]) {
    for (const ex of exercises) {
      if (normalizeName(ex) === n) return group;
    }
  }
  // Match parcial (ej. "Dumbbell Bench Press (hypertrophy)")
  for (const [group, exercises] of Object.entries(EXERCISE_CATALOG) as [MuscleGroup, string[]][]) {
    for (const ex of exercises) {
      const en = normalizeName(ex);
      if (n.includes(en) || en.includes(n)) return group;
    }
  }
  return null;
}

/** Resuelve un hint de grupo (campo muscleGroup / focus del día) al catálogo. */
export function resolveGroupHint(hint?: string | null): MuscleGroup | null {
  if (!hint) return null;
  const h = normalizeName(hint);
  if ((EXERCISE_CATALOG as Record<string, string[]>)[hint.toUpperCase()]) {
    return hint.toUpperCase() as MuscleGroup;
  }
  for (const [alias, group] of Object.entries(GROUP_ALIASES)) {
    if (h.includes(alias)) return group;
  }
  return null;
}

/** Nombre canónico del catálogo si existe; si no, null. */
export function resolveCatalogName(name: string): string | null {
  const n = normalizeName(name);
  if (!n) return null;
  for (const exercises of Object.values(EXERCISE_CATALOG)) {
    for (const ex of exercises) {
      if (normalizeName(ex) === n) return ex;
    }
  }
  for (const exercises of Object.values(EXERCISE_CATALOG)) {
    for (const ex of exercises) {
      const en = normalizeName(ex);
      if (n.includes(en) || en.includes(n)) return ex;
    }
  }
  return null;
}

export function listCatalogExercises(group?: MuscleGroup | null): string[] {
  if (group && EXERCISE_CATALOG[group]) return [...EXERCISE_CATALOG[group]];
  return Object.values(EXERCISE_CATALOG).flat();
}

/**
 * Candidatos de reemplazo del mismo grupo muscular, excluyendo el actual
 * y los que ya están en el día (para no duplicar).
 */
export function getReplacementCandidates(opts: {
  currentName: string;
  dayExerciseNames?: string[];
  muscleGroupHint?: string | null;
}): { group: MuscleGroup | null; candidates: string[] } {
  const current = normalizeName(opts.currentName);
  const excluded = new Set(
    (opts.dayExerciseNames || []).map(normalizeName).filter(Boolean)
  );
  excluded.add(current);

  let group =
    findExerciseGroup(opts.currentName) ||
    resolveGroupHint(opts.muscleGroupHint);

  let pool = listCatalogExercises(group);
  let candidates = pool.filter((ex) => !excluded.has(normalizeName(ex)));

  // Si el grupo quedó vacío (día saturado del mismo grupo), abrir catálogo completo
  if (candidates.length === 0) {
    group = null;
    pool = listCatalogExercises(null);
    candidates = pool.filter((ex) => !excluded.has(normalizeName(ex)));
  }

  return { group, candidates };
}

/**
 * Elige un reemplazo: preferredName si es válido; si no, el siguiente distinto
 * (hash estable por índice del actual para no ser totalmente aleatorio).
 */
export function pickReplacementExercise(opts: {
  currentName: string;
  dayExerciseNames?: string[];
  muscleGroupHint?: string | null;
  preferredName?: string | null;
}): { name: string; group: MuscleGroup | null; alternatives: string[] } | null {
  const { candidates, group } = getReplacementCandidates(opts);
  if (candidates.length === 0) return null;

  if (opts.preferredName) {
    const preferred =
      resolveCatalogName(opts.preferredName) ||
      // Por si llega un sinónimo parcial ya canónico del catálogo
      (candidates.find((c) => normalizeName(c) === normalizeName(opts.preferredName!)) ?? null);
    if (preferred && candidates.some((c) => normalizeName(c) === normalizeName(preferred))) {
      return {
        name: preferred,
        group: findExerciseGroup(preferred) || group,
        alternatives: candidates.filter((c) => normalizeName(c) !== normalizeName(preferred)),
      };
    }
  }

  // Rotación estable: offset por longitud del nombre actual
  const offset = (opts.currentName || "").length % candidates.length;
  const chosen = candidates[offset];
  return {
    name: chosen,
    group: findExerciseGroup(chosen) || group,
    alternatives: candidates.filter((c) => normalizeName(c) !== normalizeName(chosen)),
  };
}

/**
 * Convierte el catálogo a un string formateado para inyectar en el prompt del LLM.
 */
export function getCatalogPromptString(): string {
  let promptStr = "CATÁLOGO DE EJERCICIOS PERMITIDOS (ÚNICAS OPCIONES VÁLIDAS):\n";
  for (const [group, exercises] of Object.entries(EXERCISE_CATALOG)) {
    promptStr += `- ${group}: ${exercises.join(", ")}\n`;
  }
  return promptStr;
}
