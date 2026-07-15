// Fallback gratuito de imágenes de ejercicios, sin API key ni límite de cuota.
// Fuente: free-exercise-db (dataset público en GitHub, servido vía CDN de jsDelivr).
// https://github.com/yuhonas/free-exercise-db
import type { ExerciseMedia } from "./musclewiki";

const DATASET_URL = "https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/dist/exercises.json";
const IMAGE_BASE_URL = "https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/";

type FreeExercise = {
  name: string;
  images: string[];
};

let cachedExercises: FreeExercise[] | null = null;
let loadingPromise: Promise<FreeExercise[]> | null = null;

async function loadDataset(): Promise<FreeExercise[]> {
  if (cachedExercises) return cachedExercises;
  if (!loadingPromise) {
    loadingPromise = fetch(DATASET_URL)
      .then(res => {
        if (!res.ok) throw new Error(`free-exercise-db fetch failed: ${res.status}`);
        return res.json();
      })
      .then((data: FreeExercise[]) => {
        cachedExercises = data;
        return data;
      })
      .catch(error => {
        loadingPromise = null; // permite reintentar en la próxima llamada
        throw error;
      });
  }
  return loadingPromise;
}

function normalize(name: string): string {
  return name
    .toLowerCase()
    .replace(/[-_/]/g, " ")
    .replace(/[^a-z0-9 ]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

// Requiere que TODAS las palabras del nombre buscado aparezcan como palabra
// completa en el candidato (evita falsos positivos de substring suelto), y
// entre los candidatos válidos elige el nombre más corto/genérico
// (ej. preferir "Barbell Squat" antes que "Barbell Squat - Full Depth").
function findMatch(exercises: FreeExercise[], query: string): FreeExercise | null {
  const queryWords = normalize(query).split(" ").filter(Boolean);
  if (queryWords.length === 0) return null;

  let best: FreeExercise | null = null;
  for (const ex of exercises) {
    const nameWords = new Set(normalize(ex.name).split(" "));
    if (queryWords.every(w => nameWords.has(w))) {
      if (!best || ex.name.length < best.name.length) best = ex;
    }
  }
  return best;
}

export async function getFreeExerciseMedia(englishName: string): Promise<ExerciseMedia | null> {
  if (!englishName) return null;
  try {
    const exercises = await loadDataset();
    const match = findMatch(exercises, englishName);
    if (!match || !match.images?.[0]) return null;
    return {
      type: "image",
      url: `${IMAGE_BASE_URL}${match.images[0]}`,
      exerciseName: match.name,
    };
  } catch (error) {
    console.error("[FreeExerciseDB] lookup failed:", error);
    return null;
  }
}
