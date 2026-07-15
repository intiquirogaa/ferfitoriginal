export const macro_rules = {
  version: "1.0.0",
  sources: ["ISSN position stand on nutrition for athletes", "WHO macronutrient guidelines"],
  objectives: {
    fat_loss: { calorie_adjustment: -400, protein_per_kg: 2.2, fat_per_kg: 0.8, carbs_from_remaining: true, fiber_target_g: 30 },
    muscle_gain: { calorie_adjustment: 300, protein_per_kg: 2.0, fat_per_kg: 1.0, carbs_from_remaining: true, fiber_target_g: 25 },
    maintenance: { calorie_adjustment: 0, protein_per_kg: 1.8, fat_per_kg: 0.9, carbs_from_remaining: true, fiber_target_g: 28 },
    general_health: { calorie_adjustment: -200, protein_per_kg: 1.5, fat_per_kg: 0.8, carbs_from_remaining: true, fiber_target_g: 30 }
  },
  meal_distribution: {
    "3": [0.30, 0.40, 0.30],
    "4": [0.25, 0.35, 0.15, 0.25],
    "5": [0.20, 0.10, 0.30, 0.10, 0.30],
    "6": [0.18, 0.08, 0.28, 0.10, 0.10, 0.26]
  }
};

export const dietary_filters = {
  version: "1.0.0",
  filters: {
    vegan: { exclude_ids: ["egg","egg_white","chicken_breast","turkey_breast","salmon","tuna_canned","lean_beef","greek_yogurt","cottage_cheese","whey_protein"] },
    vegetarian: { exclude_ids: ["chicken_breast","turkey_breast","salmon","tuna_canned","lean_beef"] },
    gluten_free: { exclude_ids: ["bread_whole","pasta_whole","oats"] },
    dairy_free: { exclude_ids: ["greek_yogurt","cottage_cheese","whey_protein"] },
    nut_free: { exclude_ids: ["almonds","peanut_butter"] },
    seafood_free: { exclude_ids: ["salmon","tuna_canned"] }
  }
};

export const meal_slots = {
  breakfast: { names: ["Desayuno"], time: "08:00" },
  lunch: { names: ["Almuerzo"], time: "13:00" },
  dinner: { names: ["Cena"], time: "20:00" },
  snack: { names: ["Snack","Merienda"], time: "11:00" }
};

export const hydration = {
  fat_loss: "3-4 litros de agua diarios",
  muscle_gain: "3 litros de agua diarios",
  maintenance: "2.5-3 litros de agua diarios",
  general_health: "2-3 litros de agua diarios"
};

export const supplement = {
  fat_loss: "Multivitaminico, Omega-3",
  muscle_gain: "Creatina (5g/dia), Omega-3, Multivitaminico",
  maintenance: "Omega-3, Multivitaminico",
  general_health: "Multivitaminico"
};
