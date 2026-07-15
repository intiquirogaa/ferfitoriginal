import { useState, useEffect, useMemo } from "react";
import { trpc } from "@/lib/trpc";
import DashboardLayout from "@/components/DashboardLayout";
import { NutritionPlanSelector } from "@/components/NutritionPlanSelector";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import { Apple, Droplets, Pill, Plus, Zap, Check, TrendingUp, Info, Loader2, ChefHat, Sparkles } from "lucide-react";
import type { GeneratedTrainingAndNutritionPlan, Meal, MealFood } from "@/types";
import { toast } from "sonner";

const MEAL_IMAGES: Record<string, string> = {
  desayuno: "https://images.unsplash.com/photo-1511690656952-34342bb7c2f2?w=500&auto=format&fit=crop&q=60",
  almuerzo: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop&q=60",
  cena: "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&auto=format&fit=crop&q=60",
  snack: "https://images.unsplash.com/photo-1505576399279-565b52d4ac71?w=500&auto=format&fit=crop&q=60",
};

// Mapa de nombres de alimentos (en español, como vienen del NutritionPlanGenerator)
// a IDs del catálogo food_catalog.json. Si el ID tiene imagen en /foods/{id}.jpg,
// se usa esa imagen local en lugar de generar con IA.
const FOOD_NAME_TO_ID: Record<string, string> = {
  "huevo entero": "egg",
  "huevo": "egg",
  "huevos": "egg",
  "claras de huevo": "egg_white",
  "clara de huevo": "egg_white",
  "pechuga de pollo": "chicken_breast",
  "pollo": "chicken_breast",
  "pechuga de pavo": "turkey_breast",
  "pavo": "turkey_breast",
  "salmon": "salmon",
  "salmón": "salmon",
  "atun enlatado": "tuna_canned",
  "atun": "tuna_canned",
  "atún": "tuna_canned",
  "carne magra": "lean_beef",
  "carne": "lean_beef",
  "yogur griego": "greek_yogurt",
  "yogur griego 0%": "greek_yogurt",
  "yogur": "greek_yogurt",
  "tofu": "tofu",
  "arroz blanco": "rice_white",
  "arroz": "rice_white",
};

// IDs con imagen local en /foods/
const FOODS_WITH_LOCAL_IMAGE = new Set([
  "egg", "egg_white", "chicken_breast", "turkey_breast", "salmon",
  "tuna_canned", "lean_beef", "greek_yogurt", "tofu", "rice_white",
]);

const DAYS_ES = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"];

function isMealFood(food: string | MealFood): food is MealFood {
  return typeof food === "object" && food !== null && "name" in food;
}

function formatFood(food: string | MealFood): string {
  if (isMealFood(food)) {
    const qty = food.quantity ? `${food.quantity}${food.unit ? ` ${food.unit}` : ""}` : "";
    return qty ? `${food.name} (${qty})` : food.name;
  }
  return food;
}

function foodsToString(foods: Array<string | MealFood>): string {
  return foods.map(formatFood).join(", ");
}

function getLocalFoodImage(foods: Array<string | MealFood>): string | null {
  for (const food of foods) {
    const name = (isMealFood(food) ? food.name : food).toLowerCase().trim();
    const id = FOOD_NAME_TO_ID[name];
    if (id && FOODS_WITH_LOCAL_IMAGE.has(id)) {
      return `/foods/${id}.jpg`;
    }
  }
  return null;
}

function getMealImageKey(name: string): string {
  const clean = name.toLowerCase();
  if (clean.includes("desayuno") || clean.includes("breakfast") || clean.includes("smoothie")) return "desayuno";
  if (clean.includes("almuerzo") || clean.includes("lunch")) return "almuerzo";
  if (clean.includes("cena") || clean.includes("dinner")) return "cena";
  return "snack";
}

