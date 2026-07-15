import { trpc } from "@/lib/trpc";
import { useState } from "react";
import DashboardLayout from "@/components/DashboardLayout";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Zap, Flame, Trophy, TrendingUp, Star, Award, Target, Calendar, Dumbbell } from "lucide-react";
import TrainingCalendar, { CalendarDay } from "@/components/TrainingCalendar";
import ProgressGraphs from "@/components/ProgressGraphs";
import { exerciseTranslations } from "@/lib/exerciseTranslations";

const LEVEL_TITLES: Record<number, string> = {
  1: "Novato", 2: "Aprendiz", 3: "Atleta", 4: "Guerrero",
  5: "Campeón", 6: "Élite", 7: "Maestro", 8: "Leyenda",
  9: "Mítico", 10: "Inmortal",
};

export default function Progreso() {
  const { data: progress, isLoading: isProgressLoading } = trpc.training.getUserProgress.useQuery();
  const { data: completedDatesData, isLoading: isDatesLoading } = trpc.training.getCompletedDates.useQuery();
  const { data: trainingPlanData, isLoading: isPlanLoading } = trpc.training.getActivePlan.useQuery();
  const { data: checklistsData, isLoading: isChecklistsLoading } = trpc.training.getChecklists.useQuery();
  const { data: exerciseProgress, isLoading: isExLoading } = trpc.training.getExerciseProgress.useQuery();
  
  const [selectedDay, setSelectedDay] = useState<CalendarDay | null>(null);

  const isLoading = isProgressLoading || isDatesLoading || isPlanLoading || isChecklistsLoading;

  const level = progress?.level || 1;
  const xpInLevel = (progress?.totalXP || 0) % 500;
  const xpProgress = (xpInLevel / 500) * 100;
  const levelTitle = LEVEL_TITLES[Math.min(level, 10)] || "Leyenda";

  // Dynamic training days calculation from plan startDate forward for 4 months (120 days)
  const generateTrainingDays = (): CalendarDay[] => {
    if (!trainingPlanData || !(trainingPlanData as any).hasPlan) return [];
    
    const planObj = (trainingPlanData as any).generatedContent 
      ? (typeof (trainingPlanData as any).generatedContent === "string"
          ? JSON.parse((trainingPlanData as any).generatedContent)
          : (trainingPlanData as any).generatedContent)
      : null;

    if (!planObj || !planObj.days || planObj.days.length === 0) return [];

    const startDateStr = (trainingPlanData as any).startDate;
    if (!startDateStr) return [];
    const startDate = new Date(startDateStr);
    
    const N = planObj.daysPerWeek || 3;
    const startDayOfWeek = startDate.getDay();

    const trainingDaysOfWeek = new Set<number>();
    if (N === 1) {
      trainingDaysOfWeek.add(startDayOfWeek);
    } else if (N === 2) {
      trainingDaysOfWeek.add(startDayOfWeek);
      trainingDaysOfWeek.add((startDayOfWeek + 3) % 7);
    } else if (N === 3) {
      trainingDaysOfWeek.add(startDayOfWeek);
      trainingDaysOfWeek.add((startDayOfWeek + 2) % 7);
      trainingDaysOfWeek.add((startDayOfWeek + 4) % 7);
    } else if (N === 4) {
      trainingDaysOfWeek.add(startDayOfWeek);
      trainingDaysOfWeek.add((startDayOfWeek + 1) % 7);
      trainingDaysOfWeek.add((startDayOfWeek + 3) % 7);
      trainingDaysOfWeek.add((startDayOfWeek + 4) % 7);
    } else if (N === 5) {
      trainingDaysOfWeek.add(startDayOfWeek);
      trainingDaysOfWeek.add((startDayOfWeek + 1) % 7);
      trainingDaysOfWeek.add((startDayOfWeek + 2) % 7);
      trainingDaysOfWeek.add((startDayOfWeek + 4) % 7);
      trainingDaysOfWeek.add((startDayOfWeek + 5) % 7);
    } else if (N === 6) {
      trainingDaysOfWeek.add(startDayOfWeek);
      trainingDaysOfWeek.add((startDayOfWeek + 1) % 7);
      trainingDaysOfWeek.add((startDayOfWeek + 2) % 7);
      trainingDaysOfWeek.add((startDayOfWeek + 3) % 7);
      trainingDaysOfWeek.add((startDayOfWeek + 4) % 7);
      trainingDaysOfWeek.add((startDayOfWeek + 5) % 7);
    } else if (N === 7) {
      for (let i = 0; i < 7; i++) trainingDaysOfWeek.add(i);
    }

    const list: CalendarDay[] = [];
    let trainingDayIndex = 0;

    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + 120);

    const current = new Date(startDate);
    current.setHours(0, 0, 0, 0);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    while (current <= end) {
      const dayOfWeek = current.getDay();
      if (trainingDaysOfWeek.has(dayOfWeek)) {
        const planDay = planObj.days[trainingDayIndex % planObj.days.length];
        const dateStr = current.toISOString().split('T')[0];
        const checklist = checklistsData?.checklists?.find((c: any) => c.date === dateStr);

        list.push({
          date: new Date(current),
          isPadding: false,
          isTrainingDay: true,
          focus: planDay.focus,
          exercises: planDay.exercises || [],
          completed: checklist ? checklist.isCompleted === 1 : false,
          completedSeries: checklist ? checklist.completedSeries : 0,
          totalSeries: checklist ? checklist.totalSeries : (planDay.exercises?.reduce((acc: number, ex: any) => acc + (typeof ex.sets === 'string' ? parseInt(ex.sets) : ex.sets), 0) || 0),
          xpEarned: checklist ? checklist.xpEarned : 0,
        });

        trainingDayIndex++;
      } else {
        list.push({
          date: new Date(current),
          isPadding: false,
          isTrainingDay: false,
        });
      }
      current.setDate(current.getDate() + 1);
    }

    return list;
  };

  const calendarDays = generateTrainingDays();

  // Datos reales de progreso por ejercicio (desde exercise_history vía getExerciseProgress)

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="text-left">
          <h1 className="font-display text-4xl font-bold text-foreground">Progreso</h1>
          <p className="text-muted-foreground mt-1">Historial, estadísticas y logros de entrenamiento</p>
        </div>

        {isLoading && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <Skeleton className="h-64 rounded-2xl bg-muted/30 lg:col-span-2" />
            <Skeleton className="h-64 rounded-2xl bg-muted/30" />
          </div>
        )}

        {!isLoading && progress && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            
            {/* LEFT COLUMN: Stats, Level, Charts (8 cols) */}
            <div className="lg:col-span-8 space-y-6">
              
              {/* LEVEL PROGRESS CARD */}
              <Card className="p-6 glass-panel flex flex-col md:flex-row items-center justify-between gap-6 bg-gradient-to-br from-accent/15 to-accent/5 text-left">
                <div className="flex-1 space-y-4">
                  <div>
                    <span className="text-[10px] font-bold text-accent uppercase tracking-wider block">Nivel Actual</span>
                    <div className="flex items-baseline gap-2.5 mt-1.5">
                      <span className="font-display text-5xl font-bold text-foreground leading-none">{level}</span>
                      <span className="text-lg font-semibold text-foreground/90">{levelTitle}</span>
                    </div>
                  </div>
                  
                  <div className="space-y-2">
                    <div className="flex justify-between text-xs text-muted-foreground">
                      <span>{xpInLevel} / 500 XP</span>
                      <span>{500 - xpInLevel} XP para nivel {level + 1}</span>
                    </div>
                    <Progress value={xpProgress} className="h-2.5" />
                  </div>
                </div>

                {/* Circular indicator in SVG */}
                <div className="relative w-32 h-32 flex items-center justify-center shrink-0">
                  <svg viewBox="0 0 100 100" className="w-full h-full transform -rotate-90">
                    <circle cx="50" cy="50" r="40" fill="none" stroke="rgba(255,255,255,0.03)" strokeWidth="8" />
                    <circle 
                      cx="50" cy="50" r="40" fill="none" 
                      stroke="oklch(0.72 0.2 145)" strokeWidth="8" 
                      strokeDasharray={2 * Math.PI * 40}
                      strokeDashoffset={2 * Math.PI * 40 * (1 - (xpInLevel / 500))}
                      strokeLinecap="round"
                    />
                  </svg>
                  <div className="absolute text-center">
                    <Trophy className="w-8 h-8 text-accent mx-auto" />
                    <span className="text-[10px] text-muted-foreground mt-1 uppercase font-bold tracking-wider">Level Progress</span>
                  </div>
                </div>
              </Card>

              {/* STATS OVERVIEW GRID */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-left">
                <StatCard icon={Zap} label="XP Total" value={progress.totalXP?.toLocaleString() || "0"} sub="puntos" color="text-accent" bg="bg-accent/10 shadow-[0_0_15px_oklch(0.72_0.2_145/0.1)]" />
                <StatCard icon={Flame} label="Racha Actual" value={`${progress.streak}`} sub="días" color="text-accent" bg="bg-accent/10 shadow-[0_0_15px_oklch(0.72_0.2_145/0.1)]" />
                <StatCard icon={TrendingUp} label="Series Completadas" value={`${progress.seriesCompletedHistorically}`} sub="series" color="text-accent" bg="bg-accent/10 shadow-[0_0_15px_oklch(0.72_0.2_145/0.1)]" />
                <StatCard icon={Target} label="Total Entrenado" value={`${completedDatesData?.dates?.length || 0}`} sub="días completados" color="text-purple-400" bg="bg-purple-500/10 shadow-[0_0_15px_oklch(0.6_0.2_300/0.1)]" />
              </div>

              {/* EXERCISE PROGRESS GRAPHICS */}
              <div className="space-y-4 text-left">
                <h3 className="text-lg font-bold text-foreground font-display uppercase tracking-wider">
                  Progreso en Ejercicios Clave
                </h3>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {(exerciseProgress ?? []).length === 0 ? (
                    <Card className="p-6 border-border/50 bg-card/50 text-center col-span-full">
                      <p className="text-muted-foreground">Aún no hay registros de progreso. Completa series de tus ejercicios para ver tu evolución aquí.</p>
                    </Card>
                  ) : (
                    (exerciseProgress ?? []).map(({ exerciseName, data }) => (
                      <ProgressGraphs
                        key={exerciseName}
                        exerciseName={exerciseName}
                        data={data as any}
                      />
                    ))
                  )}
                </div>
              </div>

            </div>

            {/* RIGHT COLUMN: Achievements, Calendar, History (4 cols) */}
            <div className="lg:col-span-4 space-y-6">
              
              {/* ACHIEVEMENTS GRID */}
              <Card className="p-6 glass-panel text-left">
                <h3 className="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-5 flex items-center gap-2">
                  <Award className="w-5 h-5 text-accent" /> Logros Obtenidos
                </h3>

                <div className="grid grid-cols-2 gap-3">
                  {[
                    { icon: "🔥", title: "Primera Racha", desc: "3 días seguidos", unlocked: progress.streak >= 3 },
                    { icon: "💪", title: "Guerrero", desc: "50 series", unlocked: (progress.seriesCompletedHistorically || 0) >= 50 },
                    { icon: "⚡", title: "Nivel 5", desc: "Lograr nivel 5", unlocked: level >= 5 },
                    { icon: "🏆", title: "Centurión", desc: "100 series", unlocked: (progress.seriesCompletedHistorically || 0) >= 100 },
                    { icon: "🌟", title: "Racha Épica", desc: "7 días seguidos", unlocked: progress.streak >= 7 },
                    { icon: "👑", title: "Élite", desc: "Lograr nivel 6", unlocked: level >= 6 },
                  ].map((a, i) => (
                    <div 
                      key={i} 
                      className={`p-3 rounded-xl border transition-all ${
                        a.unlocked 
                          ? "border-accent/40 bg-accent/5 shadow-[0_0_10px_oklch(0.72_0.2_145/0.05)]" 
                          : "border-border/10 bg-muted/10 opacity-40"
                      }`}
                    >
                      <span className="text-xl block mb-1">{a.icon}</span>
                      <p className="font-semibold text-xs text-foreground truncate">{a.title}</p>
                      <p className="text-[10px] text-muted-foreground mt-0.5 line-clamp-1">{a.desc}</p>
                    </div>
                  ))}
                </div>
              </Card>

              {/* CALENDAR & HISTORIAL CARD */}
              <Card className="p-6 glass-panel text-left space-y-4">
                <h3 className="text-sm font-bold text-muted-foreground uppercase tracking-wider flex items-center gap-2">
                  <Calendar className="w-5 h-5 text-accent" /> Historial de Calendario
                </h3>

                <TrainingCalendar
                  calendarDays={calendarDays}
                  onDayClick={(day) => setSelectedDay(day)}
                  selectedDay={selectedDay}
                />

                {selectedDay && (
                  <div className="pt-3 border-t border-border/10 space-y-3 text-left">
                    <p className="text-xs font-bold text-foreground">
                      Detalle: {selectedDay.date.toLocaleDateString("es-ES", { day: "numeric", month: "short" })}
                    </p>
                    
                    {!selectedDay.isTrainingDay ? (
                      <p className="text-[11px] text-muted-foreground">Día de descanso programado</p>
                    ) : (
                      <div className="space-y-1.5 text-[11px]">
                        <p className="text-accent font-semibold">Enfoque: {selectedDay.focus}</p>
                        <p className="text-muted-foreground">
                          Progreso: {selectedDay.completedSeries || 0} / {selectedDay.totalSeries || 0} series ({selectedDay.totalSeries ? Math.round(((selectedDay.completedSeries || 0) / selectedDay.totalSeries) * 100) : 0}%)
                        </p>
                        <p className="text-muted-foreground">XP Ganado: +{selectedDay.xpEarned} XP</p>
                      </div>
                    )}
                  </div>
                )}
              </Card>

            </div>

          </div>
        )}
      </div>
    </DashboardLayout>
  );
}

function StatCard({ icon: Icon, label, value, sub, color, bg }: {
  icon: any; label: string; value: string; sub: string; color: string; bg: string;
}) {
  return (
    <Card className="p-4 glass-panel glass-panel-hover text-left flex flex-col justify-between">
      <div>
        <div className={`w-9 h-9 rounded-xl ${bg} flex items-center justify-center mb-3 shrink-0`}>
          <Icon className={`w-4.5 h-4.5 ${color}`} />
        </div>
        <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">{label}</p>
        <p className={`text-2xl font-bold font-display mt-1 ${color}`}>{value}</p>
      </div>
      <p className="text-[10px] text-muted-foreground mt-1.5">{sub}</p>
    </Card>
  );
}
