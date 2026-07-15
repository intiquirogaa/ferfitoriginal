// server/_core/injuryFilter.ts

/**
 * Mapeo de palabras clave de lesiones a listas de ejercicios prohibidos y sus sustitutos.
 * Cada lesión tiene una lista de *ejercicios prohibidos* (en inglés, tal como aparecen en el catálogo)
 * y una lista de *alternativas* que el filtro usará para reemplazar los ejercicios prohibidos.
 */
export const INJURY_BLACKLIST: Record<string, { exercises: string[]; alternatives: string[] }> = {
  // Dolor o limitación en muñeca
  wrist: {
    exercises: [
      "Push-up",
      "Bench Press",
      "Dips",
      "Plank",
      "Handstand Push-up",
      "Overhead Press",
    ],
    alternatives: ["Forearm Plank", "Dumbbell Chest Press Neutral Grip", "Triceps Extension with Rope", "Band Chest Press"]
  },
  // Dolor o limitación en rodilla
  knee: {
    exercises: [
      "Squat",
      "Lunge",
      "Leg Press",
      "Deadlift",
      "Bulgarian Split Squat",
    ],
    alternatives: ["Glute Bridge", "Leg Extension Machine", "Seated Leg Curl", "Hip Thrust"]
  },
  // Dolor lumbar / espalda baja
  lower_back: {
    exercises: ["Deadlift", "Good Morning", "Barbell Row", "Romanian Deadlift", "Back Extension"],
    alternatives: ["Bird Dog", "Superman", "Cable Row (seated)", "Chest Supported Row"]
  },
  // Lesión de hombro (ejemplo adicional)
  shoulder: {
    exercises: ["Overhead Press", "Arnold Press", "Handstand Push-up", "Push-up"],
    alternatives: ["Lateral Raise with Band", "Front Raise with Band", "Scaption with Dumbbell (neutral grip)"]
  }
};

/**
 * Normaliza la cadena de lesiones ingresada por el usuario.
 * Devuelve un array de claves que existen en INJURY_BLACKLIST.
 */
export function parseInjuries(injuries?: string): string[] {
  if (!injuries) return [];
  const lowered = injuries.toLowerCase();
  const keys: string[] = [];
  if (lowered.includes("muñec") || lowered.includes("wrist")) keys.push("wrist");
  if (lowered.includes("rodill") || lowered.includes("knee")) keys.push("knee");
  if (lowered.includes("lumbar") || lowered.includes("lower back") || lowered.includes("espalda baja"))
    keys.push("lower_back");
  if (lowered.includes("hombro") || lowered.includes("shoulder")) keys.push("shoulder");
  return keys;
}

/**
 * Filtra una rutina (objeto plano) eliminando ejercicios prohibidos según las lesiones.
 * Si un ejercicio está prohibido, se reemplaza por la primera alternativa disponible que
 * no esté también prohibida.
 */
export function filterPlanByInjuries(plan: any, injuries?: string): any {
  const injuryKeys = parseInjuries(injuries);
  if (injuryKeys.length === 0) return plan; // nada que filtrar

  // Construye un Set con todos los ejercicios prohibidos
  const prohibited = new Set<string>();
  const alternativesMap = new Map<string, string[]>();
  injuryKeys.forEach(key => {
    const entry = INJURY_BLACKLIST[key];
    entry.exercises.forEach(e => prohibited.add(e));
    alternativesMap.set(key, entry.alternatives);
  });

  // Recorre cada día y cada ejercicio
  for (const day of plan.days ?? []) {
    for (let i = 0; i < day.exercises.length; i++) {
      const ex = day.exercises[i];
      if (prohibited.has(ex.name)) {
        // Busca una alternativa que no esté prohibida en ningún otro blacklist
        let replacement: string | undefined;
        for (const key of injuryKeys) {
          const alts = alternativesMap.get(key) ?? [];
          for (const alt of alts) {
            if (!prohibited.has(alt)) {
              replacement = alt;
              break;
            }
          }
          if (replacement) break;
        }
        // Si no encontró alternativa, simplemente eliminamos el ejercicio
        if (!replacement) {
          day.exercises.splice(i, 1);
          i--;
          continue;
        }
        // Reemplazamos el nombre y adaptamos grupo muscular genérico
        ex.name = replacement;
        ex.muscleGroup = "Core"; // asignamos un grupo genérico, el catálogo tiene el mapping
        ex.instructions = `Ejercicio sustituido por ${replacement} debido a lesión(s) ${injuries}.`;
      }
    }
  }
  return plan;
}