function NutritionRings({ consumed, target }: { consumed: { protein: number; carbs: number; fats: number }; target: { protein: number; carbs: number; fats: number } }) {
  const radius = 45;
  const circumference = 2 * Math.PI * radius;

  const proteinPct = Math.min(consumed.protein / target.protein, 1);
  const carbsPct = Math.min(consumed.carbs / target.carbs, 1);
  const fatsPct = Math.min(consumed.fats / target.fats, 1);

  return (
    <div className="relative w-64 h-64 flex items-center justify-center">
      <svg viewBox="0 0 200 220" className="w-full h-full overflow-visible">
        <circle cx="100" cy="70" r={radius} fill="none" stroke="rgba(255,255,255,0.03)" strokeWidth="8" />
        <circle
          cx="100" cy="70" r={radius} fill="none"
          stroke="oklch(0.6 0.2 300)" strokeWidth="8"
          strokeDasharray={circumference}
          strokeDashoffset={circumference * (1 - proteinPct)}
          strokeLinecap="round"
          transform="rotate(-90 100 70)"
        />
        <circle cx="130" cy="130" r={radius} fill="none" stroke="rgba(255,255,255,0.03)" strokeWidth="8" />
        <circle
          cx="130" cy="130" r={radius} fill="none"
          stroke="oklch(0.72 0.2 145)" strokeWidth="8"
          strokeDasharray={circumference}
          strokeDashoffset={circumference * (1 - carbsPct)}
          strokeLinecap="round"
          transform="rotate(-90 130 130)"
        />
        <circle cx="70" cy="130" r={radius} fill="none" stroke="rgba(255,255,255,0.03)" strokeWidth="8" />
        <circle
          cx="70" cy="130" r={radius} fill="none"
          stroke="oklch(0.72 0.2 145 / 0.5)" strokeWidth="8"
          strokeDasharray={circumference}
          strokeDashoffset={circumference * (1 - fatsPct)}
          strokeLinecap="round"
          transform="rotate(-90 70 130)"
        />
      </svg>

      <div className="absolute top-8 left-[90px] text-left">
        <p className="text-[10px] font-bold text-purple-400 leading-none">Protein</p>
        <p className="text-xs font-semibold text-foreground mt-0.5">({Math.round(consumed.protein)}g/{target.protein}g)</p>
      </div>
      <div className="absolute bottom-16 right-0 text-left">
        <p className="text-[10px] font-bold text-accent leading-none">Carbs</p>
        <p className="text-xs font-semibold text-foreground mt-0.5">({Math.round(consumed.carbs)}g/{target.carbs}g)</p>
      </div>
      <div className="absolute bottom-16 left-2 text-left">
        <p className="text-[10px] font-bold text-accent/60 leading-none">Fats</p>
        <p className="text-xs font-semibold text-foreground mt-0.5">({Math.round(consumed.fats)}g/{target.fats}g)</p>
      </div>
    </div>
  );
}

function MealCard({
  meal,
  consumed,
  onToggle,
  imageUrl,
  onGenerateImage,
  generatingImage,
}: {
  meal: Meal;
  consumed: boolean;
  onToggle: () => void;
  imageUrl: string;
  onGenerateImage: () => void;
  generatingImage: boolean;
}) {
  return (
    <Card className="overflow-hidden glass-panel flex flex-col h-full text-left">
      <div className="h-44 w-full overflow-hidden relative">
        <img
          src={imageUrl}
          alt={meal.name}
          className="w-full h-full object-cover transition-transform duration-350 hover:scale-105"
        />
        <div className="absolute top-3 right-3">
          <Badge className="bg-accent text-accent-foreground font-semibold">{meal.calories} kcal</Badge>
        </div>
      </div>
      <div className="p-4 flex-1 flex flex-col justify-between space-y-4">
        <div>
          <p className="text-[10px] font-bold text-accent uppercase tracking-wider">{meal.time || "Comida"}</p>
          <h4 className="font-bold text-base text-foreground mt-1 line-clamp-1">{meal.name}</h4>
          <div className="flex flex-wrap gap-1 mt-2">
            {meal.foods?.slice(0, 3).map((f, i) => (
              <span key={i} className="text-[10px] text-muted-foreground bg-muted/30 px-2 py-0.5 rounded-full">{formatFood(f)}</span>
            ))}
          </div>
        </div>

        <div className="pt-2 border-t border-border/10 flex justify-between items-center text-xs">
          <div className="text-left">
            <span className="text-[10px] text-muted-foreground uppercase block">Prot</span>
            <span className="font-semibold text-purple-400">{meal.macros?.protein || 0}g</span>
          </div>
          <div className="text-left">
            <span className="text-[10px] text-muted-foreground uppercase block">Carbs</span>
            <span className="font-semibold text-accent">{meal.macros?.carbs || 0}g</span>
          </div>
          <div className="text-left">
            <span className="text-[10px] text-muted-foreground uppercase block">Grasas</span>
            <span className="font-semibold text-accent/80">{meal.macros?.fats || 0}g</span>
          </div>
        </div>

        <Button
          size="sm"
          onClick={onToggle}
          className={`w-full gap-2 text-xs py-1.5 font-bold uppercase tracking-wider rounded-xl transition-all ${
            consumed
              ? "bg-accent/20 text-accent border border-accent/40 hover:bg-accent/30"
              : "bg-accent text-accent-foreground hover:bg-accent/90"
          }`}
        >
          {consumed ? <><Check className="w-3.5 h-3.5" /> Realizada</> : <><Check className="w-3.5 h-3.5" /> Marcar como realizada</>}
        </Button>

        <button
          onClick={onGenerateImage}
          disabled={generatingImage}
          className="text-[10px] text-muted-foreground hover:text-accent flex items-center justify-center gap-1 disabled:opacity-50"
        >
          {generatingImage ? <Loader2 className="w-3 h-3 animate-spin" /> : <Zap className="w-3 h-3" />}
          {generatingImage ? "Generando imagen..." : "Generar imagen con IA"}
        </button>
      </div>
    </Card>
  );
}

