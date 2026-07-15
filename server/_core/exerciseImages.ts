/**
 * Mapeo de ejercicios a imágenes locales.
 * Las imágenes deben estar en client/public/exercises/
 * y se sirven como archivos estáticos en /exercises/{filename}
 */

const EXERCISE_IMAGE_MAP: Record<string, string> = {
  // CHEST
  "bench press": "bench-press.png",
  "incline bench press": "incline-bench-press.png",
  "decline bench press": "decline-bench-press.png",
  "dumbbell bench press": "dumbbell-bench-press.png",
  "incline dumbbell press": "incline-dumbbell-press.png",
  "decline dumbbell press": "decline-dumbbell-press.png",
  "dumbbell flyes": "dumbbell-flyes.png",
  "cable crossover": "cable-crossover.png",
  "pec deck fly": "pec-deck-fly.png",
  "push-up": "push-up.png",
  "decline push-up": "decline-push-up.png",
  "incline push-up": "incline-push-up.png",
  "diamond push-up": "diamond-push-up.png",
  "machine chest press": "machine-chest-press.png",

  // BACK
  "pull-up": "pull-up.png",
  "chin-up": "chin-up.png",
  "lat pulldown": "lat-pulldown.png",
  "straight arm pulldown": "straight-arm-pulldown.png",
  "barbell row": "barbell-row.png",
  "dumbbell row": "dumbbell-row.png",
  "pendlay row": "pendlay-row.png",
  "t-bar row": "t-bar-row.png",
  "seated cable row": "seated-cable-row.png",
  "chest supported row": "chest-supported-row.png",
  "deadlift": "deadlift.png",
  "rack pull": "rack-pull.png",
  "good morning": "good-morning.png",
  "superman": "superman.png",
  "inverted row": "inverted-row.png",

  // LEGS
  "barbell squat": "barbell-squat.png",
  "front squat": "front-squat.png",
  "goblet squat": "goblet-squat.png",
  "bodyweight squat": "bodyweight-squat.png",
  "air squat": "bodyweight-squat.png",
  "air squats": "bodyweight-squat.png",
  "leg press": "leg-press.png",
  "hack squat": "hack-squat.png",
  "bulgarian split squat": "bulgarian-split-squat.png",
  "lunges": "lunges.png",
  "walking lunges": "walking-lunges.png",
  "romanian deadlift": "romanian-deadlift.png",
  "stiff-legged deadlift": "stiff-legged-deadlift.png",
  "leg extension": "leg-extension.png",
  "leg curl": "leg-curl.png",
  "seated leg curl": "seated-leg-curl.png",
  "lying leg curl": "lying-leg-curl.png",
  "hip thrust": "hip-thrust.png",
  "glute bridge": "glute-bridge.png",
  "calf raise": "calf-raise.png",
  "seated calf raise": "seated-calf-raise.png",
  "standing calf raise": "standing-calf-raise.png",

  // SHOULDERS
  "overhead press": "overhead-press.png",
  "dumbbell shoulder press": "dumbbell-shoulder-press.png",
  "arnold press": "arnold-press.png",
  "lateral raise": "lateral-raise.png",
  "cable lateral raise": "cable-lateral-raise.png",
  "machine lateral raise": "machine-lateral-raise.png",
  "front raise": "front-raise.png",
  "dumbbell front raise": "dumbbell-front-raise.png",
  "reverse pec deck": "reverse-pec-deck.png",
  "face pull": "face-pull.png",
  "dumbbell rear delt row": "dumbbell-rear-delt-row.png",
  "upright row": "upright-row.png",
  "barbell shrug": "barbell-shrug.png",
  "dumbbell shrug": "dumbbell-shrug.png",

  // ARMS
  "barbell curl": "barbell-curl.png",
  "dumbbell curl": "dumbbell-curl.png",
  "hammer curl": "hammer-curl.png",
  "preacher curl": "preacher-curl.png",
  "cable curl": "cable-curl.png",
  "concentration curl": "concentration-curl.png",
  "triceps pushdown": "triceps-pushdown.png",
  "overhead triceps extension": "overhead-triceps-extension.png",
  "skullcrusher": "skullcrusher.png",
  "close grip bench press": "close-grip-bench-press.png",
  "triceps dip": "triceps-dip.png",
  "bench dip": "bench-dip.png",
  "triceps kickback": "triceps-kickback.png",

  // CORE
  "crunch": "crunch.png",
  "reverse crunch": "reverse-crunch.png",
  "bicycle crunch": "bicycle-crunch.png",
  "russian twist": "russian-twist.png",
  "plank": "plank.png",
  "side plank": "side-plank.png",
  "ab wheel rollout": "ab-wheel-rollout.png",
  "hanging leg raise": "hanging-leg-raise.png",
  "cable crunch": "cable-crunch.png",
  "decline crunch": "decline-crunch.png",
  "mountain climber": "mountain-climber.png",
  "dead bug": "dead-bug.png",
  "bird dog": "bird-dog.png",

  // CARDIO_MOBILITY
  "burpee": "burpee.png",
  "jumping jack": "jumping-jack.png",
  "high knees": "high-knees.png",
  "jump rope": "jump-rope.png",
  "box jump": "box-jump.png",
  "kettlebell swing": "kettlebell-swing.png",
  "shoulder dislocates": "shoulder-dislocates.png",
  "cat-cow": "cat-cow.png",
  "hip rotations": "hip-rotations.png",
  "torso twist": "torso-twist.png",
};

