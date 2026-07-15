import { readFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { macro_rules, dietary_filters, meal_slots, hydration, supplement } from "./nutrition_knowledge/rules";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export type Food = {
  id: string;
  name: string;
  category: "protein" | "protein_carb" | "carb" | "fat" | "vegetable" | "fruit";
  calories_per_100g: number;
  protein_per_100g: number;
  carbs_per_100g: number;
  fats_per_100g: number;
  fiber_per_100g: number;
  tags: string[];
  dietary_tags: string[];
  prep_time: string;
  cost_level: "budget" | "medium" | "premium";
  meal_slot: string[];
};

export type MealFood = {
  name: string;
  quantity: number;
  unit: string;
};

export type Meal = {
  mealNumber: number;
  time: string;
  name: string;
  foods: MealFood[];
  macros: { protein: number; carbs: number; fats: number };
  calories: number;
  notes: string;
};

export type NutritionPlan = {
  dailyCalories: number;
  dailyMacros: { protein: number; carbs: number; fats: number };
  mealFrequency: number;
  meals: Meal[];
  tips: string[];
  hydration: string;
  supplementation: string;
  notes: string;
};

export type NutritionInput = {
  age: number;
  weight: number;
  height: number;
  gender: "male" | "female";
  activityLevel: "sedentary" | "light" | "moderate" | "active" | "very_active";
  objective: "fat_loss" | "muscle_gain" | "maintenance" | "general_health";
  mealFrequency: 3 | 4 | 5 | 6;
  dietaryRestrictions: string[];
  foodPreferences?: string[];
  foodDislikes?: string[];
  prepTime?: "<15min" | "15-30min" | "30-60min" | ">60min";
  budget?: "budget" | "medium" | "premium";
};

let foodCatalog: Food[] | null = null;

import fs from "fs";

function loadFoodCatalog(): Food[] {
  if (foodCatalog) return foodCatalog;
  let path = join(__dirname, "nutrition_knowledge", "food_catalog.json");
  if (!fs.existsSync(path)) {
    path = join(process.cwd(), "server", "_core", "nutrition_knowledge", "food_catalog.json");
  }
  const raw = fs.readFileSync(path, "utf-8");
  const parsed = JSON.parse(raw);
  foodCatalog = parsed.foods as Food[];
  return foodCatalog!;
}

function calculateTDEE(input: NutritionInput): number {
  const { weight, height, age, gender, activityLevel } = input;
  const bmr = gender === "male"
    ? 10 * weight + 6.25 * height - 5 * age + 5
    : 10 * weight + 6.25 * height - 5 * age - 161;
  const multipliers = {
    sedentary: 1.2,
    light: 1.375,
    moderate: 1.55,
    active: 1.725,
    very_active: 1.9,
  };
  return Math.round(bmr * multipliers[activityLevel]);
}

function calculateMacros(input: NutritionInput, tdee: number) {
  const rule = macro_rules.objectives[input.objective];
  const protein = Math.round(rule.protein_per_kg * input.weight);
  const fats = Math.round(rule.fat_per_kg * input.weight);
  const targetCalories = tdee + rule.calorie_adjustment;
  const carbs = Math.round((targetCalories - protein * 4 - fats * 9) / 4);
  return {
    dailyCalories: targetCalories,
    protein,
    carbs: Math.max(0, carbs),
    fats,
    fiber: rule.fiber_target_g,
  };
}

function filterFoods(foods: Food[], input: NutritionInput): Food[] {
  const dislikes = new Set((input.foodDislikes || []).map(d => d.toLowerCase()));
  const preferences = new Set((input.foodPreferences || []).map(p => p.toLowerCase()));
  const restrictions = input.dietaryRestrictions || [];
  const budget = input.budget || "medium";
  const prepTime = input.prepTime || "15-30min";

  const prepOrder = ["<15min", "15-30min", "30-60min", ">60min"];
  const maxPrepIndex = prepOrder.indexOf(prepTime);

  const budgetOrder = ["budget", "medium", "premium"];
  const maxBudgetIndex = budgetOrder.indexOf(budget);

  let filtered = foods.filter(f => {
    const costIndex = budgetOrder.indexOf(f.cost_level);
    if (costIndex > maxBudgetIndex) return false;

    const prepIndex = prepOrder.indexOf(f.prep_time);
    if (prepIndex > maxPrepIndex) return false;

    if (dislikes.has(f.name.toLowerCase())) return false;
    if (dislikes.has(f.id.toLowerCase())) return false;

    return true;
  });

  for (const restriction of restrictions) {
    const filter = dietary_filters.filters[restriction as keyof typeof dietary_filters.filters];
    if (filter?.exclude_ids) {
      const excludeSet = new Set(filter.exclude_ids);
      filtered = filtered.filter(f => !excludeSet.has(f.id));
    }
  }

  // Prefer foods matching user preferences when possible
  if (preferences.size > 0) {
    const preferred = filtered.filter(f =>
      preferences.has(f.name.toLowerCase()) ||
      preferences.has(f.id.toLowerCase()) ||
      f.tags.some(t => preferences.has(t.toLowerCase()))
    );
    if (preferred.length >= 5) {
      return preferred;
    }
    // Otherwise keep all filtered but boost preferred later by selection order
  }

  return filtered;
}

function pickFoodsForMeal(
  pool: Food[],
  slot: "breakfast" | "lunch" | "dinner" | "snack",
  targetMacros: { protein: number; carbs: number; fats: number },
  targetCalories: number,
  mealNumber: number,
  input: NutritionInput
): Meal {
  const slotInfo = meal_slots[slot as keyof typeof meal_slots];
  const selected: { food: Food; grams: number }[] = [];
  const selectedNames = new Set<string>();
  let current = { protein: 0, carbs: 0, fats: 0, calories: 0 };

  // Strict slot filtering: food must explicitly allow this slot.
  // If the slot pool is too small, fall back to foods that allow lunch/dinner.
  let slotPool = pool.filter(f => f.meal_slot.includes(slot));
  if (slotPool.length < 5 && (slot === "breakfast" || slot === "snack")) {
    slotPool = pool.filter(f => f.meal_slot.includes("breakfast") || f.meal_slot.includes("snack"));
  }

  // Prefer foods matching user preferences; otherwise shuffle
  const preferences = new Set((input.foodPreferences || []).map(p => p.toLowerCase()));
  const preferred = slotPool.filter(f =>
    preferences.has(f.name.toLowerCase()) ||
    preferences.has(f.id.toLowerCase()) ||
    f.tags.some(t => preferences.has(t.toLowerCase()))
  );

  function pickFrom(candidates: Food[]): Food | null {
    if (candidates.length === 0) return null;
    const preferredCandidates = preferred.filter(f => candidates.includes(f) && !selectedNames.has(f.name));
    const poolCandidates = candidates.filter(f => !selectedNames.has(f.name));
    const source = preferredCandidates.length > 0 ? preferredCandidates : poolCandidates;
    if (source.length === 0) return null;
    return source[Math.floor(Math.random() * source.length)];
  }

  const proteins = slotPool.filter(f => f.category === "protein" || f.category === "protein_carb");
  const carbs = slotPool.filter(f => f.category === "carb" || f.category === "protein_carb");
  const fats = slotPool.filter(f => f.category === "fat" || f.fats_per_100g > 5);
  const vegetables = slotPool.filter(f => f.category === "vegetable");
  const fruits = slotPool.filter(f => f.category === "fruit");

  function addFood(food: Food, targetGrams: number) {
    if (selectedNames.has(food.name)) return;
    const grams = Math.max(10, Math.round(targetGrams));
    const p = (food.protein_per_100g * grams) / 100;
    const c = (food.carbs_per_100g * grams) / 100;
    const f = (food.fats_per_100g * grams) / 100;
    const kcal = (food.calories_per_100g * grams) / 100;
    selected.push({ food, grams });
    selectedNames.add(food.name);
    current.protein += p;
    current.carbs += c;
    current.fats += f;
    current.calories += kcal;
  }

  // Base protein
  if (proteins.length > 0 && targetMacros.protein > 0) {
    const proteinFood = pickFrom(proteins);
    if (proteinFood) {
      const targetGrams = (targetMacros.protein * 0.6) / (proteinFood.protein_per_100g / 100);
      addFood(proteinFood, targetGrams);
    }
  }

  // Base carb
  if (carbs.length > 0 && targetMacros.carbs > 0) {
    const carbFood = pickFrom(carbs);
    if (carbFood) {
      const targetGrams = (targetMacros.carbs * 0.5) / (carbFood.carbs_per_100g / 100);
      addFood(carbFood, targetGrams);
    }
  }

  // Base fat
  if (fats.length > 0 && targetMacros.fats > 0) {
    const fatFood = pickFrom(fats);
    if (fatFood) {
      const targetGrams = (targetMacros.fats * 0.4) / (fatFood.fats_per_100g / 100);
      addFood(fatFood, targetGrams);
    }
  }

  // Vegetables for lunch/dinner
  if ((slot === "lunch" || slot === "dinner") && vegetables.length > 0) {
    const veg = pickFrom(vegetables);
    if (veg) addFood(veg, 150);
  }

  // Fruit for breakfast/snack
  if ((slot === "breakfast" || slot === "snack") && fruits.length > 0) {
    const fruit = pickFrom(fruits);
    if (fruit) addFood(fruit, 100);
  }

  // Fine-tune: fill remaining macros without duplicating foods
  const remaining = {
    protein: targetMacros.protein - current.protein,
    carbs: targetMacros.carbs - current.carbs,
    fats: targetMacros.fats - current.fats,
    calories: targetCalories - current.calories,
  };

  if (remaining.protein > 5 && proteins.length > 0) {
    const food = pickFrom(proteins);
    if (food) addFood(food, remaining.protein / (food.protein_per_100g / 100));
  }
  if (remaining.carbs > 10 && carbs.length > 0) {
    const food = pickFrom(carbs);
    if (food) addFood(food, remaining.carbs / (food.carbs_per_100g / 100));
  }
  if (remaining.fats > 5 && fats.length > 0) {
    const food = pickFrom(fats);
    if (food) addFood(food, remaining.fats / (food.fats_per_100g / 100));
  }

  // Final calorie adjustment: scale portions proportionally if we overshoot/undershoot
  if (selected.length > 0 && current.calories > 0 && Math.abs(current.calories - targetCalories) > targetCalories * 0.1) {
    const scale = Math.min(Math.max(targetCalories / current.calories, 0.5), 1.5);
    for (const item of selected) {
      item.grams = Math.max(10, Math.round(item.grams * scale));
    }
    // Recalculate macros/calories after scaling
    current = { protein: 0, carbs: 0, fats: 0, calories: 0 };
    for (const item of selected) {
      const f = item.food;
      const g = item.grams;
      current.protein += (f.protein_per_100g * g) / 100;
      current.carbs += (f.carbs_per_100g * g) / 100;
      current.fats += (f.fats_per_100g * g) / 100;
      current.calories += (f.calories_per_100g * g) / 100;
    }
  }

  const foods: MealFood[] = selected.map(s => ({
    name: s.food.name,
    quantity: s.grams,
    unit: "g",
  }));

  return {
    mealNumber,
    time: slotInfo.time,
    name: slotInfo.names[mealNumber % slotInfo.names.length] || slotInfo.names[0],
    foods,
    macros: {
      protein: Math.round(current.protein),
      carbs: Math.round(current.carbs),
      fats: Math.round(current.fats),
    },
    calories: Math.round(current.calories),
    notes: `Comida ${slot} armada con alimentos del catalogo.`,
  };
}

function assignSlots(frequency: number): Array<"breakfast" | "lunch" | "dinner" | "snack"> {
  switch (frequency) {
    case 3: return ["breakfast", "lunch", "dinner"];
    case 4: return ["breakfast", "snack", "lunch", "dinner"];
    case 5: return ["breakfast", "snack", "lunch", "snack", "dinner"];
    case 6: return ["breakfast", "snack", "lunch", "snack", "dinner", "snack"];
    default: return ["breakfast", "lunch", "dinner"];
  }
}

export function generateNutritionPlan(input: NutritionInput): NutritionPlan {
  const foods = loadFoodCatalog();
  let filtered = filterFoods(foods, input);

  if (filtered.length < 5) {
    const relaxedInput = { ...input, foodDislikes: [], budget: "premium" as any, prepTime: ">60min" as any };
    filtered = filterFoods(foods, relaxedInput);
    if (filtered.length < 5) {
      filtered = foods; // Fallback extremo
    }
  }

  const tdee = calculateTDEE(input);
  const macros = calculateMacros(input, tdee);
  const distribution = macro_rules.meal_distribution[String(input.mealFrequency) as keyof typeof macro_rules.meal_distribution];
  const slots = assignSlots(input.mealFrequency);

  const meals: Meal[] = slots.map((slot, idx) => {
    const ratio = distribution[idx];
    const mealMacros = {
      protein: Math.round(macros.protein * ratio),
      carbs: Math.round(macros.carbs * ratio),
      fats: Math.round(macros.fats * ratio),
    };
    const mealCalories = Math.round(macros.dailyCalories * ratio);
    return pickFoodsForMeal(filtered, slot, mealMacros, mealCalories, idx + 1, input);
  });

  const totalProtein = meals.reduce((sum, m) => sum + m.macros.protein, 0);
  const totalCarbs = meals.reduce((sum, m) => sum + m.macros.carbs, 0);
  const totalFats = meals.reduce((sum, m) => sum + m.macros.fats, 0);
  const totalCalories = meals.reduce((sum, m) => sum + m.calories, 0);

  return {
    dailyCalories: totalCalories,
    dailyMacros: { protein: totalProtein, carbs: totalCarbs, fats: totalFats },
    mealFrequency: input.mealFrequency,
    meals,
    tips: [
      "Distribui la proteina en todas las comidas para optimizar la sintesis muscular.",
      "Prioriza carbohidratos complejos en comidas principales y simples cerca del entrenamiento.",
      "Incluye una fuente de grasa saludable en cada comida principal.",
      "Bebe agua consistentemente a lo largo del dia, no solo durante las comidas.",
    ],
    hydration: hydration[input.objective],
    supplementation: supplement[input.objective],
    notes: `Plan generado algoritmicamente para ${input.objective}. TDEE estimado: ${tdee} kcal.`,
  };
}

export { calculateTDEE as calculateNutritionTDEE, calculateMacros as calculateNutritionMacros };