function AdherenceCard({ percentage, consumed, total }: { percentage: number; consumed: number; total: number }) {
  return (
    <Card className="p-5 glass-panel text-left">
      <h3 className="font-semibold text-foreground mb-3 flex items-center gap-2 text-sm">
        <TrendingUp className="w-5 h-5 text-accent" /> Adherencia Semanal
      </h3>
      <div className="flex items-center gap-4">
        <div className="relative w-16 h-16">
          <svg viewBox="0 0 100 100" className="w-full h-full transform -rotate-90">
            <circle cx="50" cy="50" r="40" fill="none" stroke="rgba(255,255,255,0.03)" strokeWidth="8" />
            <circle
              cx="50" cy="50" r="40" fill="none"
              stroke="oklch(0.72 0.2 145)" strokeWidth="8"
              strokeDasharray={2 * Math.PI * 40}
              strokeDashoffset={2 * Math.PI * 40 * (1 - percentage / 100)}
              strokeLinecap="round"
            />
          </svg>
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="text-sm font-bold text-foreground">{percentage}%</span>
          </div>
        </div>
        <div>
          <p className="text-xs text-muted-foreground">Comidas registradas</p>
          <p className="text-lg font-bold text-accent font-display">{consumed} / {total}</p>
        </div>
      </div>
    </Card>
  );
}

function Heatmap({ logs, startDate, endDate }: { logs: any[]; startDate: Date; endDate: Date }) {
  const days: { date: Date; consumed: number; total: number }[] = [];
  const current = new Date(startDate);
  while (current <= endDate) {
    const dayLogs = logs.filter((log: any) => {
      const logDate = new Date(log.date);
      return logDate.toDateString() === current.toDateString();
    });
    days.push({
      date: new Date(current),
      consumed: dayLogs.filter((l: any) => l.consumed === 1).length,
      total: dayLogs.length || 1,
    });
    current.setDate(current.getDate() + 1);
  }

  return (
    <div className="grid grid-cols-7 gap-1">
      {days.map((day, i) => {
        const pct = day.consumed / day.total;
        return (
          <div
            key={i}
            className="aspect-square rounded-md flex items-center justify-center text-[10px] font-medium relative group"
            style={{ backgroundColor: `rgba(34, 197, 94, ${Math.max(pct, 0.1)})` }}
          >
            <span className="text-foreground/70">{day.date.getDate()}</span>
            <div className="absolute bottom-full mb-1 hidden group-hover:block bg-background border border-border/30 rounded-lg p-2 text-xs whitespace-nowrap z-10">
              {day.date.toLocaleDateString("es-AR")}: {day.consumed}/{day.total} comidas
            </div>
          </div>
        );
      })}
    </div>
  );
}

