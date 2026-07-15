import * as dotenv from "dotenv";
dotenv.config();

import { appRouter } from "./routers";
import { createContext } from "./_core/context";
import { generateNutritionPlan } from "./_core/NutritionPlanGenerator";

async function testAll() {
  console.log("=== Testing LLM ===");
  try {
    const { invokeLLM } = await import("./_core/llm");
    const res = await invokeLLM({
      messages: [{ role: "user", content: "Hola!" }],
      maxTokens: 10,
    });
    console.log("LLM ok:", res.choices[0].message.content);
  } catch(e) {
    console.error("LLM Error:", e);
  }

  console.log("\n=== Testing NutritionPlanGenerator ===");
  try {
    const plan = generateNutritionPlan({
      age: 30, weight: 70, height: 170, gender: "male",
      activityLevel: "moderate", objective: "maintenance",
      mealFrequency: 4, dietaryRestrictions: []
    });
    console.log("Nutrition Plan ok, calories:", plan.dailyCalories);
  } catch(e) {
    console.error("Nutrition Plan Error:", e);
  }
}

testAll();
