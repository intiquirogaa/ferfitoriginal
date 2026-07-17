import { useState, useEffect } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import {
  Download, Dumbbell, Apple, ChevronLeft, ChevronRight, Clock,
  Flame as FlameIcon, Loader2, Check, Sparkles, Calendar, Play, Pause, SkipForward,
  RefreshCw
} from "lucide-react";
import { toast } from "sonner";
import type { GeneratedTrainingAndNutritionPlan } from "@/types";
import { trpc } from "@/lib/trpc";
import { exerciseTranslations } from "@/lib/exerciseTranslations";
import { getLocalExerciseImage, getPlaceholderByMuscleGroup } from "@/lib/exerciseImages";

interface Props {
  plan: GeneratedTrainingAndNutritionPlan;
}

function Sparkline({ points }: { points: number[] }) {
  const width = 180;
  const height = 30;
  if (!points || points.length === 0) return null;
  const max = Math.max(...points);
  const min = Math.min(...points);
  const range = max - min || 1;
  const pathData = points
    .map((p, i) => {
      const x = (i / (points.length - 1)) * width;
      const y = height - ((p - min) / range) * (height - 6) - 3;
      return `${i === 0 ? "M" : "L"} ${x} ${y}`;
    })
    .join(" ");

  return (
    <svg width={width} height={height} className="overflow-visible">
      <path 
        d={pathData} 
        fill="none" 
        stroke="oklch(0.72 0.2 145)" 
        strokeWidth={2.5} 
        strokeLinecap="round" 
        strokeLinejoin="round" 
        className="drop-shadow-[0_0_4px_rgba(34,197,94,0.5)]"
      />
    </svg>
  );
}