function CoachMarks({ onClose }: { onClose: () => void }) {
  const [step, setStep] = useState(0);
  const tips = [
    { title: "Registrá cada comida", desc: "Marcá las comidas como realizadas para calcular tu adherencia real." },
    { title: "Anillos de macros", desc: "Los anillos muestran tu progreso diario de proteínas, carbos y grasas." },
    { title: "Imágenes con IA", desc: "Tocá 'Generar imagen con IA' en cada comida para verla de forma personalizada." },
  ];

  if (step >= tips.length) {
    onClose();
    return null;
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <Card className="max-w-sm p-6 glass-panel text-center">
        <div className="w-12 h-12 rounded-full bg-accent/20 flex items-center justify-center mx-auto mb-4">
          <Info className="w-6 h-6 text-accent" />
        </div>
        <h3 className="font-display text-xl font-bold text-foreground mb-2">{tips[step].title}</h3>
        <p className="text-sm text-muted-foreground mb-6">{tips[step].desc}</p>
        <div className="flex justify-center gap-1.5 mb-4">
          {tips.map((_, i) => (
            <div key={i} className={`h-1.5 rounded-full transition-all ${i === step ? "w-5 bg-accent" : "w-1.5 bg-muted/50"}`} />
          ))}
        </div>
        <Button onClick={() => setStep(step + 1)} className="bg-accent text-accent-foreground hover:bg-accent/90 w-full">
          {step === tips.length - 1 ? "Entendido" : "Siguiente"}
        </Button>
      </Card>
    </div>
  );
}

