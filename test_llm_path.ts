import { generatePersonalizedPlanWithNutrition } from "./server/routers.js";

async function runTest() {
  console.log("=== TEST DEL CAMINO LLM (generatePersonalizedPlanWithNutrition) ===\n");
  
  try {
    const plan = await generatePersonalizedPlanWithNutrition({
      objective: "hypertrophy",
      experienceLevel: "intermediate",
      age: 28,
      weight: 75,
      height: 180,
      daysPerWeek: 4,
      equipment: "full_gym",
      injuries: "",
      preferences: "",
    });
    
    console.log("✅ Plan generado exitosamente");
    console.log(`- Días: ${plan.days.length}`);
    console.log(`- Día 1 ejercicios: ${plan.days[0].exercises.map((e:any)=>e.name).join(", ")}`);
    
  } catch (error) {
    console.error("❌ ERROR:", error);
  }
  
  process.exit(0);
}

runTest();