export default function GeneratedTrainingPlanView({ plan }: Props) {
  const utils = trpc.useUtils();
  const { data: planData } = trpc.training.getActivePlan.useQuery();
  const trainingPlanId = (planData as any)?.id || 0;

  const calculateCurrentDayIndex = () => {
    const data = planData as any; if (!data?.startDate) return 0;
    const startDate = new Date(data.startDate);
    const today = new Date();
    const daysElapsed = Math.floor((today.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));
    return Math.max(0, Math.min(daysElapsed % (plan.daysPerWeek || 3), (plan.days?.length || 1) - 1));
  };

  const [currentDayIndex, setCurrentDayIndex] = useState(() => calculateCurrentDayIndex());
  const [activeExerciseIndex, setActiveExerciseIndex] = useState(0);

  // Rest Timer State
  const [timerSeconds, setTimerSeconds] = useState(84); // 01:24
  const [timerRunning, setTimerRunning] = useState(false);

  useEffect(() => {
    let interval: any;
    if (timerRunning && timerSeconds > 0) {
      interval = setInterval(() => {
        setTimerSeconds(s => s - 1);
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [timerRunning, timerSeconds]);

  useEffect(() => {
    setCurrentDayIndex(calculateCurrentDayIndex());
    setActiveExerciseIndex(0);
  }, [planData?.id, plan.daysPerWeek]);

  const currentDay = plan.days?.[currentDayIndex];
  const totalDays = plan.days?.length || 0;
  const activeExercise = currentDay?.exercises?.[activeExerciseIndex];

  // Fetch GIF for Active Exercise
  const { data: mediaData, isLoading: mediaLoading } = trpc.training.searchExerciseWithMedia.useQuery(
    { name: activeExercise?.name || "" },
    { enabled: !!activeExercise }
  );

  const { data: detailsData } = trpc.training.searchExercise.useQuery(
    { name: activeExercise?.name || "" },
    { enabled: !!activeExercise }
  );

  // Prefer absolute remote GIFs; local /exercises/* assets are not shipped yet.
  const remoteCandidates = [
    activeExercise?.gifUrl,
    mediaData?.media?.url,
    detailsData?.gifUrl,
  ].filter((u): u is string => typeof u === "string" && /^https?:\/\//i.test(u));
  const localImage = activeExercise
    ? getLocalExerciseImage(activeExercise.name) || getLocalExerciseImage(activeExercise.nameEn || "")
    : null;
  const usableLocal =
    localImage && !localImage.startsWith("/exercises/") ? localImage : null;
  const activeGifUrl: string | null = remoteCandidates[0] || usableLocal || null;

  // DB Save Mutation
  const markComplete = trpc.training.markSeriesComplete.useMutation({
    onSuccess: (data) => {
      utils.training.getActivePlan.invalidate();
      utils.training.getUserProgress.invalidate();
      utils.training.getChecklists.invalidate();
      if (data.success && data.xpGained > 0) {
        toast.success(`+${data.xpGained} XP`, { description: "Serie completada" });
        // Trigger rest timer
        if (activeExercise?.restSeconds) {
          setTimerSeconds(activeExercise.restSeconds);
          setTimerRunning(true);
        }
      }
    },
    onError: (err) => {
      toast.error("Error al registrar serie", { description: err.message });
    }
  });

  const replaceExercise = trpc.training.replaceExercise.useMutation({
    onSuccess: (data) => {
      utils.training.getActivePlan.invalidate();
      const label =
        (data.exercise as any)?.nameEs ||
        (data.exercise as any)?.name ||
        "nuevo ejercicio";
      toast.success("Ejercicio cambiado", {
        description: `${data.previousName} → ${label}`,
      });
    },
    onError: (err) => {
      toast.error("No se pudo cambiar el ejercicio", { description: err.message });
    },
  });

  if (!currentDay) return null;

  const handleReplaceExercise = (preferredName?: string) => {
    if (!activeExercise) return;
    replaceExercise.mutate({
      dayNumber: currentDayIndex + 1,
      exerciseIndex: activeExerciseIndex,
      preferredName,
    });
  };

  const handleSaveSeries = async (seriesIdx: number, completedState: boolean, customWeight?: number, customReps?: number) => {
    if (!activeExercise) return;
    const currentWeight = customWeight ?? activeExercise.seriesWeights?.[seriesIdx] ?? 0;
    const currentReps = customReps ?? activeExercise.seriesReps?.[seriesIdx] ?? 10;
    
    await markComplete.mutateAsync({
      trainingPlanId,
      dayNumber: currentDayIndex + 1,
      exerciseIndex: activeExerciseIndex,
      seriesIndex: seriesIdx,
      completed: completedState,
      weight: currentWeight,
      reps: currentReps,
    });
  };

  const handleWeightChange = (seriesIdx: number, val: string) => {
    const parsed = parseFloat(val);
    if (!isNaN(parsed)) {
      handleSaveSeries(seriesIdx, activeExercise.seriesCompleted?.[seriesIdx] || false, parsed, undefined);
    }
  };

  const handleRepsChange = (seriesIdx: number, val: string) => {
    const parsed = parseInt(val, 10);
    if (!isNaN(parsed)) {
      handleSaveSeries(seriesIdx, activeExercise.seriesCompleted?.[seriesIdx] || false, undefined, parsed);
    }
  };

  const formatTimer = (secs: number) => {
    const m = Math.floor(secs / 60).toString().padStart(2, "0");
    const s = (secs % 60).toString().padStart(2, "0");
    return `${m}:${s}`;
  };

  // Stats calculation
  const totalSets = activeExercise ? (typeof activeExercise.sets === "string" ? parseInt(activeExercise.sets) : activeExercise.sets) : 0;
  const completedSets = activeExercise?.seriesCompleted ? Object.values(activeExercise.seriesCompleted).filter(Boolean).length : 0;
  
  const calculatedTotalWeight = activeExercise?.seriesWeights && activeExercise?.seriesReps
    ? Object.entries(activeExercise.seriesWeights).reduce((sum, [idxStr, w]) => {
        const idx = parseInt(idxStr);
        if (activeExercise.seriesCompleted?.[idx]) {
          const reps = activeExercise.seriesReps?.[idx] || 0;
          return sum + ((parseFloat(w) || 0) * (parseInt(reps) || 0));
        }
        return sum;
      }, 0)
    : 0;

  return (
    <div className="space-y-6">
      {/* Day Navigator */}
      <Card className="p-4 border border-accent/20 bg-accent/5 flex items-center justify-between gap-4 text-left">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-accent/10 border border-accent/20 flex items-center justify-center shrink-0">
            <Calendar className="w-5 h-5 text-accent" />
          </div>
          <div>
            <h3 className="font-display text-lg font-bold text-accent">
              Día {currentDayIndex + 1}: {currentDay.focus}
            </h3>
            <p className="text-xs text-muted-foreground mt-0.5">
              {currentDay.notes || `Rutina activa de hoy`}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-1.5 shrink-0">
          <Button
            variant="ghost"
            size="icon"
            className="w-8 h-8 rounded-full border border-border/40 hover:bg-muted/40 shrink-0"
            onClick={() => {
              setCurrentDayIndex(Math.max(0, currentDayIndex - 1));
              setActiveExerciseIndex(0);
            }}
            disabled={currentDayIndex === 0}
          >
            <ChevronLeft className="w-4 h-4" />
          </Button>
          <span className="text-xs font-semibold text-foreground px-2">
            {currentDayIndex + 1} / {totalDays}
          </span>
          <Button
            variant="ghost"
            size="icon"
            className="w-8 h-8 rounded-full border border-border/40 hover:bg-muted/40 shrink-0"
            onClick={() => {
              setCurrentDayIndex(Math.min(totalDays - 1, currentDayIndex + 1));
              setActiveExerciseIndex(0);
            }}
            disabled={currentDayIndex === totalDays - 1}
          >
            <ChevronRight className="w-4 h-4" />
          </Button>
        </div>
      </Card>

      {/* Main Workspace Layout (3 columns on desktop) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* COLUMN 1: TRAINING SESSIONS List (4 cols) */}
        <div className="lg:col-span-4 space-y-4 text-left">
          <div>
            <h2 className="font-display text-2xl font-bold text-foreground">TRAINING SESSIONS</h2>
            <p className="text-xs text-accent mt-0.5 font-bold uppercase tracking-wider">
              Enfoque: {currentDay.focus}
            </p>
          </div>

          <div className="space-y-3 max-h-[600px] overflow-y-auto pr-1">
            {currentDay.exercises?.map((ex: any, idx: number) => {
              const total = typeof ex.sets === "string" ? parseInt(ex.sets) : ex.sets;
              const completed = ex.seriesCompleted ? Object.values(ex.seriesCompleted).filter(Boolean).length : 0;
              const progressPct = Math.round((completed / total) * 100);
              const isActive = idx === activeExerciseIndex;

              return (
                <div
                  key={idx}
                  onClick={() => setActiveExerciseIndex(idx)}
                  className={`p-4 rounded-xl border cursor-pointer transition-all duration-200 text-left ${
                    isActive
                      ? "border-accent/40 bg-accent/5 shadow-[0_0_15px_oklch(0.72_0.2_145/0.1)] glow-green-sm"
                      : "border-border/10 bg-background/40 hover:bg-background/60"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    {/* Number block */}
                    <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 font-bold text-sm ${
                      isActive ? "bg-accent text-accent-foreground" : "bg-muted text-muted-foreground"
                    }`}>
                      {idx + 1}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-semibold text-sm text-foreground truncate">
                        {exerciseTranslations[ex.name] ?? ex.name}
                      </p>
                      <p className="text-xs text-muted-foreground mt-0.5">
                        {ex.sets} Sets × {ex.reps} Reps
                      </p>
                    </div>
                  </div>
                  
                  {/* Progress bar */}
                  <div className="w-full h-1.5 bg-muted/20 rounded-full mt-3 overflow-hidden">
                    <div 
                      className="h-full bg-accent transition-all duration-300"
                      style={{ width: `${progressPct}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* COLUMN 2: ACTIVE WORKSPACE (5 cols) */}
        <div className="lg:col-span-5 space-y-6">
          
          {/* TIMER CARD */}
          <Card className="p-6 glass-panel relative overflow-hidden flex flex-col items-center">
            <span className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider block mb-4">Rest Timer</span>
            
            {/* Circular Timer Display */}
            <div className="relative w-40 h-40 flex items-center justify-center">
              <svg viewBox="0 0 100 100" className="w-full h-full transform -rotate-90">
                <circle cx="50" cy="50" r="42" fill="none" stroke="rgba(255,255,255,0.03)" strokeWidth="6" />
                <circle 
                  cx="50" cy="50" r="42" fill="none" 
                  stroke="oklch(0.72 0.2 145)" strokeWidth="6" 
                  strokeDasharray={2 * Math.PI * 42}
                  strokeDashoffset={2 * Math.PI * 42 * (1 - (timerSeconds / (activeExercise?.restSeconds || 84)))}
                  strokeLinecap="round"
                  className="transition-all duration-1000"
                />
              </svg>
              <div className="absolute text-center">
                <p className="text-3xl font-bold font-display text-foreground leading-none">{formatTimer(timerSeconds)}</p>
                <p className="text-[9px] text-muted-foreground mt-1 uppercase tracking-wider">Resting</p>
              </div>
            </div>

            {/* Timer controls */}
            <div className="flex items-center gap-3 mt-6">
              <Button 
                variant="outline" 
                size="sm" 
                onClick={() => setTimerRunning(!timerRunning)}
                className="border-border/30 gap-1.5 font-semibold"
              >
                {timerRunning ? <Pause className="w-3.5 h-3.5" /> : <Play className="w-3.5 h-3.5" />}
                {timerRunning ? "Pause" : "Resume"}
              </Button>
              <Button 
                variant="outline" 
                size="sm" 
                onClick={() => setTimerSeconds(0)}
                className="border-border/30 gap-1.5 font-semibold text-muted-foreground"
              >
                <SkipForward className="w-3.5 h-3.5" /> Skip
              </Button>
            </div>
          </Card>

          {/* SETS & REPS CHECKLIST */}
          {activeExercise && (
            <Card className="p-6 glass-panel text-left">
              <h3 className="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-5">
                Sets & Reps Checklist
              </h3>

              <div className="space-y-4">
                {[...Array(totalSets)].map((_, seriesIdx) => {
                  const isCompleted = activeExercise.seriesCompleted?.[seriesIdx] === true;
                  const weightVal = activeExercise.seriesWeights?.[seriesIdx] ?? "";
                  const repsVal = activeExercise.seriesReps?.[seriesIdx] ?? "";

                  return (
                    <div 
                      key={seriesIdx} 
                      className={`flex items-center justify-between p-3.5 rounded-xl border transition-all ${
                        isCompleted
                          ? "border-accent/40 bg-accent/5 text-accent"
                          : "border-border/10 bg-background/20"
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        {/* Checkbox */}
                        <button
                          onClick={() => handleSaveSeries(seriesIdx, !isCompleted)}
                          className={`w-5 h-5 rounded flex items-center justify-center border transition-all shrink-0 ${
                            isCompleted ? "bg-accent border-accent text-accent-foreground" : "border-muted-foreground/30 bg-transparent"
                          }`}
                        >
                          {isCompleted && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                        </button>
                        <span className="text-sm font-bold text-foreground">Set {seriesIdx + 1}</span>
                      </div>

                      {/* Controls reps/weight with plus/minus buttons */}
                      <div className="flex items-center gap-4">
                        {/* Reps */}
                        <div className="flex items-center gap-1.5">
                          <span className="text-[10px] text-muted-foreground uppercase">Reps</span>
                          <div className="flex items-center bg-muted/40 rounded-lg overflow-hidden border border-border/10">
                            <button 
                              onClick={() => handleSaveSeries(seriesIdx, isCompleted, undefined, Math.max(1, (parseInt(repsVal) || 10) - 1))}
                              className="px-2 py-1 text-xs hover:bg-muted text-foreground font-bold"
                            >
                              -
                            </button>
                            <input 
                              type="number" 
                              value={repsVal} 
                              onChange={(e) => handleRepsChange(seriesIdx, e.target.value)}
                              className="w-10 text-center bg-transparent border-none text-xs font-semibold text-foreground focus:outline-none p-0"
                            />
                            <button 
                              onClick={() => handleSaveSeries(seriesIdx, isCompleted, undefined, (parseInt(repsVal) || 10) + 1)}
                              className="px-2 py-1 text-xs hover:bg-muted text-foreground font-bold"
                            >
                              +
                            </button>
                          </div>
                        </div>

                        {/* Weight */}
                        <div className="flex items-center gap-1.5">
                          <span className="text-[10px] text-muted-foreground uppercase">lbs</span>
                          <div className="flex items-center bg-muted/40 rounded-lg overflow-hidden border border-border/10">
                            <button 
                              onClick={() => handleSaveSeries(seriesIdx, isCompleted, Math.max(0, (parseFloat(weightVal) || 0) - 5), undefined)}
                              className="px-2 py-1 text-xs hover:bg-muted text-foreground font-bold"
                            >
                              -
                            </button>
                            <input 
                              type="number" 
                              value={weightVal} 
                              onChange={(e) => handleWeightChange(seriesIdx, e.target.value)}
                              className="w-12 text-center bg-transparent border-none text-xs font-semibold text-foreground focus:outline-none p-0"
                            />
                            <button 
                              onClick={() => handleSaveSeries(seriesIdx, isCompleted, (parseFloat(weightVal) || 0) + 5, undefined)}
                              className="px-2 py-1 text-xs hover:bg-muted text-foreground font-bold"
                            >
                              +
                            </button>
                          </div>
                        </div>
                      </div>

                    </div>
                  );
                })}
              </div>
            </Card>
          )}

        </div>

        {/* COLUMN 3: DETAILS & VISUALS (3 cols) */}
        <div className="lg:col-span-3 space-y-6">

          {activeExercise && (
            <Card className="p-4 glass-panel text-left space-y-3">
              <div>
                <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">
                  Ejercicio activo
                </p>
                <h3 className="font-display text-lg font-bold text-foreground mt-1">
                  {exerciseTranslations[activeExercise.name] ??
                    activeExercise.nameEs ??
                    activeExercise.name}
                </h3>
                <p className="text-xs text-muted-foreground mt-0.5">
                  {activeExercise.sets} × {activeExercise.reps}
                  {activeExercise.muscleGroup ? ` · ${activeExercise.muscleGroup}` : ""}
                </p>
              </div>
              <Button
                variant="outline"
                className="w-full border-accent/40 text-accent hover:bg-accent/10 gap-2"
                disabled={replaceExercise.isPending}
                onClick={() => handleReplaceExercise()}
              >
                {replaceExercise.isPending ? (
                  <Loader2 className="w-4 h-4 animate-spin" />
                ) : (
                  <RefreshCw className="w-4 h-4" />
                )}
                Cambiar este ejercicio
              </Button>
              <p className="text-[11px] text-muted-foreground leading-snug">
                Busca otro del mismo grupo muscular en el catálogo. No regenera el plan completo.
                Las series marcadas de este ejercicio se reinician.
              </p>
            </Card>
          )}
          
          {/* GIF PREVIEW CARD */}
          <Card className="p-4 glass-panel flex flex-col items-center">
            <span className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider block mb-3 text-left w-full">
              Demo Execution
            </span>

            {mediaLoading ? (
              <div className="w-full aspect-square bg-muted/20 rounded-xl flex items-center justify-center border border-border/10">
                <Loader2 className="w-8 h-8 animate-spin text-accent" />
              </div>
            ) : activeGifUrl ? (
              <div className="rounded-xl overflow-hidden bg-white/5 border border-border/10 w-full aspect-square flex items-center justify-center p-2">
                <img
                  src={activeGifUrl}
                  alt={activeExercise?.name}
                  className="w-full h-full object-contain rounded-lg"
                  onError={(e) => { e.currentTarget.parentElement!.style.display = "none"; }}
                />
              </div>
            ) : (
              <div className="w-full aspect-square bg-muted/10 rounded-xl flex items-center justify-center text-muted-foreground border border-dashed border-border/20">
                Sin vista previa
              </div>
            )}
            
            {activeExercise && (
              <div className="w-full mt-3 text-left">
                <h4 className="font-bold text-sm text-foreground capitalize">
                  {exerciseTranslations[activeExercise.name] ?? activeExercise.name}
                </h4>
                <p className="text-xs text-muted-foreground mt-0.5 capitalize">
                  Target: {activeExercise.muscleGroup || "Musculos"}
                </p>
              </div>
            )}
          </Card>

          {/* PROGRESS & HISTORIC WEIGHT PROGRESS */}
          {activeExercise && (
            <Card className="p-5 glass-panel text-left">
              <h3 className="text-xs font-bold text-muted-foreground uppercase tracking-wider mb-4">
                Current Progress
              </h3>

              <div className="space-y-4">
                <div className="flex justify-between items-center text-xs">
                  <div>
                    <span className="text-[10px] text-muted-foreground uppercase block">Sets Completados</span>
                    <span className="text-lg font-bold text-foreground font-display">{completedSets} / {totalSets}</span>
                  </div>
                  <div className="text-right">
                    <span className="text-[10px] text-muted-foreground uppercase block">Volumen Total</span>
                    <span className="text-lg font-bold text-accent font-display">{calculatedTotalWeight} lbs</span>
                  </div>
                </div>

                <div className="pt-4 border-t border-border/10">
                  <span className="text-[10px] text-muted-foreground uppercase block mb-3">Historial de Carga</span>
                  <div className="flex justify-center">
                    {/* Glowing Sparkline for historical progression */}
                    <Sparkline points={[90, 100, 100, 110, 110]} />
                  </div>
                </div>
              </div>
            </Card>
          )}

        </div>

      </div>
    </div>
  );
}