/**
 * Obtiene la URL de la imagen local para un ejercicio.
 * @param exerciseName - Nombre del ejercicio (en inglés o español)
 * @returns URL relativa de la imagen o null si no existe
 */
export function getLocalExerciseImage(exerciseName: string): string | null {
  if (!exerciseName) return null;
  const normalized = exerciseName.toLowerCase().trim().replace(/\s+/g, " ");

  // Direct match
  if (EXERCISE_IMAGE_MAP[normalized]) {
    return `/exercises/${EXERCISE_IMAGE_MAP[normalized]}`;
  }

  // Try removing common suffixes/prefixes
  const cleaned = normalized
    .replace(/^(barbell|dumbbell|cable|machine|bodyweight)\s+/i, "")
    .replace(/\s+(bodyweight|with barbell|with dumbbell)$/i, "");

  if (cleaned !== normalized && EXERCISE_IMAGE_MAP[cleaned]) {
    return `/exercises/${EXERCISE_IMAGE_MAP[cleaned]}`;
  }

  // Partial match - find closest
  for (const [key, value] of Object.entries(EXERCISE_IMAGE_MAP)) {
    if (normalized.includes(key) || key.includes(normalized)) {
      return `/exercises/${value}`;
    }
  }

  return null;
}

/**
 * Placeholder por grupo muscular cuando no hay imagen específica.
 * Usa un SVG inline o una imagen genérica.
 */
export const MUSCLE_GROUP_PLACEHOLDERS: Record<string, string> = {
  "chest": "/exercises/placeholder-chest.png",
  "back": "/exercises/placeholder-back.png",
  "legs": "/exercises/placeholder-legs.png",
  "shoulders": "/exercises/placeholder-shoulders.png",
  "arms": "/exercises/placeholder-arms.png",
  "core": "/exercises/placeholder-core.png",
  "cardio": "/exercises/placeholder-cardio.png",
  "default": "/exercises/placeholder-default.png",
};

export function getPlaceholderByMuscleGroup(muscleGroup: string | undefined): string {
  if (!muscleGroup) return MUSCLE_GROUP_PLACEHOLDERS.default;
  const mg = muscleGroup.toLowerCase();
  if (mg.includes("chest") || mg.includes("pecho")) return MUSCLE_GROUP_PLACEHOLDERS.chest;
  if (mg.includes("back") || mg.includes("espalda")) return MUSCLE_GROUP_PLACEHOLDERS.back;
  if (mg.includes("leg") || mg.includes("pierna") || mg.includes("glute") || mg.includes("calf")) return MUSCLE_GROUP_PLACEHOLDERS.legs;
  if (mg.includes("shoulder") || mg.includes("hombro")) return MUSCLE_GROUP_PLACEHOLDERS.shoulders;
  if (mg.includes("arm") || mg.includes("bicep") || mg.includes("tricep") || mg.includes("brazo")) return MUSCLE_GROUP_PLACEHOLDERS.arms;
  if (mg.includes("core") || mg.includes("abdom") || mg.includes("abs")) return MUSCLE_GROUP_PLACEHOLDERS.core;
  if (mg.includes("cardio") || mg.includes("mobility")) return MUSCLE_GROUP_PLACEHOLDERS.cardio;
  return MUSCLE_GROUP_PLACEHOLDERS.default;
}
