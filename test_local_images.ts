import { getLocalExerciseImage, getPlaceholderByMuscleGroup } from "./server/_core/exerciseImages.js";

console.log("=== TEST DE IMÁGENES LOCALES ===\n");

const tests = [
  { name: "Bench Press", expected: "/exercises/bench-press.png" },
  { name: "Push-up", expected: "/exercises/push-up.png" },
  { name: "Barbell Squat", expected: "/exercises/barbell-squat.png" },
  { name: "Plank", expected: "/exercises/plank.png" },
  { name: "Diamond Push-up", expected: "/exercises/diamond-push-up.png" },
  { name: "Walking Lunges", expected: "/exercises/walking-lunges.png" },
  { name: "Air Squat", expected: "/exercises/bodyweight-squat.png" }, // partial match
  { name: "Abdominal Crunch", expected: "/exercises/crunch.png" }, // partial match
  { name: "Ejercicio Inexistente", expected: null },
];

let passed = 0;
let failed = 0;

for (const test of tests) {
  const result = getLocalExerciseImage(test.name);
  const ok = result === test.expected;
  if (ok) {
    passed++;
    console.log(`✅ ${test.name} → ${result}`);
  } else {
    failed++;
    console.log(`❌ ${test.name} → got "${result}", expected "${test.expected}"`);
  }
}

console.log(`\n--- Placeholders ---`);
console.log(`Core: ${getPlaceholderByMuscleGroup("Core")}`);
console.log(`Pecho: ${getPlaceholderByMuscleGroup("Pecho")}`);
console.log(`Piernas: ${getPlaceholderByMuscleGroup("Piernas")}`);
console.log(`Undefined: ${getPlaceholderByMuscleGroup(undefined)}`);

console.log(`\n=== RESULTADO: ${passed} passed, ${failed} failed ===`);
process.exit(failed > 0 ? 1 : 0);
