import { generateBasicPlan } from "./server/routers.js";

async function runTest() {
  console.log("=== INICIANDO QA TEST DE FALLBACK AVANZADO ===\n");
  
  const macrosMock = { protein: 150, carbs: 200, fats: 60 };

  try {
    console.log(">> Test 1: Principiante, 3 días, preferencia 'solo core'");
    const plan1 = await generateBasicPlan({
      objective: "fat_loss",
      experienceLevel: "beginner",
      daysPerWeek: 3,
      equipment: "bodyweight",
      preferences: "solo core"
    }, 2000, macrosMock);
    
    console.log("✅ RESULTADO TEST 1:");
    console.log(`- Días generados: ${plan1.days.length}`);
    console.log(`- Día 1 Focus: ${plan1.days[0].focus}`);
    console.log(`- Ejercicios Día 1: ${plan1.days[0].exercises.length}`);
    console.log(`- Primer ejercicio: ${plan1.days[0].exercises[0].name} (${plan1.days[0].exercises[0].sets} series)`);
    console.log(`- Calorías recomendadas: ${plan1.nutrition.dailyCalories}`);
    
    console.log("\n-----------------------------------\n");

    console.log(">> Test 2: Avanzado, 4 días, hipertrofia");
    const plan2 = await generateBasicPlan({
      objective: "hypertrophy",
      experienceLevel: "advanced",
      daysPerWeek: 4,
      equipment: "full_gym",
      preferences: "ninguna"
    }, 2800, macrosMock);

    console.log("✅ RESULTADO TEST 2:");
    console.log(`- Días generados: ${plan2.days.length}`);
    console.log(`- Día 1 Focus: ${plan2.days[0].focus}`);
    console.log(`- Ejercicios Día 1: ${plan2.days[0].exercises.length}`);
    console.log(`- Primer ejercicio: ${plan2.days[0].exercises[0].name} (${plan2.days[0].exercises[0].sets} series)`);
    
    console.log("\n-----------------------------------\n");

    console.log(">> Test 3: Intermedio, 3 días, fuerza (preferencia: 'quiero mejorar abdomen')");
    const plan3 = await generateBasicPlan({
      objective: "strength",
      experienceLevel: "intermediate",
      daysPerWeek: 3,
      equipment: "dumbbells",
      preferences: "quiero mejorar abdomen"
    }, 2500, macrosMock);

    console.log("✅ RESULTADO TEST 3:");
    console.log(`- Repeticiones objetivo (debe ser 4-6 para fuerza): ${plan3.days[0].exercises[0].reps}`);
    console.log(`- Descanso objetivo (debe ser 120s para fuerza): ${plan3.days[0].exercises[0].restSeconds}s`);
    console.log(`- Ejercicios Día 1 (debe incluir 2 de abdomen extra, total 7): ${plan3.days[0].exercises.length}`);
    const lastEx = plan3.days[0].exercises[plan3.days[0].exercises.length - 1];
    console.log(`- Último ejercicio del Día 1: ${lastEx.name} (Grupo: ${lastEx.muscleGroup})`);

  } catch (error) {
    console.error("❌ ERROR DURANTE EL QA TEST:", error);
  }
  
  process.exit(0);
}

runTest();
