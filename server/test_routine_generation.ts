import dotenv from "dotenv";
import path from "path";

// Load environment variables using process.cwd() first
dotenv.config({ path: path.resolve(process.cwd(), ".env") });

async function main() {
  try {
    console.log("Calling generatePersonalizedPlanWithNutrition (after dotenv load)...");
    
    // Dynamic import to prevent ESM compile-time execution before dotenv
    const { generatePersonalizedPlanWithNutrition } = await import("./routers");
    
    const plan = await generatePersonalizedPlanWithNutrition({
      objective: "strength",
      experienceLevel: "beginner",
      age: 30,
      weight: 80,
      height: 180,
      daysPerWeek: 3,
      equipment: "bodyweight",
      injuries: "dolor de rodilla",
      preferences: "solo zona media y cardio"
    });
    
    console.log("\n================ RESULT ================");
    console.log(JSON.stringify(plan, null, 2));
    console.log("\n========================================");
  } catch (err: any) {
    console.error("Execution failed:", err.stack || err);
  }
}

main();
