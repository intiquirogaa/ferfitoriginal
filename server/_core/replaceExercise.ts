/**
 * Reemplazo granular de un ejercicio del plan activo (sin regenerar el plan).
 * Solo elige del catálogo RAG cerrado y conserva series/reps del original.
 */
import * as db from "../db";
import {
  getReplacementCandidates,
  pickReplacementExercise,
  type MuscleGroup,
} from "./catalog";
import { getExerciseMediaUrl } from "./musclewiki";
import { translateExerciseToSpanish } from "./translations";

export type ReplaceExerciseInput = {
  userId: number;
  dayNumber: number; // 1-based (igual que markSeriesComplete)
  exerciseIndex: number;
  preferredName?: string;
};

export type ReplacementOption = {
  name: string;
  nameEs: string;
  group: MuscleGroup | null;
};

export type ReplaceExerciseResult = {
  success: true;
  previousName: string;
  exercise: Record<string, unknown>;
  dayNumber: number;
  exerciseIndex: number;
  alternatives: ReplacementOption[];
  generatedContent: unknown;
};

function exerciseDisplayName(ex: any): string {
  return String(ex?.nameEn || ex?.name || ex?.nameEs || ex?.exerciseName || "").trim();
}

function dayNames(day: any): string[] {
  return (day?.exercises || []).map((e: any) => exerciseDisplayName(e)).filter(Boolean);
}

export async function listReplacementOptions(input: {
  userId: number;
  dayNumber: number;
  exerciseIndex: number;
}): Promise<{ currentName: string; group: MuscleGroup | null; options: ReplacementOption[] }> {
  const plan = await db.getActiveTrainingPlan(input.userId);
  if (!plan) throw new Error("No active training plan");

  const content =
    typeof plan.generatedContent === "string"
      ? JSON.parse(plan.generatedContent || "{}")
      : plan.generatedContent || {};
  const day = content.days?.[input.dayNumber - 1];
  if (!day) throw new Error("Day not found");
  const exercise = day.exercises?.[input.exerciseIndex];
  if (!exercise) throw new Error("Exercise not found");

  const currentName = exerciseDisplayName(exercise);
  const hint =
    exercise.muscleGroup ||
    exercise.targetMuscles?.[0] ||
    exercise.target ||
    day.focus ||
    null;

  const { group, candidates } = getReplacementCandidates({
    currentName,
    dayExerciseNames: dayNames(day),
    muscleGroupHint: typeof hint === "string" ? hint : null,
  });

  return {
    currentName,
    group,
    options: candidates.map((name) => ({
      name,
      nameEs: translateExerciseToSpanish(name),
      group: group,
    })),
  };
}

export async function replaceExerciseInActivePlan(
  input: ReplaceExerciseInput
): Promise<ReplaceExerciseResult> {
  const plan = await db.getActiveTrainingPlan(input.userId);
  if (!plan) throw new Error("No active training plan");

  const content =
    typeof plan.generatedContent === "string"
      ? JSON.parse(plan.generatedContent || "{}")
      : { ...(plan.generatedContent || {}) };

  const day = content.days?.[input.dayNumber - 1];
  if (!day) throw new Error("Day not found");
  const exercise = day.exercises?.[input.exerciseIndex];
  if (!exercise) throw new Error("Exercise not found");

  const previousName = exerciseDisplayName(exercise);
  const hint =
    exercise.muscleGroup ||
    exercise.targetMuscles?.[0] ||
    exercise.target ||
    day.focus ||
    null;

  const picked = pickReplacementExercise({
    currentName: previousName,
    dayExerciseNames: dayNames(day),
    muscleGroupHint: typeof hint === "string" ? hint : null,
    preferredName: input.preferredName,
  });

  if (!picked) {
    throw new Error("No hay alternativas disponibles en el catálogo para este ejercicio");
  }

  const nameEs = translateExerciseToSpanish(picked.name);
  let gifUrl: string | undefined;
  let mediaType: string | undefined;
  try {
    const media = await getExerciseMediaUrl(picked.name);
    if (media?.url) {
      gifUrl = media.url;
      mediaType = media.type;
    }
  } catch {
    // media es best-effort
  }

  const sets = exercise.sets ?? 3;
  const reps = exercise.reps ?? "10";
  const restSeconds = exercise.restSeconds ?? 60;

  const replacement: Record<string, unknown> = {
    ...exercise,
    name: nameEs,
    nameEn: picked.name,
    nameEs,
    muscleGroup: picked.group || exercise.muscleGroup || undefined,
    sets,
    reps,
    restSeconds,
    seriesCompleted: {},
    seriesWeights: {},
    seriesReps: {},
    notes: exercise.notes
      ? `${exercise.notes} · Reemplazado: ${previousName} → ${nameEs}`
      : `Reemplazado: ${previousName} → ${nameEs}`,
    alternatives: picked.alternatives.slice(0, 8),
  };

  if (gifUrl) {
    replacement.gifUrl = gifUrl;
    if (mediaType) replacement.mediaType = mediaType;
  } else {
    delete replacement.gifUrl;
    delete replacement.imageUrl;
  }

  day.exercises[input.exerciseIndex] = replacement;
  await db.updateTrainingPlanContent(plan.id, JSON.stringify(content));

  return {
    success: true,
    previousName,
    exercise: replacement,
    dayNumber: input.dayNumber,
    exerciseIndex: input.exerciseIndex,
    alternatives: picked.alternatives.slice(0, 12).map((name) => ({
      name,
      nameEs: translateExerciseToSpanish(name),
      group: picked.group,
    })),
    generatedContent: content,
  };
}
