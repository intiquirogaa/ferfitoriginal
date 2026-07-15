// QA Exhaustive Test with GIF verification
import { generateBasicPlan } from "./server/routers.js";
import { getExerciseMediaUrl } from "./server/_core/musclewiki.js";

async function runTests() {
  console.log("=== INICIANDO QA EXHAUSTIVA 5 PRUEBAS + VERIFICACIÓN DE GIFS ===\n");
  const macrosMock = { protein: 150, carbs: 200, fats: 60 };

  // Helper to check GIFs for a plan
  async function verifyGifs(plan, label) {
    console.log(`>> Verificando GIFs para ${label}`);
    let missing = 0;
    for (const day of plan.days) {
      for (const ex of day.exercises) {
        const media = await getExerciseMediaUrl(ex.name);
        if (media && media.url) {
          ex.gifUrl = media.url;
        } else {
          missing++;
          console.warn(`⚠️ GIF no encontrado para '${ex.name}'`);
        }
      }
    }
    console.log(`✅ GIFs verificados: ${plan.days.reduce((c,d)=>c+d.exercises.length,0)} ejercicios, faltantes: ${missing}\n`);
  }

  // 1. Pérdida de grasa, principiante, edad avanzada, sobrepeso, sin equipamiento, sin lesiones.
  const plan1 = await generateBasicPlan({
    objective: "fat_loss",
    experienceLevel: "beginner",
    age: 65,
    weight: 95,
    height: 170,
    daysPerWeek: 3,
    equipment: "bodyweight",
    injuries: "",
    preferences: ""
  }, 2500, macrosMock);
  console.log("✅ Test 1 generado");
  await verifyGifs(plan1, "Test 1");

  // 2. Ganar músculo, intermedio, lesión muñeca.
  const plan2 = await generateBasicPlan({
    objective: "hypertrophy",
    experienceLevel: "intermediate",
    age: 30,
    weight: 75,
    height: 180,
    daysPerWeek: 4,
    equipment: "dumbbells",
    injuries: "dolor de muñeca",
    preferences: ""
  }, 2800, macrosMock);
  console.log("✅ Test 2 generado");
  await verifyGifs(plan2, "Test 2");

  // 3. Fuerza, avanzado, lesión rodilla.
  const plan3 = await generateBasicPlan({
    objective: "strength",
    experienceLevel: "advanced",
    age: 28,
    weight: 80,
    height: 175,
    daysPerWeek: 5,
    equipment: "full_gym",
    injuries: "dolor de rodilla",
    preferences: ""
  }, 3000, macrosMock);
  console.log("✅ Test 3 generado");
  await verifyGifs(plan3, "Test 3");

  // 4. Recomposición, lesión lumbar.
  const plan4 = await generateBasicPlan({
    objective: "recomposition",
    experienceLevel: "beginner",
    age: 45,
    weight: 70,
    height: 165,
    daysPerWeek: 3,
    equipment: "limited",
    injuries: "dolor lumbar",
    preferences: ""
  }, 2400, macrosMock);
  console.log("✅ Test 4 generado");
  await verifyGifs(plan4, "Test 4");

  // 5. Hipertrofia, avanzado, sin lesiones.
  const plan5 = await generateBasicPlan({
    objective: "hypertrophy",
    experienceLevel: "advanced",
    age: 22,
    weight: 68,
    height: 178,
    daysPerWeek: 6,
    equipment: "full_gym",
    injuries: "",
    preferences: ""
  }, 3000, macrosMock);
  console.log("✅ Test 5 generado");
  await verifyGifs(plan5, "Test 5");

  console.log("=== TODOS LOS TESTS COMPLETADOS ===");
  process.exit(0);
}

runTests();
