import "dotenv/config";
import path from "path";

async function main() {
  try {
    console.log("Calling generatePersonalizedPlanWithNutrition...");
    const { generatePersonalizedPlanWithNutrition } = await import("./routers");
    
    const plan = await generatePersonalizedPlanWithNutrition({
      objective: "strength",
      experienceLevel: "beginner",
      age: 30,
      weight: 80,
      height: 180,
      daysPerWeek: 3,
      equipment: "bodyweight",
      injuries: "ninguna",
      preferences: "ninguna"
    });
    
    console.log("\n================ RESULT ================");
    console.log(`Plan generado con éxito. Días: ${plan.days?.length}`);
    console.log("\n========================================");
  } catch (err: any) {
    console.error("Execution failed:", err.stack || err);
  }
}

main();
