import { useState } from "react";
import { trpc } from "@/lib/trpc";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { Apple, ArrowRight, ArrowLeft, Utensils, Target, Flame, Clock, Wallet, AlertCircle, Check } from "lucide-react";

const OBJECTIVES = [
  { id: "fat_loss", label: "Perder grasa", icon: Flame, desc: "Déficit calórico moderado" },
  { id: "muscle_gain", label: "Ganar músculo", icon: Target, desc: "Superávit calórico controlado" },
  { id: "maintenance", label: "Mantenimiento", icon: Apple, desc: "Mantener peso actual" },
  { id: "general_health", label: "Salud general", icon: Check, desc: "Hábitos alimentarios saludables" },
];

const FREQUENCIES = [
  { value: 3, label: "3 comidas" },
  { value: 4, label: "4 comidas" },
  { value: 5, label: "5 comidas" },
  { value: 6, label: "6 comidas" },
];

const RESTRICTIONS = [
  { id: "vegan", label: "Vegano" },
  { id: "vegetarian", label: "Vegetariano" },
  { id: "gluten_free", label: "Sin gluten" },
  { id: "dairy_free", label: "Sin lactosa" },
  { id: "nut_free", label: "Sin frutos secos" },
  { id: "seafood_free", label: "Sin pescado" },
];

const PREP_TIMES = [
  { value: "<15min", label: "< 15 min" },
  { value: "15-30min", label: "15-30 min" },
  { value: "30-60min", label: "30-60 min" },
  { value: ">60min", label: "> 60 min" },
];

const BUDGETS = [
  { value: "budget", label: "Económico" },
  { value: "medium", label: "Medio" },
  { value: "premium", label: "Premium" },
];

const ACTIVITY_LEVELS = [
  { value: "sedentary", label: "Sedentario" },
  { value: "light", label: "Ligero" },
  { value: "moderate", label: "Moderado" },
  { value: "active", label: "Activo" },
  { value: "very_active", label: "Muy activo" },
];

