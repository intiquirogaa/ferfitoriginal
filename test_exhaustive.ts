// QA Exhaustive Tests for Ferfit Plan Generator
import { generateBasicPlan } from "./server/routers.js";

async function runTests() {
  console.log("=== INICIANDO QA EXHAUSTIVA 5 PRUEBAS ===\n");
  const macrosMock = { protein: 150, carbs: 200, fats: 60 };

  // 1. Pérdida de grasa, principiante, edad avanzada, sobrepeso, sin equipamiento, 3 días
  console.log(">> Test 1: pérdida de grasa, principiante, 65 años, 95kg, 170cm, 3 días, sin equipamiento, sin lesiones");
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
  console.log("✅ Resultado Test 1:");
  console.log(`- Días: ${plan1.days.length}`);
  console.log(`- Día 1 ejercicios: ${plan1.days[0].exercises.map((e:any)=>e.name).join(", ")}`);
  console.log("---\n");

  // 2. Ganar músculo, intermedio, 30 años, 75kg, 180cm, 4 días, pesas, lesión muñeca
  console.log(">> Test 2: ganar músculo, intermedio, lesión muñeca");
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
  console.log("✅ Resultado Test 2:");
  console.log(`- Día 1 ejercicios: ${plan2.days[0].exercises.map((e:any)=>e.name).join(", ")}`);
  console.log("---\n");

  // 3. Ganar fuerza, avanzado, 28 años, 80kg, 175cm, 5 días, equip completo, lesión rodilla
  console.log(">> Test 3: fuerza avanzada, lesión rodilla");
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
  console.log("✅ Resultado Test 3:");
  console.log(`- Día 1 ejercicios: ${plan3.days[0].exercises.map((e:any)=>e.name).join(", ")}`);
  console.log("---\n");

  // 4. Recomposición, principiante, 45 años, 70kg, 165cm, 3 días, bandas, lesión espalda baja
  console.log(">> Test 4: recomposición, lesión espalda baja");
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
  console.log("✅ Resultado Test 4:");
  console.log(`- Día 1 ejercicios: ${plan4.days[0].exercises.map((e:any)=>e.name).join(", ")}`);
  console.log("---\n");

  // 5. Ganar músculo, avanzado, 22 años, 68kg, 178cm, 6 días, pesas, sin lesiones
  console.log(">> Test 5: músculo avanzado sin lesiones");
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
  console.log("✅ Resultado Test 5:");
  console.log(`- Días: ${plan5.days.length}`);
  console.log(`- Día 1 ejercicios: ${plan5.days[0].exercises.map((e:any)=>e.name).join(", ")}`);
  console.log("---\n");

  process.exit(0);
}

runTests();
