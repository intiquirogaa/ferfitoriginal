const TRANSLATIONS: Record<string, string> = {
  // Chest
  "bench press": "Press de banca",
  "barbell bench press": "Press de banca con barra",
  "incline bench press": "Press de banca inclinado",
  "incline barbell bench press": "Press inclinado con barra",
  "decline bench press": "Press de banca declinado",
  "dumbbell press": "Press con mancuernas",
  "dumbbell bench press": "Press de banca con mancuernas",
  "incline dumbbell press": "Press inclinado con mancuernas",
  "decline dumbbell press": "Press declinado con mancuernas",
  "chest press": "Press de pecho",
  "dumbbell chest press": "Press de pecho con mancuernas",
  "chest fly": "Aperturas de pecho",
  "dumbbell fly": "Aperturas con mancuernas",
  "dumbbell flyes": "Aperturas con mancuernas",
  "incline dumbbell fly": "Aperturas inclinadas con mancuernas",
  "cable flyes": "Cruces de polea",
  "cable crossover": "Cruce de poleas",
  "push-up": "Flexiones de brazos",
  "push-up (version peso corporal)": "Flexiones de brazos",
  "push-up (enfoque en contraccion de pecho)": "Flexiones (enfoque en pecho)",
  "push-ups": "Flexiones de brazos",
  "pushup": "Flexiones de brazos",
  "pushups": "Flexiones de brazos",
  "decline push-up": "Flexión declinada",
  "chest dips": "Fondos en paralelas (pecho)",
  "chest dip": "Fondos en paralelas (pecho)",

  // Back
  "pull-up": "Dominadas",
  "pull-ups": "Dominadas",
  "pullup": "Dominadas",
  "pullups": "Dominadas",
  "chin-up": "Dominadas supinas",
  "chin-ups": "Dominadas supinas",
  "chinup": "Dominadas supinas",
  "lat pulldown": "Jalón al pecho",
  "cable lat pulldown": "Jalón al pecho en polea",
  "close grip lat pulldown": "Jalón al pecho agarre cerrado",
  "dumbbell row": "Remo con mancuerna",
  "dumbbell rows": "Remo con mancuernas",
  "one arm dumbbell row": "Remo a una mano con mancuerna",
  "barbell row": "Remo con barra",
  "bent over row": "Remo inclinado con barra",
  "bent over rows": "Remo inclinado con barra",
  "cable row": "Remo en polea",
  "seated cable row": "Remo sentado en polea",
  "t-bar row": "Remo en barra T",
  "t bar row": "Remo en barra T",
  "inverted row": "Remo invertido",
  "hyperextension": "Hiperextensiones",
  "hyperextensions": "Hiperextensiones",

  // Shoulders
  "overhead press": "Press militar",
  "barbell overhead press": "Press militar con barra",
  "military press": "Press militar",
  "shoulder press": "Press de hombro",
  "dumbbell shoulder press": "Press de hombro con mancuernas",
  "dumbbell overhead press": "Press militar con mancuernas",
  "arnold press": "Press Arnold",
  "lateral raise": "Elevaciones laterales",
  "lateral raises": "Elevaciones laterales",
  "dumbbell lateral raise": "Elevaciones laterales con mancuernas",
  "dumbbell lateral raises": "Elevaciones laterales con mancuernas",
  "front raise": "Elevaciones frontales",
  "dumbbell front raise": "Elevaciones frontales con mancuernas",
  "rear delt fly": "Pájaros (hombro posterior)",
  "rear delt flyes": "Pájaros (hombro posterior)",
  "dumbbell rear delt fly": "Pájaros con mancuernas",
  "face pull": "Face pull en polea",
  "face pulls": "Face pull en polea",
  "shrugs": "Encogimientos de hombros",
  "barbell shrug": "Encogimientos con barra",
  "dumbbell shrug": "Encogimientos con mancuernas",
  "pike push-up": "Flexión en pica",
  "pike pushups": "Flexiones en pica",
  "arm circles": "Círculos de brazos",

  // Legs (Quads, Hamstrings, Glutes, Calves)
  "squat": "Sentadilla",
  "squats": "Sentadillas",
  "barbell squat": "Sentadilla con barra",
  "barbell squats": "Sentadillas con barra",
  "goblet squat": "Sentadilla Goblet",
  "dumbbell goblet squat": "Sentadilla Goblet con mancuerna",
  "bodyweight squat": "Sentadilla libre (peso corporal)",
  "bodyweight squats": "Sentadillas libres",
  "air squat": "Sentadilla al aire",
  "air squats": "Sentadillas al aire",
  "front squat": "Sentadilla frontal",
  "hack squat": "Sentadilla Hack",
  "bulgarian split squat": "Sentadilla búlgara",
  "bulgarian split squats": "Sentadillas búlgaras",
  "leg press": "Prensa de piernas",
  "leg extension": "Extensión de piernas",
  "leg extensions": "Extensiones de piernas",
  "leg curl": "Curl de piernas",
  "leg curls": "Curl de piernas",
  "lying leg curl": "Curl de piernas acostado",
  "lying leg curls": "Curl de piernas acostado",
  "seated leg curl": "Curl de piernas sentado",
  "deadlift": "Peso muerto",
  "deadlifts": "Peso muerto",
  "barbell deadlift": "Peso muerto con barra",
  "dumbbell deadlift": "Peso muerto con mancuernas",
  "romanian deadlift": "Peso muerto rumano",
  "barbell romanian deadlift": "Peso muerto rumano con barra",
  "dumbbell romanian deadlift": "Peso muerto rumano con mancuernas",
  "stiff-legged deadlift": "Peso muerto piernas semirrígidas",
  "lunge": "Estocada",
  "lunges": "Estocadas",
  "dumbbell lunge": "Estocadas con mancuernas",
  "dumbbell lunges": "Estocadas con mancuernas",
  "walking lunges": "Estocadas caminando",
  "step-up": "Subidas al banco",
  "step ups": "Subidas al banco",
  "hip thrust": "Hip thrust",
  "barbell hip thrust": "Hip thrust con barra",
  "glute bridge": "Puente de glúteos",
  "single-leg glute bridge": "Puente de glúteos a una pierna",
  "single-leg romanian deadlift": "Peso muerto rumano a una pierna",
  "calf raise": "Elevación de talones",
  "calf raises": "Elevaciones de talones",
  "standing calf raise": "Elevación de talones de pie",
  "standing calf raises": "Elevaciones de talones de pie",
  "seated calf raise": "Elevación de talones sentado",
  "seated calf raises": "Elevaciones de talones sentado",

  // Arms (Biceps & Triceps)
  "bicep curl": "Curl de bíceps",
  "bicep curls": "Curl de bíceps",
  "barbell curl": "Curl con barra",
  "barbell curls": "Curl con barra",
  "dumbbell curl": "Curl con mancuernas",
  "dumbbell curls": "Curl con mancuernas",
  "hammer curl": "Curl martillo",
  "hammer curls": "Curl martillo",
  "incline dumbbell curl": "Curl inclinado con mancuernas",
  "preacher curl": "Curl predicador",
  "cable curl": "Curl en polea",
  "tricep extension": "Extensión de tríceps",
  "tricep extensions": "Extensiones de tríceps",
  "tricep pushdown": "Extensión de tríceps en polea",
  "triceps pushdown": "Extensión de tríceps en polea",
  "rope pushdown": "Extensión en polea con cuerda",
  "overhead tricep extension": "Extensión de tríceps sobre la cabeza",
  "dumbbell overhead tricep extension": "Extensión de tríceps copa",
  "skull crusher": "Press francés",
  "skull crushers": "Press francés",
  "tricep dips": "Fondos de tríceps",
  "tricep dip": "Fondos de tríceps",
  "bench dips": "Fondos en banco",
  "bench dip": "Fondos en banco",
  "dips": "Fondos",

  // Core & Abs
  "plank": "Plancha",
  "planks": "Planchas",
  "side plank": "Plancha lateral",
  "crunch": "Abdominales crunches",
  "crunches": "Abdominales crunches",
  "abdominal crunch": "Abdominales crunches",
  "lying leg raise": "Elevación de piernas acostado",
  "lying leg raises": "Elevaciones de piernas acostado",
  "leg raise": "Elevación de piernas",
  "leg raises": "Elevaciones de piernas",
  "hanging leg raise": "Elevación de piernas colgado",
  "russian twist": "Giros rusos",
  "russian twists": "Giros rusos",
  "dead bug": "Bicho muerto (Dead Bug)",
  "dead bugs": "Bicho muerto (Dead Bug)",
  "bird dog": "Bird Dog",
  "bird dogs": "Bird Dog",
  "bicycle crunches": "Abdominales bicicleta",
  "mountain climbers": "Escaladores",
  "toes to bar": "Pies a la barra",
};

export function translateExerciseToSpanish(name: string): string {
  if (!name) return name;
  const cleanName = name.toLowerCase().trim().replace(/\s+/g, " ");
  
  // Direct match
  if (TRANSLATIONS[cleanName]) {
    return TRANSLATIONS[cleanName];
  }

  // Substring match or partial mapping
  for (const [english, spanish] of Object.entries(TRANSLATIONS)) {
    if (cleanName === english) {
      return spanish;
    }
  }

  // If no match, try to translate common words to make it sound Spanish
  let translated = name;
  // Capitalize first letter
  return translated.charAt(0).toUpperCase() + translated.slice(1);
}

const REVERSE_TRANSLATIONS: Record<string, string> = {};
for (const [english, spanish] of Object.entries(TRANSLATIONS)) {
  REVERSE_TRANSLATIONS[spanish.toLowerCase()] = english;
}

export function translateExerciseToEnglish(name: string): string {
  if (!name) return name;
  const cleanName = name.toLowerCase().trim().replace(/\s+/g, " ");
  if (REVERSE_TRANSLATIONS[cleanName]) {
    return REVERSE_TRANSLATIONS[cleanName];
  }
  return name;
}

