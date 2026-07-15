import { useState, useRef } from "react";
import { trpc } from "@/lib/trpc";
import { useUser } from "@clerk/clerk-react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Skeleton } from "@/components/ui/skeleton";
import DashboardLayout from "@/components/DashboardLayout";
import { TrainingPlanSelector } from "@/components/TrainingPlanSelector";
import { EngagementBanner } from "@/components/EngagementBanner";
import {
  Zap, Flame, Trophy, TrendingUp, Dumbbell, Calendar, Plus, CheckCircle2,
  Circle, ChevronRight, Star, ChevronLeft, Droplets, Moon, Apple,
  Heart, Activity, Target, Shield, User
} from "lucide-react";
import { useLocation } from "wouter";
import { toast } from "sonner";
import { getLevelProgress } from "@/lib/levels";
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";

function Sparkline({ points, color }: { points: number[]; color: string }) {
  const width = 80;
  const height = 24;
  const max = Math.max(...points);
  const min = Math.min(...points);
  const range = max - min || 1;
  const pathData = points
    .map((p, i) => {
      const x = (i / (points.length - 1)) * width;
      const y = height - ((p - min) / range) * height;
      return `${i === 0 ? "M" : "L"} ${x} ${y}`;
    })
    .join(" ");

  return (
    <svg width={width} height={height} className="overflow-visible">
      <path d={pathData} fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

const DAYS_ES = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"];
const DAYS_FULL = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"];

const ICON_MAP: Record<string, React.ElementType> = {
  droplets: Droplets, moon: Moon, zap: Zap, flame: Flame, apple: Apple,
  heart: Heart, activity: Activity, trophy: Trophy, target: Target,
  dumbbell: Dumbbell, star: Star, shield: Shield, user: User,
};

export default function Dashboard() {
  const { user } = useUser();
  const [, navigate] = useLocation();
  const [wizardOpen, setWizardOpen] = useState(false);
  const utils = trpc.useUtils();

  const { data: planData, isLoading: planLoading } = trpc.training.getActivePlan.useQuery();
  const { data: progress, isLoading: progressLoading } = trpc.training.getUserProgress.useQuery();
  const { data: checklist } = trpc.training.getTodayChecklist.useQuery();
  const { data: dashData, isLoading: dashLoading } = trpc.training.getDashboardData.useQuery();
  const { data: tipsData, isLoading: tipsLoading } = trpc.training.getAITips.useQuery();
  const generateDemo = trpc.training.generateDemoRoutine.useMutation();

  const hasPlan = planData && (planData as any).hasPlan;
  const xpToNextLevel = ((progress?.level || 1) * 500);
  const xpProgress = progress ? ((progress.totalXP % 500) / 500) * 100 : 0;
  const todayIndex = new Date().getDay();

  const handlePlanCreated = () => {
    setWizardOpen(false);
    utils.training.getActivePlan.invalidate();
    toast.success("¡Plan creado exitosamente!");
  };

  const handleGenerateDemo = async () => {
    try {
      await generateDemo.mutateAsync();
      toast.success("¡Rutina de demo generada!");
      handlePlanCreated();
    } catch {
      toast.error("Error al generar la rutina de demo");
    }
  };

  const planWithContent = planData as any;
  const generatedPlan = hasPlan && planWithContent?.generatedContent
    ? (typeof planWithContent.generatedContent === "string"
      ? JSON.parse(planWithContent.generatedContent)
      : planWithContent.generatedContent)
    : null;

  // Today's exercises logic: show real checklist or empty state
  const todayWorkouts = checklist && (checklist as any).totalSeries > 0
    ? [
        { name: "Rutina del Día", progress: Math.round(((checklist as any).completedSeries / (checklist as any).totalSeries) * 100), completed: (checklist as any).isCompleted === 1, time: `${(checklist as any).completedSeries}/${(checklist as any).totalSeries} series` }
      ]
    : [];

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Welcome */}
        <div className="flex items-center justify-between flex-wrap gap-4">
          <div>
            <h1 className="font-display text-3xl font-bold text-foreground text-left">
              Hola, <span className="text-accent">{user?.firstName || user?.username || "Atleta"}</span> 👋
            </h1>
            <p className="text-muted-foreground mt-1 text-left">
              {DAYS_FULL[todayIndex]}, {new Date().toLocaleDateString("es-AR", { day: "numeric", month: "long" })}
            </p>
          </div>
          {!hasPlan && (
            <Button onClick={() => setWizardOpen(true)} className="bg-accent text-accent-foreground hover:bg-accent/90 gap-2">
              <Plus className="w-4 h-4" /> Crear mi rutina
            </Button>
          )}
        </div>

        <EngagementBanner onCreatePlan={() => setWizardOpen(true)} />

        {/* Dashboard Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          
          {/* Columna Izquierda (2/3 de ancho) */}
          <div className="lg:col-span-2 space-y-6">
            
            {/* WEEKLY PROGRESS */}
            <Card className="p-6 glass-panel relative overflow-hidden text-left">
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h3 className="text-lg font-bold text-foreground font-display uppercase tracking-wider">
                    Weekly Progress
                  </h3>
                  <p className="text-xs text-muted-foreground mt-0.5">Entrenamientos completados esta semana</p>
                </div>
                <div className="flex items-center gap-4 text-xs text-muted-foreground">
                  <div className="flex items-center gap-1.5">
                    <div className="w-2.5 h-2.5 rounded-full bg-accent" />
                    <span>Entrenamientos</span>
                  </div>
                </div>
              </div>

              <div className="h-72 w-full mt-4 transition-transform duration-300 hover:scale-[1.02]">
                {!dashData || dashData.weeklyChart.length === 0 ? (
                  <div className="h-full flex flex-col items-center justify-center text-sm text-muted-foreground gap-4">
                    <div className="w-16 h-16 rounded-full bg-accent/10 flex items-center justify-center animate-pulse">
                      <TrendingUp className="w-8 h-8 text-accent opacity-50" />
                    </div>
                    Aún no hay entrenamientos registrados esta semana
                  </div>
                ) : (
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={dashData.weeklyChart} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                      <defs>
                        <linearGradient id="colorWorkouts" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="oklch(0.72 0.2 145)" stopOpacity={0.4} />
                          <stop offset="95%" stopColor="oklch(0.72 0.2 145)" stopOpacity={0.0} />
                        </linearGradient>
                      </defs>
                      <XAxis dataKey="day" stroke="rgba(255,255,255,0.4)" fontSize={11} tickLine={false} axisLine={false} />
                      <YAxis stroke="rgba(255,255,255,0.4)" fontSize={11} tickLine={false} axisLine={false} allowDecimals={false} />
                      <Tooltip
                        contentStyle={{ backgroundColor: "rgba(15,15,20,0.95)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "12px" }}
                        labelStyle={{ fontWeight: "bold", color: "#fff" }}
                      />
                      <Area 
                        type="monotone" 
                        dataKey="count" 
                        stroke="oklch(0.72 0.2 145)" 
                        strokeWidth={3} 
                        fillOpacity={1} 
                        fill="url(#colorWorkouts)" 
                        isAnimationActive={true}
                        animationDuration={1500}
                        activeDot={{ r: 8, strokeWidth: 2, fill: "oklch(0.72 0.2 145)" }}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                )}
              </div>
            </Card>

            {/* DAILY WORKOUT CHECKLIST */}
            <Card className="p-6 glass-panel text-left">
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h3 className="text-lg font-bold text-foreground font-display uppercase tracking-wider">
                    Daily Workout Checklist
                  </h3>
                  <p className="text-xs text-muted-foreground mt-0.5">Tus metas de entrenamiento para hoy</p>
                </div>
                <Badge variant="outline" className="border-accent/30 text-accent font-semibold">
                  Hoy
                </Badge>
              </div>

              <div className="space-y-4">
                {todayWorkouts.length > 0 ? (
                  todayWorkouts.map((w, idx) => (
                    <div
                      key={idx}
                      className="flex items-center justify-between p-4 rounded-xl border border-border/10 bg-background/30 backdrop-blur-sm transition-all hover:border-accent/30 hover:bg-background/40"
                    >
                      <div className="flex items-center gap-4 flex-1">
                        <div className="w-6 h-6 rounded border border-accent/40 flex items-center justify-center bg-accent/5 text-accent">
                          {w.completed ? (
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="3" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                            </svg>
                          ) : null}
                        </div>
                        <div className="flex-1 text-left">
                          <p className={`text-sm font-semibold text-foreground ${w.completed ? "line-through opacity-50" : ""}`}>
                            {w.name}
                          </p>
                          {/* Progress Bar under name */}
                          <div className="w-full max-w-sm h-1.5 bg-muted/25 rounded-full mt-2 overflow-hidden">
                            <div
                              className="h-full bg-accent transition-all duration-500"
                              style={{ width: `${w.completed ? 100 : w.progress}%` }}
                            />
                          </div>
                        </div>
                      </div>
                      {w.time && (
                        <span className="text-xs text-muted-foreground bg-muted/30 px-2.5 py-1 rounded-full font-medium">
                          {w.time}
                        </span>
                      )}
                    </div>
                  ))
                ) : (
                  <div className="text-center py-8 text-muted-foreground">
                    <p className="text-sm">No hay entrenamiento programado para hoy.</p>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => navigate("/entrenamiento")}
                      className="mt-3 border-border/50 gap-2"
                    >
                      <Dumbbell className="w-4 h-4" /> Ir a entrenamiento
                    </Button>
                  </div>
                )}
              </div>
            </Card>

          </div>

          {/* Columna Derecha (1/3 de ancho) */}
          <div className="space-y-6">
            
            {/* XP PROGRESS CARD */}
            <Card className="p-6 glass-panel relative overflow-hidden bg-gradient-to-br from-accent/10 to-accent/5 text-left">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h3 className="text-sm font-bold text-muted-foreground uppercase tracking-wider">Level Progress</h3>
                  <p className="text-2xl font-bold text-foreground font-display mt-1">XP: {progress?.totalXP?.toLocaleString() || "0"}</p>
                </div>
                <div className="w-12 h-12 rounded-xl bg-accent/20 border border-accent/30 flex items-center justify-center shadow-[0_0_15px_oklch(0.72_0.2_145/0.15)]">
                  <Star className="w-6 h-6 text-accent" />
                </div>
              </div>
              
              <div className="space-y-2">
                <div className="flex justify-between text-xs text-muted-foreground">
                  <span>Nivel {progress?.level || 1}</span>
                  <span>{progress ? (progress.totalXP % 500) : 0} / 500 XP</span>
                </div>
                <Progress value={xpProgress} className="h-2.5" />
                <p className="text-[11px] text-muted-foreground text-left italic mt-1.5">
                  {progress ? (500 - (progress.totalXP % 500)) : 500} XP para alcanzar el nivel {(progress?.level || 1) + 1}
                </p>
              </div>
            </Card>

            {/* DAILY GOAL PROGRESS: real stats from dashboard data */}
            <div className="grid grid-cols-2 gap-4">
              <Card className="p-4 glass-panel text-left">
                <p className="text-xs font-bold text-muted-foreground uppercase tracking-wider">Entrenamientos</p>
                <p className="text-xl font-bold text-accent font-display mt-2">{dashData?.fitnessStats?.totalWorkouts ?? 0}</p>
                <p className="text-[10px] text-muted-foreground mt-1">Completados en total</p>
              </Card>
              <Card className="p-4 glass-panel text-left">
                <p className="text-xs font-bold text-muted-foreground uppercase tracking-wider">Series esta semana</p>
                <p className="text-xl font-bold text-purple-400 font-display mt-2">{dashData?.fitnessStats?.weeklyTotalSeries ?? 0}</p>
                <p className="text-[10px] text-muted-foreground mt-1">+{dashData?.fitnessStats?.weeklyTotalXP ?? 0} XP</p>
              </Card>
            </div>

            {/* FITNESS STATS OVERVIEW */}
            <Card className="p-6 glass-panel text-left">
              <h3 className="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-6">
                Fitness Stats Overview
              </h3>

              <div className="space-y-5">
                {/* Streak */}
                <div className="flex items-center justify-between">
                  <div className="text-left">
                    <p className="text-xs text-muted-foreground">Racha actual</p>
                    <p className="text-lg font-bold text-foreground font-display mt-0.5">
                      {progress?.streak ?? 0} <span className="text-xs text-accent font-sans">días</span>
                    </p>
                  </div>
                  <Sparkline points={[0, progress?.streak ?? 0, progress?.streak ?? 0, progress?.streak ?? 0, progress?.streak ?? 0, progress?.streak ?? 0, progress?.streak ?? 0]} color="oklch(0.72 0.2 145)" />
                </div>

                {/* Level */}
                <div className="flex items-center justify-between">
                  <div className="text-left">
                    <p className="text-xs text-muted-foreground">Nivel</p>
                    <p className="text-lg font-bold text-foreground font-display mt-0.5">
                      {progress?.level ?? 1} <span className="text-xs text-purple-400 font-sans">/ {xpToNextLevel} XP</span>
                    </p>
                  </div>
                  <Sparkline points={[1, progress?.level ?? 1, progress?.level ?? 1, progress?.level ?? 1, progress?.level ?? 1, progress?.level ?? 1, progress?.level ?? 1]} color="oklch(0.6 0.2 300)" />
                </div>

                {/* Weekly workouts */}
                <div className="flex items-center justify-between">
                  <div className="text-left">
                    <p className="text-xs text-muted-foreground">Entrenos esta semana</p>
                    <p className="text-lg font-bold text-foreground font-display mt-0.5">
                      {dashData?.weeklyChart?.reduce((acc: number, d: any) => acc + (d.count || 0), 0) ?? 0} <span className="text-xs text-accent font-sans">/ {planData?.daysPerWeek ?? 0}</span>
                    </p>
                  </div>
                  <Sparkline points={dashData?.weeklyChart?.map((d: any) => d.count || 0) ?? [0, 0, 0, 0, 0, 0, 0]} color="oklch(0.72 0.2 145)" />
                </div>
              </div>
            </Card>

          </div>

        </div>

        {/* AI Tips */}
        <AiTipsCard tips={tipsData?.tips} isLoading={tipsLoading} />
      </div>

      <TrainingPlanSelector isOpen={wizardOpen} onClose={() => setWizardOpen(false)} onPlanCreated={handlePlanCreated} />
    </DashboardLayout>
  );
}

/* ────────────── Sub-components ────────────── */

const DEFAULT_ACTIVITY = [
  { icon: "star", title: "¡Bienvenido a FerFit!", description: "Comenzá tu viaje fitness", time: "Hoy" },
  { icon: "user", title: "Perfil creado", description: "Configuración inicial completada", time: "Hoy" },
  { icon: "target", title: "Objetivo establecido", description: "Definí tu objetivo principal", time: "Hoy" },
];

function StatCard({ icon: Icon, label, value, sub, color, bg }: {
  icon: any; label: string; value: string; sub: string; color: string; bg: string;
}) {
  return (
    <Card className="p-4 glass-panel glass-panel-hover">
      <div className={`w-10 h-10 rounded-xl ${bg} flex items-center justify-center mb-3`}>
        <Icon className={`w-5 h-5 ${color}`} />
      </div>
      <p className="text-xs text-muted-foreground">{label}</p>
      <p className={`text-2xl font-bold font-display mt-1 ${color}`}>{value}</p>
      <p className="text-xs text-muted-foreground mt-0.5">{sub}</p>
    </Card>
  );
}

function WeeklyCalendar({ plan, todayIndex }: { plan: any; todayIndex: number }) {
  const daysPerWeek = plan.daysPerWeek || 3;
  const trainingDayIndices: number[] = [];
  for (let i = 0; i < daysPerWeek; i++) {
    trainingDayIndices.push((1 + i) % 7);
  }

  return (
    <div className="grid grid-cols-7 gap-1 md:gap-2">
      {DAYS_ES.map((day, idx) => {
        const isTraining = trainingDayIndices.includes(idx);
        const isToday = idx === todayIndex;
        return (
          <div key={idx} className={`rounded-xl p-1 md:p-2 text-center transition-all ${
            isToday ? "border-2 border-accent bg-accent/10" :
            isTraining ? "border border-accent/30 bg-accent/5" :
            "border border-border/20 bg-muted/10"
          }`}>
            <p className={`text-[10px] md:text-xs font-semibold ${isToday ? "text-accent" : "text-muted-foreground"}`}>{day}</p>
            <div className={`w-5 h-5 md:w-6 md:h-6 rounded-full mx-auto mt-1 flex items-center justify-center ${
              isTraining ? "bg-accent/20" : "bg-transparent"
            }`}>
              {isTraining ? (
                <Dumbbell className={`w-2.5 h-2.5 md:w-3 h-3 ${isToday ? "text-accent" : "text-accent/60"}`} />
              ) : (
                <Circle className="w-2.5 h-2.5 md:w-3 h-3 text-border/40" />
              )}
            </div>
            {isToday && <div className="w-1 h-1 md:w-1.5 md:h-1.5 rounded-full bg-accent mx-auto mt-1" />}
          </div>
        );
      })}
    </div>
  );
}

const TIP_COLORS = [
  { bg: "bg-accent/10", border: "border-accent/20", icon: "text-accent" },
  { bg: "bg-purple-500/10", border: "border-purple-500/20", icon: "text-purple-400" },
  { bg: "bg-accent/10", border: "border-accent/20", icon: "text-accent" },
];

function AiTipsCard({ tips, isLoading }: { tips?: any[]; isLoading: boolean }) {
  const [current, setCurrent] = useState(0);
  const displayTips = tips || [];

  return (
    <Card className="p-5 glass-panel">
      <div className="flex items-center justify-between mb-5">
        <h3 className="font-semibold text-foreground flex items-center gap-2">
          <div className="w-6 h-6 rounded-full bg-yellow-400/20 flex items-center justify-center">
            <span className="text-sm">💡</span>
          </div>
          Consejos para vos
        </h3>
        {!isLoading && displayTips.length > 0 && (
          <div className="flex items-center gap-1">
            <button
              onClick={() => setCurrent(c => Math.max(0, c - 1))}
              disabled={current === 0}
              className="w-7 h-7 rounded-full border border-border/50 flex items-center justify-center hover:bg-muted/40 disabled:opacity-30 transition-all"
            >
              <ChevronLeft className="w-3.5 h-3.5" />
            </button>
            <button
              onClick={() => setCurrent(c => Math.min(displayTips.length - 1, c + 1))}
              disabled={current === displayTips.length - 1}
              className="w-7 h-7 rounded-full border border-border/50 flex items-center justify-center hover:bg-muted/40 disabled:opacity-30 transition-all"
            >
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>
        )}
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {[...Array(3)].map((_, i) => <Skeleton key={i} className="h-28 rounded-xl bg-muted/30" />)}
        </div>
      ) : displayTips.length > 0 ? (
        <>
          {/* Mobile: carousel */}
          <div className="md:hidden">
            <TipCard tip={displayTips[current]} colorSet={TIP_COLORS[current % TIP_COLORS.length]} />
            <div className="flex justify-center gap-1.5 mt-3">
              {displayTips.map((_, i) => (
                <button
                  key={i}
                  onClick={() => setCurrent(i)}
                  className={`h-1.5 rounded-full transition-all ${i === current ? "w-5 bg-accent" : "w-1.5 bg-muted/50"}`}
                />
              ))}
            </div>
          </div>
          {/* Desktop: all 3 side by side */}
          <div className="hidden md:grid grid-cols-3 gap-4">
            {displayTips.map((tip: any, i: number) => (
              <TipCard key={i} tip={tip} colorSet={TIP_COLORS[i % TIP_COLORS.length]} />
            ))}
          </div>
        </>
      ) : (
        <p className="text-sm text-muted-foreground text-center py-4">Cargando consejos personalizados...</p>
      )}

      <p className="text-xs text-muted-foreground/50 text-center mt-4 flex items-center justify-center gap-1">
        <Zap className="w-3 h-3" /> Generado por IA según tu actividad
      </p>
    </Card>
  );
}

function TipCard({ tip, colorSet }: { tip: any; colorSet: { bg: string; border: string; icon: string } }) {
  const Icon = ICON_MAP[tip.icon] || Zap;
  return (
    <div className={`rounded-xl p-4 glass-panel glass-panel-hover transition-all hover:scale-[1.02] duration-200`}>
      <div className={`w-9 h-9 rounded-xl ${colorSet.bg} border ${colorSet.border} flex items-center justify-center mb-3`}>
        <Icon className={`w-4.5 h-4.5 ${colorSet.icon}`} />
      </div>
      <p className="text-sm font-semibold text-foreground mb-1">{tip.title}</p>
      <p className="text-xs text-muted-foreground leading-relaxed">{tip.description}</p>
    </div>
  );
}
