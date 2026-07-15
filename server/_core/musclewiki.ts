import { ENV } from "./env";
import { translateExerciseToEnglish } from "./translations";
import { getFreeExerciseMedia } from "./freeExerciseDb";
import { getLocalExerciseImage } from "./exerciseImages";

export interface ExerciseMedia {
  type: "image" | "video";
  url: string;
  exerciseName?: string;
}

/**
 * Absolute http(s) URLs only. Relative paths like `/exercises/foo.png` break
 * Flutter (Image.network) and 404 on web until real assets are shipped.
 */
export function isUsableMediaUrl(url: string | null | undefined): boolean {
  if (!url || typeof url !== "string") return false;
  const trimmed = url.trim();
  if (!trimmed) return false;
  // Local /exercises/* maps exist in code but files were never added (only README).
  if (trimmed.startsWith("/exercises/")) return false;
  return /^https?:\/\//i.test(trimmed);
}

/**
 * Get exercise media, trying ExerciseDB (RapidAPI) first and falling back to
 * a free, unlimited public dataset (freeExerciseDb.ts) if RapidAPI fails —
 * e.g. quota agotada, timeout, o sin match.
 *
 * NOTE: local `/exercises/*.png` map is intentionally NOT preferred — the
 * public folder has no real image files yet, so preferring it stored broken
 * gifUrl values in the DB and blocked remote GIFs.
 */
export async function getExerciseMediaUrl(
  exerciseName: string
): Promise<ExerciseMedia | null> {
  if (!exerciseName) return null;

  const englishName = translateExerciseToEnglish(exerciseName);

  // 1. Try RapidAPI ExerciseDB (real GIFs when API key + quota available)
  const rapidApiMedia = await getRapidApiExerciseMedia(englishName);
  if (rapidApiMedia && isUsableMediaUrl(rapidApiMedia.url)) return rapidApiMedia;

  // 2. Fallback to free exercise database (CDN images)
  const freeMedia = await getFreeExerciseMedia(englishName);
  if (freeMedia && isUsableMediaUrl(freeMedia.url)) return freeMedia;

  // 3. Local map only if ever populated with absolute URLs
  const localImage = getLocalExerciseImage(exerciseName) || getLocalExerciseImage(englishName);
  if (localImage && isUsableMediaUrl(localImage)) {
    return {
      type: "image",
      url: localImage,
      exerciseName: englishName || exerciseName,
    };
  }

  return null;
}

async function getRapidApiExerciseMedia(englishName: string): Promise<ExerciseMedia | null> {
  try {
    const normalizedName = englishName.toLowerCase().trim();

    // ExerciseDB RapidAPI endpoint: search by name
    const response = await fetch(
      `https://exercisedb.p.rapidapi.com/exercises/name/${encodeURIComponent(normalizedName)}?limit=1`,
      {
        method: "GET",
        headers: {
          "x-rapidapi-key": ENV.muscleWikiApiKey || "",
          "x-rapidapi-host": "exercisedb.p.rapidapi.com",
          "Content-Type": "application/json",
        },
      }
    );

    if (!response.ok) {
      console.log(
        `[ExerciseDB] API error: ${response.status} ${response.statusText}`
      );
      return null;
    }

    const data = await response.json();

    if (Array.isArray(data) && data.length > 0) {
      const exercise = data[0];
      // Preferimos el gifUrl directo de la búsqueda: evita un segundo
      // request (y segundo consumo de cuota) contra /api/exercise-image
      // por cada ejercicio mostrado.
      if (exercise.gifUrl) {
        return {
          type: "image",
          url: exercise.gifUrl,
          exerciseName: exercise.name,
        };
      }
      if (exercise.id) {
        return {
          type: "image",
          url: `/api/exercise-image?exerciseId=${encodeURIComponent(exercise.id)}`,
          exerciseName: exercise.name,
        };
      }
    }

    return null;
  } catch (error) {
    console.error("[ExerciseDB] Get media error:", error);
    return null;
  }
}

/**
 * Search for exercises in ExerciseDB
 * Returns exercises with their GIF images
 */
export async function searchExerciseWithMedia(
  name: string,
  limit: number = 5
): Promise<
  Array<{
    name: string;
    gifUrl: string;
    target?: string;
    equipment?: string;
  }>
> {
  try {
    if (!name) {
      return [];
    }

    const normalizedName = name.toLowerCase().trim();

    const response = await fetch(
      `https://exercise-db-fitness-workout-gym.p.rapidapi.com/search?q=${encodeURIComponent(normalizedName)}&limit=${limit}`,
      {
        method: "GET",
        headers: {
          "x-rapidapi-key": ENV.muscleWikiApiKey || "",
          "x-rapidapi-host": "exercise-db-fitness-workout-gym.p.rapidapi.com",
          "Content-Type": "application/json",
        },
      }
    );

    if (!response.ok) {
      console.log(
        `[ExerciseDB] Search error: ${response.status} ${response.statusText}`
      );
      return [];
    }

    const data = await response.json();

    if (Array.isArray(data)) {
      return data
        .filter((ex) => ex.gifUrl)
        .map((ex) => ({
          name: ex.name,
          gifUrl: ex.gifUrl,
          target: ex.target,
          equipment: ex.equipment,
        }));
    }

    return [];
  } catch (error) {
    console.error("[ExerciseDB] Search error:", error);
    return [];
  }
}
