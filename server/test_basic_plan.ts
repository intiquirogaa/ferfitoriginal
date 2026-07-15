import "dotenv/config";
import { generateBasicPlan } from "./_core/basic_plan_generator";
import { NutritionInput } from "./_core/NutritionPlanGenerator";

async function main() {
  try {
    const { generateNutritionPlan } = await import("./_core/NutritionPlanGenerator");
    const plan = generateNutritionPlan({
      age: 30, weight: 80, height: 180, gender: "male",
      activityLevel: "moderate", objective: "muscle_gain",
      mealFrequency: 4, dietaryRestrictions: []
    });
    console.log("Success! Generated basic plan meals:", plan.meals.length);
  } catch (err: any) {
    console.error("Execution failed:", err.stack || err);
  }
}
main();
