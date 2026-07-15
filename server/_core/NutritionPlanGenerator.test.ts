import { describe, it, expect } from "vitest";
import { generateNutritionPlan } from "./NutritionPlanGenerator";

describe("NutritionPlanGenerator", () => {
  it("generates a plan with coherent meals", () => {
    const plan = generateNutritionPlan({
      age: 30,
      weight: 70,
      height: 170,
      gender: "male",
      activityLevel: "moderate",
      objective: "muscle_gain",
      mealFrequency: 4,
      dietaryRestrictions: [],
    });

    expect(plan.meals.length).toBe(4);
    expect(plan.dailyCalories).toBeGreaterThan(0);
    expect(plan.dailyMacros.protein).toBeGreaterThan(0);

    for (const meal of plan.meals) {
      expect(meal.foods.length).toBeGreaterThan(0);
      expect(meal.calories).toBeGreaterThan(0);
      // No duplicate foods within a meal
      const names = meal.foods.map(f => f.name);
      expect(new Set(names).size).toBe(names.length);
    }
  });

  it("respects dietary restrictions (vegan)", () => {
    const plan = generateNutritionPlan({
      age: 30,
      weight: 60,
      height: 165,
      gender: "female",
      activityLevel: "light",
      objective: "fat_loss",
      mealFrequency: 3,
      dietaryRestrictions: ["vegan"],
    });

    const forbidden = ["huevo", "huevo entero", "claras de huevo", "pechuga de pollo", "pechuga de pavo", "salmon", "salmón", "atun", "atún", "carne magra", "yogur griego", "yogur griego 0%", "queso cottage"];
    for (const meal of plan.meals) {
      for (const food of meal.foods) {
        expect(forbidden).not.toContain(food.name.toLowerCase());
      }
    }
  });

  it("uses food preferences when provided", () => {
    const plan = generateNutritionPlan({
      age: 30,
      weight: 70,
      height: 170,
      gender: "male",
      activityLevel: "moderate",
      objective: "muscle_gain",
      mealFrequency: 4,
      dietaryRestrictions: [],
      foodPreferences: ["pechuga de pollo"],
    });

    const allFoods = plan.meals.flatMap(m => m.foods.map(f => f.name.toLowerCase()));
    expect(allFoods.some(f => f.includes("pollo"))).toBe(true);
  });
});