export default function Nutricion() {
  const [wizardOpen, setWizardOpen] = useState(false);
  const [activeTab, setActiveTab] = useState("today");
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [mealImages, setMealImages] = useState<Record<number, string>>({});
  const [generatingImage, setGeneratingImage] = useState<Record<number, boolean>>({});
  const [showCoachMarks, setShowCoachMarks] = useState(false);
  const [fridgeOpen, setFridgeOpen] = useState(false);
  const [fridgeIngredients, setFridgeIngredients] = useState("");
  const [fridgeRecipe, setFridgeRecipe] = useState<any>(null);
  const [fridgeLoading, setFridgeLoading] = useState(false);
  const utils = trpc.useUtils();

  const { data: nutritionPlanData, isLoading } = trpc.nutrition.getActivePlan.useQuery();
  const hasPlan = nutritionPlanData?.hasPlan || false;
  const nutritionPlanId = nutritionPlanData?.planId || 1;

  const nutrition = nutritionPlanData?.plan as any;

  const { data: dailyNutrition, isLoading: dailyLoading } = trpc.nutrition.getDailyNutrition.useQuery(
    { trainingPlanId: nutritionPlanId, date: selectedDate },
    { enabled: hasPlan }
  );

  const { data: adherenceData, isLoading: adherenceLoading } = trpc.nutrition.getAdherence.useQuery(
    { trainingPlanId: nutritionPlanId, days: 7 },
    { enabled: hasPlan }
  );

  const logMeal = trpc.nutrition.logMeal.useMutation({
    onSuccess: () => {
      utils.nutrition.getDailyNutrition.invalidate();
      utils.nutrition.getAdherence.invalidate();
      utils.training.getUserProgress.invalidate();
      toast.success("Comida registrada +5 XP");
    },
    onError: (err) => toast.error("Error al registrar comida", { description: err.message }),
  });

  const generateMealImage = trpc.nutrition.generateMealImage.useMutation({
    onSuccess: (data, variables) => {
      if (data.success && data.url) {
        setMealImages(prev => ({ ...prev, [variables.mealNumber]: data.url as string }));
        toast.success("Imagen generada");
      } else {
        toast.error("No se pudo generar la imagen");
      }
    },
    onError: () => toast.error("Error al generar imagen"),
  });

  const generateFridgeRecipe = trpc.nutrition.generateFridgeRecipe.useMutation({
    onSuccess: (data) => {
      setFridgeLoading(false);
      if (data.success && data.recipe) {
        setFridgeRecipe(data.recipe);
      } else {
        toast.error("No se pudo generar la receta");
      }
    },
    onError: (err) => {
      setFridgeLoading(false);
      toast.error("Error al generar receta", { description: err.message });
    },
  });

  const handleGenerateFridgeRecipe = () => {
    if (!fridgeIngredients.trim()) return;
    setFridgeLoading(true);
    setFridgeRecipe(null);
    const macrosLeft = nutrition?.dailyMacros
      ? {
          calories: Math.max(0, (nutrition.dailyCalories || 0) - consumedMacros.calories),
          protein: Math.max(0, (nutrition.dailyMacros.protein || 0) - consumedMacros.protein),
          carbs: Math.max(0, (nutrition.dailyMacros.carbs || 0) - consumedMacros.carbs),
          fats: Math.max(0, (nutrition.dailyMacros.fats || 0) - consumedMacros.fats),
        }
      : undefined;
    generateFridgeRecipe.mutate({ ingredients: fridgeIngredients, macrosLeft });
  };

  useEffect(() => {
    const seen = localStorage.getItem("ferfit-nutrition-coach");
    if (!seen && hasPlan) {
      setShowCoachMarks(true);
    }
  }, [hasPlan]);

  const handleCloseCoachMarks = () => {
    localStorage.setItem("ferfit-nutrition-coach", "true");
    setShowCoachMarks(false);
  };

  const handlePlanCreated = () => {
    utils.nutrition.getActivePlan.invalidate();
  };

  const consumedMacros = useMemo(() => {
    if (!dailyNutrition?.logs || !nutrition?.meals) return { protein: 0, carbs: 0, fats: 0, calories: 0 };
    return nutrition.meals.reduce((acc: any, meal: any) => {
      const log = dailyNutrition.logs.find((l: any) => l.mealNumber === meal.mealNumber);
      if (log?.consumed) {
        acc.protein += meal.macros.protein;
        acc.carbs += meal.macros.carbs;
        acc.fats += meal.macros.fats;
        acc.calories += meal.calories;
      }
      return acc;
    }, { protein: 0, carbs: 0, fats: 0, calories: 0 });
  }, [dailyNutrition, nutrition]);

  const handleToggleMeal = (mealNumber: number, consumed: boolean) => {
    logMeal.mutate({ trainingPlanId: nutritionPlanId, date: selectedDate, mealNumber, consumed: !consumed });
  };

  const handleGenerateImage = (meal: Meal) => {
    // Si ya hay imagen local, no llamar a Forge
    const localImg = getLocalFoodImage(meal.foods || []);
    if (localImg) {
      setMealImages(prev => ({ ...prev, [meal.mealNumber]: localImg }));
      toast.success("Imagen local cargada");
      return;
    }
    setGeneratingImage(prev => ({ ...prev, [meal.mealNumber]: true }));
    generateMealImage.mutate(
      { mealNumber: meal.mealNumber, mealName: meal.name, foods: foodsToString(meal.foods || []) },
      {
        onSettled: () => setGeneratingImage(prev => ({ ...prev, [meal.mealNumber]: false })),
      }
    );
  };

  const getMealImage = (meal: Meal) => {
    // 1. Imagen local por alimento (prioridad máxima)
    const localImg = getLocalFoodImage(meal.foods || []);
    if (localImg) return localImg;
    // 2. Imagen generada con IA (Forge)
    if (mealImages[meal.mealNumber]) return mealImages[meal.mealNumber];
    // 3. Fallback Unsplash por tipo de comida
    return MEAL_IMAGES[getMealImageKey(meal.name)];
  };

  const isMealConsumed = (mealNumber: number) => {
    return dailyNutrition?.logs?.find((l: any) => l.mealNumber === mealNumber)?.consumed || false;
  };

  const weeklyMeals = useMemo(() => {
    if (!nutrition?.meals) return [];
    const days: { date: Date; meals: Meal[] }[] = [];
    const today = new Date();
    for (let i = 0; i < 7; i++) {
      const date = new Date(today);
      date.setDate(today.getDate() - today.getDay() + i);
      days.push({ date, meals: nutrition.meals });
    }
    return days;
  }, [nutrition]);

  const heatmapEndDate = new Date();
  const heatmapStartDate = new Date();
  heatmapStartDate.setDate(heatmapEndDate.getDate() - 27);

  const { data: historyLogs } = trpc.nutrition.getAdherence.useQuery(
    { trainingPlanId: nutritionPlanId, days: 28 },
    { enabled: hasPlan && activeTab === "history" }
  );

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between flex-wrap gap-4 text-left">
          <div>
            <h1 className="font-display text-4xl font-bold text-foreground">Nutrición</h1>
            <p className="text-muted-foreground mt-1">Tu plan de alimentación diario</p>
          </div>
          {!hasPlan && (
            <Button onClick={() => setWizardOpen(true)} className="bg-accent text-accent-foreground hover:bg-accent/90 gap-2">
              <Plus className="w-4 h-4" /> Crear plan
            </Button>
          )}
        </div>

        {isLoading && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {[...Array(3)].map((_, i) => <Skeleton key={i} className="h-96 rounded-2xl bg-muted/30" />)}
          </div>
        )}

        {!isLoading && !hasPlan && (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <div className="w-20 h-20 rounded-2xl bg-accent/10 border border-accent/20 flex items-center justify-center mb-6">
              <Apple className="w-10 h-10 text-accent" />
            </div>
            <h2 className="font-display text-2xl font-bold text-foreground mb-3">Sin plan nutricional</h2>
            <p className="text-muted-foreground max-w-md mb-6">
              Creá tu plan de entrenamiento y recibirás automáticamente un plan nutricional personalizado.
            </p>
            <Button onClick={() => setWizardOpen(true)} className="bg-accent text-accent-foreground hover:bg-accent/90 gap-2">
              <Zap className="w-4 h-4" /> Crear mi plan
            </Button>
          </div>
        )}

        {!isLoading && hasPlan && nutrition && (
          <Card className="p-5 glass-panel text-left">
            <div className="flex items-center justify-between flex-wrap gap-4">
              <div>
                <h3 className="font-semibold text-foreground flex items-center gap-2">
                  <ChefHat className="w-5 h-5 text-accent" /> Recetas con lo que tenés
                </h3>
                <p className="text-xs text-muted-foreground mt-1">
                  Escribí los ingredientes de tu heladera y Feo te arma una receta.
                </p>
              </div>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setFridgeOpen(prev => !prev)}
                className="border-border/50 gap-2"
              >
                <Sparkles className="w-4 h-4" /> {fridgeOpen ? "Cerrar" : "Generar receta"}
              </Button>
            </div>

            {fridgeOpen && (
              <div className="mt-4 space-y-4">
                <div className="flex gap-2">
                  <Textarea
                    placeholder="Ej: huevos, espinaca, queso, tomate..."
                    value={fridgeIngredients}
                    onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setFridgeIngredients(e.target.value)}
                    className="flex-1 min-h-[60px] bg-background/50"
                  />
                  <Button
                    onClick={handleGenerateFridgeRecipe}
                    disabled={fridgeLoading || !fridgeIngredients.trim()}
                    className="bg-accent text-accent-foreground hover:bg-accent/90 gap-2 self-end"
                  >
                    {fridgeLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Sparkles className="w-4 h-4" />}
                    Generar
                  </Button>
                </div>

                {fridgeRecipe && (
                  <div className="rounded-xl border border-border/20 bg-background/40 p-4 space-y-3">
                    <div className="flex items-center justify-between">
                      <h4 className="font-bold text-foreground">{fridgeRecipe.title}</h4>
                      <Badge variant="outline" className="text-xs">{fridgeRecipe.prepTime}</Badge>
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {fridgeRecipe.ingredients?.map((ing: string, i: number) => (
                        <span key={i} className="text-[10px] bg-accent/10 text-accent px-2 py-0.5 rounded-full">{ing}</span>
                      ))}
                    </div>
                    <ol className="text-xs text-muted-foreground space-y-1 list-decimal list-inside">
                      {fridgeRecipe.steps?.map((step: string, i: number) => (
                        <li key={i}>{step}</li>
                      ))}
                    </ol>
                    <div className="flex gap-4 text-xs">
                      <span className="text-purple-400">{fridgeRecipe.macros?.protein ?? 0}g proteína</span>
                      <span className="text-accent">{fridgeRecipe.macros?.carbs ?? 0}g carbs</span>
                      <span className="text-accent/70">{fridgeRecipe.macros?.fats ?? 0}g grasas</span>
                      <span className="text-foreground font-semibold">{fridgeRecipe.macros?.calories ?? 0} kcal</span>
                    </div>
                    {fridgeRecipe.tip && (
                      <p className="text-xs text-accent italic">💡 {fridgeRecipe.tip}</p>
                    )}
                  </div>
                )}
              </div>
            )}
          </Card>
        )}

        {!isLoading && hasPlan && nutrition && (
          <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
            <TabsList className="grid w-full grid-cols-4 bg-muted/30">
              <TabsTrigger value="today">Hoy</TabsTrigger>
              <TabsTrigger value="weekly">Plan semanal</TabsTrigger>
              <TabsTrigger value="history">Historial</TabsTrigger>
              <TabsTrigger value="settings">Ajustes</TabsTrigger>
            </TabsList>

            <TabsContent value="today" className="space-y-6">
              {/* Header de calorías */}
              <Card className="p-5 glass-panel flex items-center justify-between">
                <div className="text-left">
                  <p className="text-xs text-muted-foreground uppercase tracking-wider">Calorías hoy</p>
                  <p className="text-2xl font-bold text-foreground font-display">
                    {Math.round(consumedMacros.calories)} <span className="text-sm text-muted-foreground font-sans">/ {nutrition.dailyCalories} kcal</span>
                  </p>
                </div>
                <div className="w-32 h-2 bg-muted/30 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-accent transition-all"
                    style={{ width: `${Math.min((consumedMacros.calories / nutrition.dailyCalories) * 100, 100)}%` }}
                  />
                </div>
              </Card>

              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div className="lg:col-span-2 space-y-6 text-left">
                  <h3 className="text-xl font-bold text-foreground font-display uppercase tracking-wider">
                    Comidas de hoy
                  </h3>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    {nutrition.meals?.slice(0, 3).map((meal: Meal) => (
                      <MealCard
                        key={meal.mealNumber}
                        meal={meal}
                        consumed={isMealConsumed(meal.mealNumber)}
                        onToggle={() => handleToggleMeal(meal.mealNumber, isMealConsumed(meal.mealNumber))}
                        imageUrl={getMealImage(meal)}
                        onGenerateImage={() => handleGenerateImage(meal)}
                        generatingImage={generatingImage[meal.mealNumber] || false}
                      />
                    ))}
                  </div>
                  {nutrition.meals && nutrition.meals.length > 3 && (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {nutrition.meals.slice(3).map((meal: Meal) => (
                        <MealCard
                          key={meal.mealNumber}
                          meal={meal}
                          consumed={isMealConsumed(meal.mealNumber)}
                          onToggle={() => handleToggleMeal(meal.mealNumber, isMealConsumed(meal.mealNumber))}
                          imageUrl={getMealImage(meal)}
                          onGenerateImage={() => handleGenerateImage(meal)}
                          generatingImage={generatingImage[meal.mealNumber] || false}
                        />
                      ))}
                    </div>
                  )}
                </div>

                <div className="space-y-6 text-left">
                  <h3 className="text-xl font-bold text-foreground font-display uppercase tracking-wider">
                    Macronutrientes
                  </h3>
                  <Card className="p-6 glass-panel flex flex-col items-center justify-center min-h-[400px]">
                    <NutritionRings consumed={consumedMacros} target={nutrition.dailyMacros} />
                    <div className="w-full mt-4 text-center">
                      <p className="text-2xl font-bold text-accent font-display">{nutrition.dailyCalories} kcal</p>
                      <p className="text-xs text-muted-foreground mt-0.5">Calorías Totales Diarias</p>
                    </div>
                  </Card>
                  {!adherenceLoading && adherenceData && (
                    <AdherenceCard
                      percentage={adherenceData.percentage}
                      consumed={adherenceData.consumed}
                      total={adherenceData.total}
                    />
                  )}
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-left">
                <Card className="p-5 glass-panel">
                  <h3 className="font-semibold text-foreground mb-3 flex items-center gap-2">
                    <Droplets className="w-5 h-5 text-accent" /> Hidratación recomendada
                  </h3>
                  <p className="text-sm text-muted-foreground leading-relaxed">{nutrition.hydration}</p>
                </Card>
                {nutrition.supplementation && (
                  <Card className="p-5 glass-panel">
                    <h3 className="font-semibold text-foreground mb-3 flex items-center gap-2">
                      <Pill className="w-5 h-5 text-purple-400" /> Suplementación
                    </h3>
                    <p className="text-sm text-muted-foreground leading-relaxed">{nutrition.supplementation}</p>
                  </Card>
                )}
              </div>

              {nutrition.notes && (
                <Card className="p-5 glass-panel text-left">
                  <h3 className="font-semibold text-foreground mb-2">Notas del Plan Nutricional</h3>
                  <p className="text-sm text-muted-foreground leading-relaxed">{nutrition.notes}</p>
                </Card>
              )}
            </TabsContent>

            <TabsContent value="weekly" className="space-y-6">
              <h3 className="text-xl font-bold text-foreground font-display uppercase tracking-wider text-left">
                Plan semanal
              </h3>
              <div className="grid grid-cols-1 md:grid-cols-7 gap-3">
                {weeklyMeals.map((day, idx) => (
                  <Card key={idx} className="p-3 glass-panel text-left">
                    <p className="text-xs font-bold text-accent uppercase tracking-wider mb-2">{DAYS_ES[day.date.getDay()]}</p>
                    <p className="text-[10px] text-muted-foreground mb-2">{day.date.toLocaleDateString("es-AR", { day: "numeric", month: "short" })}</p>
                    <div className="space-y-1.5">
                      {day.meals.slice(0, 3).map((meal) => (
                        <div key={meal.mealNumber} className="text-[10px] text-muted-foreground truncate">
                          {meal.time} — {meal.name}
                        </div>
                      ))}
                    </div>
                    <div className="mt-3 pt-2 border-t border-border/10">
                      <p className="text-[10px] text-muted-foreground uppercase">Total</p>
                      <p className="text-sm font-bold text-foreground">{nutrition.dailyCalories} kcal</p>
                    </div>
                  </Card>
                ))}
              </div>
            </TabsContent>

            <TabsContent value="history" className="space-y-6">
              <h3 className="text-xl font-bold text-foreground font-display uppercase tracking-wider text-left">
                Historial de adherencia
              </h3>
              <Card className="p-6 glass-panel">
                <p className="text-sm text-muted-foreground mb-4 text-left">Últimos 28 días</p>
                {historyLogs && (
                  <Heatmap logs={historyLogs as any} startDate={heatmapStartDate} endDate={heatmapEndDate} />
                )}
                <div className="flex gap-4 text-xs text-muted-foreground mt-4">
                  <div className="flex items-center gap-2"><div className="w-3 h-3 rounded bg-accent/20" /> Baja</div>
                  <div className="flex items-center gap-2"><div className="w-3 h-3 rounded bg-accent/60" /> Media</div>
                  <div className="flex items-center gap-2"><div className="w-3 h-3 rounded bg-accent" /> Alta</div>
                </div>
              </Card>
            </TabsContent>

            <TabsContent value="settings" className="space-y-6">
              <h3 className="text-xl font-bold text-foreground font-display uppercase tracking-wider text-left">
                Ajustes del plan
              </h3>
              <Card className="p-6 glass-panel text-left">
                <p className="text-sm text-muted-foreground mb-4">
                  Próximamente podrás editar restricciones alimentarias, comidas favoritas y alimentos que no te gustan.
                </p>
                <Button onClick={() => setWizardOpen(true)} variant="outline" className="border-border/50 gap-2">
                  <Plus className="w-4 h-4" /> Crear nuevo plan
                </Button>
              </Card>
            </TabsContent>
          </Tabs>
        )}
      </div>

      {showCoachMarks && <CoachMarks onClose={handleCloseCoachMarks} />}
      {wizardOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 overflow-y-auto">
          <div className="w-full max-w-3xl">
            <NutritionPlanSelector onPlanCreated={() => { handlePlanCreated(); setWizardOpen(false); }} />
          </div>
        </div>
      )}
    </DashboardLayout>
  );
}