export function NutritionPlanSelector({ onPlanCreated }: { onPlanCreated: () => void }) {
  const [step, setStep] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [form, setForm] = useState({
    age: 30,
    weight: 70,
    height: 170,
    gender: "male" as "male" | "female",
    activityLevel: "moderate" as any,
    objective: "maintenance" as any,
    mealFrequency: 4 as 3 | 4 | 5 | 6,
    dietaryRestrictions: [] as string[],
    foodPreferences: [] as string[],
    foodDislikes: [] as string[],
    prepTime: "15-30min" as any,
    budget: "medium" as any,
  });

  const createPlan = trpc.nutrition.createPlan.useMutation({
    onSuccess: (data) => {
      setIsSubmitting(false);
      if (data.success) {
        toast.success("Plan nutricional generado");
        onPlanCreated();
      } else {
        toast.error("No se pudo generar el plan", { description: data.error });
      }
    },
    onError: (err) => {
      setIsSubmitting(false);
      toast.error("Error al generar plan", { description: err.message });
    },
  });

  const steps = [
    { title: "Perfil", description: "Datos básicos" },
    { title: "Objetivo", description: "Qué querés lograr" },
    { title: "Comidas", description: "Frecuencia y restricciones" },
    { title: "Preferencias", description: "Gustos y disgustos" },
    { title: "Estilo de vida", description: "Tiempo y presupuesto" },
  ];

  function toggleRestriction(id: string) {
    setForm(prev => ({
      ...prev,
      dietaryRestrictions: prev.dietaryRestrictions.includes(id)
        ? prev.dietaryRestrictions.filter(r => r !== id)
        : [...prev.dietaryRestrictions, id],
    }));
  }

  function addPreference(tag: string) {
    const clean = tag.trim().toLowerCase();
    if (!clean) return;
    setForm(prev => ({
      ...prev,
      foodPreferences: prev.foodPreferences.includes(clean) ? prev.foodPreferences : [...prev.foodPreferences, clean],
    }));
  }

  function addDislike(tag: string) {
    const clean = tag.trim().toLowerCase();
    if (!clean) return;
    setForm(prev => ({
      ...prev,
      foodDislikes: prev.foodDislikes.includes(clean) ? prev.foodDislikes : [...prev.foodDislikes, clean],
    }));
  }

  function handleSubmit() {
    setIsSubmitting(true);
    createPlan.mutate(form);
  }

  function renderStep() {
    switch (step) {
      case 0:
        return (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Edad</Label>
                <Input type="number" value={form.age} onChange={e => setForm({ ...form, age: Number(e.target.value) })} />
              </div>
              <div>
                <Label>Género</Label>
                <div className="flex gap-2 mt-1.5">
                  <Button type="button" variant={form.gender === "male" ? "default" : "outline"} onClick={() => setForm({ ...form, gender: "male" })} className="flex-1">Hombre</Button>
                  <Button type="button" variant={form.gender === "female" ? "default" : "outline"} onClick={() => setForm({ ...form, gender: "female" })} className="flex-1">Mujer</Button>
                </div>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Peso (kg)</Label>
                <Input type="number" value={form.weight} onChange={e => setForm({ ...form, weight: Number(e.target.value) })} />
              </div>
              <div>
                <Label>Altura (cm)</Label>
                <Input type="number" value={form.height} onChange={e => setForm({ ...form, height: Number(e.target.value) })} />
              </div>
            </div>
            <div>
              <Label>Nivel de actividad</Label>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 mt-1.5">
                {ACTIVITY_LEVELS.map(level => (
                  <Button key={level.value} type="button" variant={form.activityLevel === level.value ? "default" : "outline"} onClick={() => setForm({ ...form, activityLevel: level.value })} className="text-xs">
                    {level.label}
                  </Button>
                ))}
              </div>
            </div>
          </div>
        );
      case 1:
        return (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {OBJECTIVES.map(obj => (
              <Card
                key={obj.id}
                onClick={() => setForm({ ...form, objective: obj.id })}
                className={`p-4 cursor-pointer transition-all ${form.objective === obj.id ? "border-accent bg-accent/10" : "hover:bg-muted/30"}`}
              >
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-accent/10">
                    <obj.icon className="w-5 h-5 text-accent" />
                  </div>
                  <div>
                    <p className="font-semibold text-foreground">{obj.label}</p>
                    <p className="text-xs text-muted-foreground">{obj.desc}</p>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        );
      case 2:
        return (
          <div className="space-y-6">
            <div>
              <Label>Comidas por día</Label>
              <div className="grid grid-cols-4 gap-2 mt-1.5">
                {FREQUENCIES.map(freq => (
                  <Button key={freq.value} type="button" variant={form.mealFrequency === freq.value ? "default" : "outline"} onClick={() => setForm({ ...form, mealFrequency: freq.value as any })}>
                    {freq.label}
                  </Button>
                ))}
              </div>
            </div>
            <div>
              <Label>Restricciones alimentarias</Label>
              <div className="flex flex-wrap gap-2 mt-1.5">
                {RESTRICTIONS.map(r => (
                  <Badge
                    key={r.id}
                    variant={form.dietaryRestrictions.includes(r.id) ? "default" : "outline"}
                    className="cursor-pointer px-3 py-1.5 text-sm"
                    onClick={() => toggleRestriction(r.id)}
                  >
                    {r.label}
                  </Badge>
                ))}
              </div>
            </div>
          </div>
        );
      case 3:
        return (
          <div className="space-y-6">
            <div>
              <Label>Alimentos que te gustan</Label>
              <div className="flex gap-2 mt-1.5">
                <Input id="pref-input" placeholder="Ej: pollo, arroz, palta" onKeyDown={e => {
                  if (e.key === "Enter") {
                    addPreference((e.target as HTMLInputElement).value);
                    (e.target as HTMLInputElement).value = "";
                  }
                }} />
              </div>
              <div className="flex flex-wrap gap-2 mt-2">
                {form.foodPreferences.map(p => (
                  <Badge key={p} variant="secondary" className="px-2 py-1">{p}</Badge>
                ))}
              </div>
            </div>
            <div>
              <Label>Alimentos que NO te gustan</Label>
              <div className="flex gap-2 mt-1.5">
                <Input id="dislike-input" placeholder="Ej: brócoli, pescado" onKeyDown={e => {
                  if (e.key === "Enter") {
                    addDislike((e.target as HTMLInputElement).value);
                    (e.target as HTMLInputElement).value = "";
                  }
                }} />
              </div>
              <div className="flex flex-wrap gap-2 mt-2">
                {form.foodDislikes.map(d => (
                  <Badge key={d} variant="destructive" className="px-2 py-1">{d}</Badge>
                ))}
              </div>
            </div>
          </div>
        );
      case 4:
        return (
          <div className="space-y-6">
            <div>
              <Label className="flex items-center gap-2"><Clock className="w-4 h-4" /> Tiempo para cocinar</Label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 mt-1.5">
                {PREP_TIMES.map(pt => (
                  <Button key={pt.value} type="button" variant={form.prepTime === pt.value ? "default" : "outline"} onClick={() => setForm({ ...form, prepTime: pt.value })}>
                    {pt.label}
                  </Button>
                ))}
              </div>
            </div>
            <div>
              <Label className="flex items-center gap-2"><Wallet className="w-4 h-4" /> Presupuesto</Label>
              <div className="grid grid-cols-3 gap-2 mt-1.5">
                {BUDGETS.map(b => (
                  <Button key={b.value} type="button" variant={form.budget === b.value ? "default" : "outline"} onClick={() => setForm({ ...form, budget: b.value })}>
                    {b.label}
                  </Button>
                ))}
              </div>
            </div>
            <div className="bg-muted/30 p-3 rounded-lg flex gap-2 text-xs text-muted-foreground">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <p>El plan se genera con un algoritmo basado en datos nutricionales reales. No requiere IA.</p>
            </div>
          </div>
        );
      default:
        return null;
    }
  }

  return (
    <Card className="p-6 glass-panel max-w-2xl mx-auto">
      <div className="flex items-center gap-3 mb-6">
        <div className="p-3 rounded-full bg-accent/20">
          <Utensils className="w-6 h-6 text-accent" />
        </div>
        <div>
          <h2 className="text-xl font-bold text-foreground font-display">Crear plan nutricional</h2>
          <p className="text-sm text-muted-foreground">Paso {step + 1} de {steps.length}: {steps[step].title}</p>
        </div>
      </div>

      <div className="flex gap-1 mb-6">
        {steps.map((s, i) => (
          <div key={i} className={`h-1.5 flex-1 rounded-full ${i <= step ? "bg-accent" : "bg-muted/30"}`} />
        ))}
      </div>

      {renderStep()}

      <div className="flex justify-between mt-8">
        <Button variant="outline" onClick={() => setStep(Math.max(0, step - 1))} disabled={step === 0}>
          <ArrowLeft className="w-4 h-4 mr-2" /> Atrás
        </Button>
        {step < steps.length - 1 ? (
          <Button onClick={() => setStep(step + 1)}>
            Siguiente <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        ) : (
          <Button onClick={handleSubmit} disabled={isSubmitting} className="bg-accent text-accent-foreground hover:bg-accent/90">
            {isSubmitting ? "Generando..." : "Generar plan"}
          </Button>
        )}
      </div>
    </Card>
  );
}
