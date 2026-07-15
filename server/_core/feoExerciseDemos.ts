/**
 * 15 ejercicios del catálogo con demo de Feo en Flutter.
 * Catálogo: server/_core/catalog.ts
 */
export const FEO_MVP_EXERCISES = [
  // Originales (5)
  {
    id: "push_up",
    catalogName: "Push-up",
    nameEs: "Flexiones de brazos",
    group: "CHEST",
  },
  {
    id: "bodyweight_squat",
    catalogName: "Bodyweight Squat",
    nameEs: "Sentadilla (peso corporal)",
    group: "LEGS",
  },
  {
    id: "plank",
    catalogName: "Plank",
    nameEs: "Plancha",
    group: "CORE",
  },
  {
    id: "pull_up",
    catalogName: "Pull-up",
    nameEs: "Dominadas",
    group: "BACK",
  },
  {
    id: "dumbbell_curl",
    catalogName: "Dumbbell Curl",
    nameEs: "Curl con mancuernas",
    group: "ARMS",
  },
  // +10
  {
    id: "lunges",
    catalogName: "Lunges",
    nameEs: "Zancadas",
    group: "LEGS",
  },
  {
    id: "burpee",
    catalogName: "Burpee",
    nameEs: "Burpees",
    group: "CARDIO_MOBILITY",
  },
  {
    id: "mountain_climber",
    catalogName: "Mountain Climber",
    nameEs: "Escaladores",
    group: "CORE",
  },
  {
    id: "bench_press",
    catalogName: "Bench Press",
    nameEs: "Press de banca",
    group: "CHEST",
  },
  {
    id: "deadlift",
    catalogName: "Deadlift",
    nameEs: "Peso muerto",
    group: "BACK",
  },
  {
    id: "overhead_press",
    catalogName: "Overhead Press",
    nameEs: "Press militar",
    group: "SHOULDERS",
  },
  {
    id: "lateral_raise",
    catalogName: "Lateral Raise",
    nameEs: "Elevaciones laterales",
    group: "SHOULDERS",
  },
  {
    id: "triceps_dip",
    catalogName: "Triceps Dip",
    nameEs: "Fondos de tríceps",
    group: "ARMS",
  },
  {
    id: "crunch",
    catalogName: "Crunch",
    nameEs: "Crunch / abdominales",
    group: "CORE",
  },
  {
    id: "jumping_jack",
    catalogName: "Jumping Jack",
    nameEs: "Jumping jacks",
    group: "CARDIO_MOBILITY",
  },
] as const;

export type FeoMvpExerciseId = (typeof FEO_MVP_EXERCISES)[number]["id"];
