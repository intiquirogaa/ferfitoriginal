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
