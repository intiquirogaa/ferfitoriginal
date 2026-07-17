import { COOKIE_NAME } from "@shared/const";
import { getDb } from "./db";
import { eq } from "drizzle-orm"; 
import { getSessionCookieOptions } from "./_core/cookies";
import { systemRouter } from "./_core/systemRouter";
import { publicProcedure, router, protectedProcedure } from "./_core/trpc";
import { invokeLLM } from "./_core/llm";
import { callDataApi } from "./_core/dataApi";
import { z } from "zod";
import { getCatalogPromptString } from "./_core/catalog";
import { buildEngagement } from "./_core/engagement";
import * as db from "./db";
import { trainingPlans, dailyChecklists, userProgress, exerciseHistory } from "../drizzle/schema";
import { exerciseRouter } from "./routers/exerciseRouter";
import {
  progressQuest,
  getOrGenerateTodayQuests,
  claimQuestReward,
  submitCameraProof,
  buildChallengeNotifications,
} from "./_core/quests";
import {
  listReplacementOptions,
  replaceExerciseInActivePlan,
} from "./_core/replaceExercise";

const DAYS_FULL = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"];

// Helper para actualizar plan de entrenamiento
async function updateTrainingPlanContent(planId: number, generatedContent: string) {
  const database = await getDb();
  if (!database) throw new Error("Database not available");
  await database.update(trainingPlans)
    .set({ generatedContent })
    .where(eq(trainingPlans.id, planId));
}


export const appRouter = router({
  system: systemRouter,
  auth: router({
    me: publicProcedure.query(opts => opts.ctx.user),
    logout: publicProcedure.mutation(({ ctx }) => {
      const cookieOptions = getSessionCookieOptions(ctx.req);
      ctx.res.clearCookie(COOKIE_NAME, { ...cookieOptions, maxAge: -1 });
      return { success: true } as const;
    }),
  }),
  training: router({
    createPlan: protectedProcedure
      .input(z.object({
        objective: z.enum(["hypertrophy", "strength", "fat_loss", "recomposition"]),
        experienceLevel: z.enum(["beginner", "intermediate", "advanced"]).optional(),
        experience: z.enum(["beginner", "intermediate", "advanced"]).optional(),
        gender: z.string().optional(),
        activityLevel: z.string().optional(),
        trainingTimeMinutes: z.number().optional(),
        age: z.number().min(13).max(100),
        weight: z.number().min(30).max(300),
        height: z.number().min(100).max(250),
        daysPerWeek: z.number().min(2).max(6),
        equipment: z.enum(["full_gym", "dumbbells", "bodyweight", "limited"]).optional(),
        injuries: z.string().optional(),
        preferences: z.string().optional(),
        dietaryRestrictions: z.union([z.string(), z.array(z.string())]).optional(),
        useDemo: z.boolean().optional(),
      }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        try {
          console.log("[createPlan] Generating plan for user:", ctx.user.id);
          const selectedExperience = input.experienceLevel ?? input.experience ?? "intermediate";
          const selectedEquipment = input.equipment ?? "full_gym";

          // Contexto real del usuario para personalizar el plan según su historial
          let userContext: string | undefined;
          try {
            const progress = await db.getUserProgress(ctx.user.id);
            const checklists = await db.getUserChecklists(ctx.user.id);
            const completedWorkouts = checklists.filter((c: any) => c.isCompleted === 1).length;
            if (progress || completedWorkouts > 0) {
              const parts: string[] = [];
              if (progress) {
                parts.push(`Nivel actual: ${progress.level || 1}`);
                parts.push(`Racha actual: ${progress.streak || 0} días`);
                parts.push(`Series completadas históricamente: ${progress.seriesCompletedHistorically || 0}`);
                parts.push(`XP total: ${progress.totalXP || 0}`);
              }
              parts.push(`Entrenamientos completados: ${completedWorkouts}`);
              userContext = parts.join(". ");
            }
          } catch {
            userContext = undefined;
          }

          const generatedPlan = await generatePersonalizedPlanWithNutrition({
            objective: input.objective,
            experienceLevel: selectedExperience,
            age: input.age,
            weight: input.weight,
            height: input.height,
            daysPerWeek: input.daysPerWeek,
            equipment: selectedEquipment,
            injuries: input.injuries,
            preferences: input.preferences,
            dietaryRestrictions: input.dietaryRestrictions,
            gender: input.gender,
            activityLevel: input.activityLevel,
            trainingTimeMinutes: input.trainingTimeMinutes,
            userContext,
          });
          const generatedContentJson = JSON.stringify(generatedPlan);
          const result = await db.createTrainingPlan(
            ctx.user.id,
            input.objective === "strength" ? "strength" : "hypertrophy",
            input.daysPerWeek,
            generatedContentJson
          );
          console.log("[createPlan] Plan saved:", result);
          return {
            id: (result as any).insertId || 0,
            userId: ctx.user.id,
            type: input.objective === "strength" ? "strength" : "hypertrophy",
            daysPerWeek: input.daysPerWeek,
            durationWeeks: 12,
            generatedContent: generatedContentJson,
            isActive: 1,
            startDate: new Date(),
            createdAt: new Date(),
            updatedAt: new Date(),
          };
        } catch (error) {
          console.error("[createPlan] Error:", error);
          throw error;
        }
      }),

    getActivePlan: protectedProcedure.query(async ({ ctx }) => {
      if (!ctx.user) throw new Error("Not authenticated");
      try {
        const plan = await db.getActiveTrainingPlan(ctx.user.id);
        if (!plan) return { hasPlan: false, id: null, userId: ctx.user.id };
        let generatedContent = plan.generatedContent;
        if (typeof generatedContent === "string") {
          try { generatedContent = JSON.parse(generatedContent); } catch { /* keep as string */ }
        }

        // Dynamic translation and enrichment for existing plans
        if (generatedContent && Array.isArray(generatedContent.days)) {
          const { getExerciseMediaUrl, isUsableMediaUrl } = await import("./_core/musclewiki");
          const { translateExerciseToSpanish } = await import("./_core/translations");
          
          let modified = false;

          // --- WEEKLY RESET LOGIC ---
          // Resetea los checks al iniciar una nueva semana de la rutina
          const planStartDate = plan.startDate ? new Date(plan.startDate) : new Date();
          planStartDate.setHours(0,0,0,0);
          const today = new Date();
          today.setHours(0,0,0,0);
          const diffDays = Math.floor((today.getTime() - planStartDate.getTime()) / (1000 * 60 * 60 * 24));
          const currentPlanWeek = Math.max(0, Math.floor(diffDays / 7));

          const lastResetWeek = generatedContent.lastResetWeek ?? -1;
          
          if (currentPlanWeek > lastResetWeek) {
            for (const day of generatedContent.days) {
              for (const ex of day.exercises || []) {
                ex.seriesCompleted = {};
                ex.seriesWeights = {};
                ex.seriesReps = {};
              }
            }
            generatedContent.lastResetWeek = currentPlanWeek;
            modified = true;
          }
          
          for (const day of generatedContent.days) {
            for (const ex of day.exercises || []) {
              const currentName = ex.name || "";
              
              // 1. Fetch GIF if missing or stored as broken local path (/exercises/*)
              const hasGoodGif = isUsableMediaUrl(ex.gifUrl);
              if (!hasGoodGif && currentName) {
                const searchName = ex.nameEn || currentName;
                const media = await getExerciseMediaUrl(searchName);
                if (media && isUsableMediaUrl(media.url)) {
                  ex.gifUrl = media.url;
                  modified = true;
                } else if (ex.gifUrl && !hasGoodGif) {
                  // Clear dead relative paths so clients don't keep failing
                  delete ex.gifUrl;
                  modified = true;
                }
              }
              
              // 2. Translate name if needed
              const spanishName = translateExerciseToSpanish(currentName);
              if (spanishName !== currentName && !ex.nameEn) {
                ex.nameEn = currentName;
                ex.name = spanishName;
                modified = true;
              }
            }
          }
          
          if (modified) {
            await db.updateTrainingPlanContent(plan.id, JSON.stringify(generatedContent));
          }
        }

        return { ...plan, hasPlan: true, generatedContent };
      } catch (error) {
        console.error("[getActivePlan] Error:", error);
        return { hasPlan: false, id: null, userId: ctx.user.id } as any;
      }
    }),

    getTodayChecklist: protectedProcedure.query(async ({ ctx }) => {
      if (!ctx.user) throw new Error("Not authenticated");
      try {
        const checklist = await db.getTodayChecklist(ctx.user.id);
        return checklist || { hasTrainingToday: false, exercises: [], id: null, userId: ctx.user.id };
      } catch (error) {
        console.error("[getTodayChecklist] Error:", error);
        return { hasTrainingToday: false, exercises: [], id: null, userId: ctx.user.id };
      }
    }),

    getUserProgress: protectedProcedure.query(async ({ ctx }) => {
      if (!ctx.user) throw new Error("Not authenticated");
      let progress = await db.getUserProgress(ctx.user.id);
      if (!progress) {
        await db.createUserProgress(ctx.user.id);
        progress = await db.getUserProgress(ctx.user.id);
      }
      return progress;
    }),

    getAchievements: publicProcedure.query(async () => {
      return await db.getAchievements();
    }),

    getUserAchievements: protectedProcedure.query(async ({ ctx }) => {
      if (!ctx.user) throw new Error("Not authenticated");
      return await db.getUserAchievements(ctx.user.id);
    }),

    getStats: protectedProcedure.query(async ({ ctx }) => {
      if (!ctx.user) throw new Error("Not authenticated");
      
      const database = await db.getDb();
      if (!database) throw new Error("Database not available");

      const progress = await db.getUserProgress(ctx.user.id);
      
      const checklists = await database
        .select()
        .from(dailyChecklists)
        .where(eq(dailyChecklists.userId, ctx.user.id));
      
      const totalWorkoutsCompleted = checklists.filter((c: any) => c.isCompleted === 1).length;

      const plans = await database
        .select()
        .from(trainingPlans)
        .where(eq(trainingPlans.userId, ctx.user.id));
      
      let seriesProgrammed = 0;
      let seriesCompleted = 0;

      for (const plan of plans) {
        const generatedContent = JSON.parse(plan.generatedContent || "{}");
        for (const day of generatedContent.days || []) {
          for (const ex of day.exercises || []) {
            const totalSets = ex.sets || 3;
            seriesProgrammed += totalSets;
            seriesCompleted += Object.values(ex.seriesCompleted || {}).filter(Boolean).length;
          }
        }
      }

      return {
        seriesCompleted,
        seriesProgrammed,
        totalWorkoutsCompleted,
        xp: progress?.totalXP || 0,
      };
    }),


    createDailyChecklist: protectedProcedure
      .input(z.object({
        trainingPlanId: z.number(),
        dayOfWeek: z.string(),
        totalSeries: z.number().min(1).max(100),
      }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        return await db.createDailyChecklist(ctx.user.id, input.trainingPlanId, input.dayOfWeek, input.totalSeries);
      }),

    generateDemoRoutine: protectedProcedure.mutation(async ({ ctx }) => {
      if (!ctx.user) throw new Error("Not authenticated");
      try {
        const generatedContent = await generatePersonalizedPlanWithNutrition({
          objective: "hypertrophy",
          experienceLevel: "intermediate",
          age: 28,
          weight: 75,
          height: 180,
          daysPerWeek: 4,
          equipment: "full_gym",
          injuries: "",
          preferences: "Upper/Lower split",
        });
        const planId = await db.createTrainingPlan(ctx.user.id, "hypertrophy", 4, JSON.stringify(generatedContent));
        return { id: planId, userId: ctx.user.id, type: "hypertrophy", daysPerWeek: 4, generatedContent, isActive: 1 };
      } catch (error) {
        console.error("[generateDemoRoutine] Error:", error);
        throw new Error("No se pudo generar la rutina de demo");
      }
    }),

    searchExercise: protectedProcedure
      .input(z.object({ name: z.string() }))
      .query(async ({ input }) => {
        try {
          console.log("[searchExercise] Searching for:", input.name);
          const result = await callDataApi("ExerciseDB/exercises/name/{name}", {
            pathParams: { name: encodeURIComponent(input.name.toLowerCase()) },
            query: { limit: 3, offset: 0 },
          }) as any[];
          if (Array.isArray(result) && result.length > 0) {
            const ex = result[0];
            return {
              found: true,
              gifUrl: ex.gifUrl || null,
              instructions: Array.isArray(ex.instructions) ? ex.instructions : [],
              targetMuscles: ex.target || ex.targetMuscles || "",
              secondaryMuscles: Array.isArray(ex.secondaryMuscles) ? ex.secondaryMuscles : [],
              equipment: ex.equipment || "",
              bodyPart: ex.bodyPart || "",
            };
          }
          return { found: false, gifUrl: null, instructions: [], targetMuscles: "", secondaryMuscles: [], equipment: "", bodyPart: "" };
        } catch (error) {
          console.error("[searchExercise] Error:", error);
          return { found: false, gifUrl: null, instructions: [], targetMuscles: "", secondaryMuscles: [], equipment: "", bodyPart: "" };
        }
      }),
    markSeriesComplete: protectedProcedure
      .input(z.object({
        trainingPlanId: z.number(),
        dayNumber: z.number(),
        exerciseIndex: z.number(),
        seriesIndex: z.number(),
        completed: z.boolean(),
        weight: z.number().optional(),
        reps: z.number().optional(),
      }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        try {
          // Obtener el plan actual
          const plan = await db.getActiveTrainingPlan(ctx.user.id);
          if (!plan) throw new Error("No active training plan");
          
          const generatedContent = JSON.parse(plan.generatedContent || "{}");
          const day = generatedContent.days?.[input.dayNumber - 1];
          if (!day) throw new Error("Day not found");
          
          const exercise = day.exercises?.[input.exerciseIndex];
          if (!exercise) throw new Error("Exercise not found");
          
          // Inicializar tracking si no existe
          if (!exercise.seriesCompleted) exercise.seriesCompleted = {};
          if (!exercise.seriesWeights) exercise.seriesWeights = {};
          if (!exercise.seriesReps) exercise.seriesReps = {};
          
          const wasCompleted = exercise.seriesCompleted[input.seriesIndex] === true;
          const currentWeight = exercise.seriesWeights[input.seriesIndex];
          const currentReps = exercise.seriesReps[input.seriesIndex];
          
          // Check if anything actually changed
          const completionChanged = wasCompleted !== input.completed;
          const weightChanged = input.weight !== undefined && currentWeight !== input.weight;
          const repsChanged = input.reps !== undefined && currentReps !== input.reps;
          
          if (!completionChanged && !weightChanged && !repsChanged) {
            return { success: true, xpGained: 0, newXp: 0, unlockedAchievements: [] };
          }
          
          // Save weight and reps
          if (input.weight !== undefined) {
            exercise.seriesWeights[input.seriesIndex] = input.weight;
          }
          if (input.reps !== undefined) {
            exercise.seriesReps[input.seriesIndex] = input.reps;
          }
          
          exercise.seriesCompleted[input.seriesIndex] = input.completed;
          
          // Calcular XP: +10 por serie completada, -10 al desmarcar
          let xpGained = 0;
          if (completionChanged) {
            if (input.completed) {
              xpGained = 10;
              // Bonus si todas las series del ejercicio están completadas
              const totalSeries = exercise.sets || 3;
              const completedSeries = Object.values(exercise.seriesCompleted as Record<string, boolean>).filter(Boolean).length;
              if (completedSeries === totalSeries) xpGained += 25;
            } else {
              xpGained = -10;
            }
          }
          
          // Actualizar progreso del usuario
          let progress = await db.getUserProgress(ctx.user.id);
          if (!progress) {
            await db.createUserProgress(ctx.user.id);
            progress = await db.getUserProgress(ctx.user.id);
          }
          let newXp = progress ? (progress.totalXP || 0) : 0;
          if (progress && completionChanged) {
            newXp = Math.max(0, newXp + xpGained);
            await db.updateUserProgress(ctx.user.id, xpGained, input.completed ? 1 : -1, plan.daysPerWeek);
          }
          
          // Guardar cambios en el plan
          const updatedPlan = JSON.stringify(generatedContent);
          await updateTrainingPlanContent(plan.id, updatedPlan);

          // --- CÁLCULO DE COMPLETADO DEL DÍA & RACHA ---
          let totalSeriesToday = 0;
          let completedSeriesToday = 0;
          for (const dEx of day.exercises || []) {
            totalSeriesToday += dEx.sets || 3;
            completedSeriesToday += Object.values(dEx.seriesCompleted || {}).filter(Boolean).length;
          }

          let checklist = await db.getTodayChecklist(ctx.user.id);
          if (!checklist) {
            // Si no existe checklist hoy, crearlo
            const dayName = DAYS_FULL[new Date().getDay()];
            await db.createDailyChecklist(ctx.user.id, plan.id, dayName, totalSeriesToday);
            checklist = await db.getTodayChecklist(ctx.user.id);
          }

          if (checklist) {
            const isDayCompletedNow = completedSeriesToday === totalSeriesToday;
            // Actualizar checklist
            const d = await db.getDb();
            if (d) {
              await d.update(dailyChecklists).set({
                completedSeries: completedSeriesToday,
                isCompleted: isDayCompletedNow ? 1 : 0,
                xpEarned: Math.max(0, (checklist.xpEarned || 0) + xpGained),
              }).where(eq(dailyChecklists.id, checklist.id));
            }

            // Registrar/actualizar historial del ejercicio para los gráficos de progreso
            const completedSeriesIdx = Object.entries(exercise.seriesCompleted || {})
              .filter(([, v]) => v === true)
              .map(([k]) => Number(k));
            const completedRepsList = completedSeriesIdx
              .map((i) => exercise.seriesReps?.[i])
              .filter((v) => v !== undefined && v !== null);
            const completedWeights = completedSeriesIdx
              .map((i) => exercise.seriesWeights?.[i])
              .filter((v) => typeof v === "number");
            const representativeWeight = typeof input.weight === "number"
              ? input.weight
              : (completedWeights.length ? Math.max(...completedWeights) : null);
            const existingHistory = (await db.getExerciseHistoryByDay(ctx.user.id, checklist.id))
              .find((e: any) => e.exerciseName === exercise.name && e.exerciseIndex === input.exerciseIndex);
            const historyPayload = {
              userId: ctx.user.id,
              trainingPlanId: plan.id,
              dailyChecklistId: checklist.id,
              exerciseName: exercise.name,
              dayNumber: input.dayNumber,
              exerciseIndex: input.exerciseIndex,
              plannedSets: typeof exercise.sets === "number" ? exercise.sets : (parseInt(exercise.sets as string) || 3),
              plannedReps: String(exercise.reps ?? ""),
              completedSets: completedSeriesIdx.length,
              completedReps: completedRepsList.length ? completedRepsList.join(",") : null,
              weight: representativeWeight,
              isCompleted: completedSeriesIdx.length > 0 ? 1 : 0,
              completedAt: new Date(),
            };
            if (existingHistory) {
              await db.updateExerciseHistory(existingHistory.id, historyPayload);
            } else {
              await db.createExerciseHistory(historyPayload);
            }
          }
          
          // Verificar logros y misiones (series + villanos + sesión matutina)
          if (completionChanged) {
            const exerciseName = String(
              exercise.nameEn || exercise.name || exercise.nameEs || ""
            );
            await progressQuest(
              ctx.user.id,
              "complete_series",
              input.completed ? 1 : -1,
              { exerciseName, hourLocal: new Date().getHours() }
            );
            if (checklist?.isCompleted) {
              await progressQuest(ctx.user.id, "complete_day", 1);
            }
          }
          
          const newlyUnlocked = await db.checkAndUnlockAchievements(ctx.user.id);

          return { 
            success: true, 
            xpGained, 
            newXp,
            unlockedAchievements: newlyUnlocked 
          };
        } catch (error) {
          console.error("[markSeriesComplete] Error:", error);
          throw error;
        }
      }),

    /** Lista alternativas del catálogo para un ejercicio del plan activo. */
    listExerciseReplacements: protectedProcedure
      .input(z.object({
        dayNumber: z.number().min(1),
        exerciseIndex: z.number().min(0),
      }))
      .query(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        return listReplacementOptions({
          userId: ctx.user.id,
          dayNumber: input.dayNumber,
          exerciseIndex: input.exerciseIndex,
        });
      }),

    /**
     * Reemplaza un solo ejercicio del plan activo (mismo grupo muscular del catálogo).
     * Conserva sets/reps; resetea series marcadas de ese ejercicio.
     */
    replaceExercise: protectedProcedure
      .input(z.object({
        dayNumber: z.number().min(1),
        exerciseIndex: z.number().min(0),
        preferredName: z.string().optional(),
      }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        try {
          return await replaceExerciseInActivePlan({
            userId: ctx.user.id,
            dayNumber: input.dayNumber,
            exerciseIndex: input.exerciseIndex,
            preferredName: input.preferredName,
          });
        } catch (error) {
          console.error("[replaceExercise] Error:", error);
          throw error;
        }
      }),

    getExerciseProgress: protectedProcedure
      .query(async ({ ctx }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        try {
          const plan = await db.getActiveTrainingPlan(ctx.user.id);
          if (!plan || !(plan as any).generatedContent) return [];

          const generatedContent = JSON.parse((plan as any).generatedContent || "{}");
          const days = generatedContent.days || [];
          const exerciseNames: string[] = [];
          for (const day of days) {
            for (const ex of day.exercises || []) {
              if (ex?.name && !exerciseNames.includes(ex.name)) exerciseNames.push(ex.name);
            }
          }

          const mapRow = (r: any) => {
            const repsRaw = r.completedReps
              ? String(r.completedReps).split(",").map(Number).filter((n: number) => !isNaN(n))
              : [];
            const reps = repsRaw.length
              ? Math.round(repsRaw.reduce((a: number, b: number) => a + b, 0) / repsRaw.length)
              : undefined;
            const date = r.completedAt
              ? new Date(r.completedAt).toLocaleDateString("es-ES", { day: "2-digit", month: "short" })
              : "";
            return {
              date,
              weight: r.weight ?? undefined,
              reps,
              sets: r.completedSets || undefined,
              duration: r.duration ?? undefined,
            };
          };

          const result: { exerciseName: string; data: ReturnType<typeof mapRow>[] }[] = [];
          for (const name of exerciseNames.slice(0, 8)) {
            const rows = await db.getExerciseProgressStats(ctx.user.id, name);
            const data = rows.map(mapRow).filter(
              (d: any) => d.weight !== undefined || d.reps !== undefined || d.sets !== undefined
            );
            if (data.length > 0) result.push({ exerciseName: name, data });
          }
          return result;
        } catch (error) {
          console.error("[getExerciseProgress] Error:", error);
          return [];
        }
      }),
    searchExerciseWithMedia: publicProcedure
      .input(z.object({
        name: z.string(),
        limit: z.number().optional(),
      }))
      .query(async ({ input }) => {
        try {
          const { getExerciseMediaUrl } = await import("./_core/musclewiki");
          const media = await getExerciseMediaUrl(input.name);
          return {
            success: true,
            media,
            exerciseName: input.name,
          };
        } catch (error) {
          console.error("[searchExerciseWithMedia] Error:", error);
          return {
            success: false,
            media: null,
            error: "Failed to search exercise media",
          };
        }
      }),

    getDailyProgress: protectedProcedure
      .input(z.object({
        trainingPlanId: z.number(),
        dayNumber: z.number(),
      }))
      .query(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        try {
          const plan = await db.getActiveTrainingPlan(ctx.user.id);
          if (!plan) return { exercises: [] };
          
          const generatedContent = JSON.parse(plan.generatedContent || "{}");
          const day = generatedContent.days?.[input.dayNumber - 1];
          if (!day) return { exercises: [] };
          
          return {
            dayNumber: input.dayNumber,
            focus: day.focus,
            exercises: (day.exercises || []).map((ex: any, idx: number) => ({
              index: idx,
              name: ex.name,
              sets: ex.sets || 3,
              reps: ex.reps,
              seriesCompleted: ex.seriesCompleted || {},
            })),
          };
        } catch (error) {
          console.error("[getDailyProgress] Error:", error);
          return { exercises: [] };
        }
      }),
      getChecklists: protectedProcedure.query(async ({ ctx }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        try {
          const checklists = await db.getUserChecklists(ctx.user.id);
          return { success: true, checklists };
        } catch (error) {
          console.error("[getChecklists] Error:", error);
          return { success: false, checklists: [] };
        }
      }),
      getCompletedDates: protectedProcedure.query(async ({ ctx }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        try {
          const completedDates = await db.getCompletedDates(ctx.user.id);
          return { dates: completedDates };
        } catch (error) {
          console.error("[getCompletedDates] Error:", error);
          return { dates: [] };
        }
      }),
      getDayDetails: protectedProcedure
        .input(z.object({ date: z.date() }))
        .query(async ({ ctx, input }) => {
          if (!ctx.user) throw new Error("Not authenticated");
          try {
            const dayDetails = await db.getDayDetails(ctx.user.id, input.date);
            if (!dayDetails) return { checklist: null, exercises: [], duration: 0 };
            const plan = JSON.parse(dayDetails.plan.generatedContent || "{}");
            const dayOfWeek = input.date.toLocaleDateString('es-ES', { weekday: 'long' });
            const dayIndex = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'].indexOf(dayOfWeek.toLowerCase());
            const dayPlan = plan.plan?.days?.[dayIndex] || { exercises: [] };
            return { checklist: dayDetails.checklist, exercises: dayPlan.exercises || [], duration: dayPlan.duration || 0 };
          } catch (error) {
            console.error("[getDayDetails] Error:", error);
            return { checklist: null, exercises: [], duration: 0 };
          }
        }),

      getDashboardData: protectedProcedure.query(async ({ ctx }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        try {
          const database = await db.getDb();
          if (!database) throw new Error("Database not available");

          const allChecklists = await db.getUserChecklists(ctx.user.id);

          // Weekly chart: workouts per day-of-week for the current week (Mon-Sun)
          const now = new Date();
          const dayOfWeek = now.getDay(); // 0=Sun,1=Mon...
          // Start of this week Monday
          const startOfWeek = new Date(now);
          startOfWeek.setHours(0, 0, 0, 0);
          startOfWeek.setDate(now.getDate() - ((dayOfWeek + 6) % 7));
          const endOfWeek = new Date(startOfWeek);
          endOfWeek.setDate(startOfWeek.getDate() + 6);
          endOfWeek.setHours(23, 59, 59, 999);

          // Count completed workouts per weekday this week
          const weekCounts: Record<number, number> = { 0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0 };
          for (const c of allChecklists) {
            if (c.isCompleted !== 1) continue;
            const d = new Date(c.date);
            if (d >= startOfWeek && d <= endOfWeek) {
              const wd = (d.getDay() + 6) % 7; // Mon=0...Sun=6
              weekCounts[wd] = (weekCounts[wd] || 0) + 1;
            }
          }
          // Weekly progress stats
          const weekStats: Record<number, { series: number, xp: number }> = { 0: {series:0,xp:0}, 1: {series:0,xp:0}, 2: {series:0,xp:0}, 3: {series:0,xp:0}, 4: {series:0,xp:0}, 5: {series:0,xp:0}, 6: {series:0,xp:0} };
          let weeklyTotalSeries = 0;
          let weeklyTotalXP = 0;
          for (const c of allChecklists) {
            const d = new Date(c.date);
            if (d >= startOfWeek && d <= endOfWeek) {
              const wd = (d.getDay() + 6) % 7; // Mon=0...Sun=6
              weekStats[wd].series += (c.completedSeries || 0);
              weekStats[wd].xp += (c.xpEarned || 0);
              weeklyTotalSeries += (c.completedSeries || 0);
              weeklyTotalXP += (c.xpEarned || 0);
              
              if (c.isCompleted === 1) weekCounts[wd] = (weekCounts[wd] || 0) + 1;
            }
          }
          const weeklyProgress = [
            { day: "Lun", series: weekStats[0].series, xp: weekStats[0].xp },
            { day: "Mar", series: weekStats[1].series, xp: weekStats[1].xp },
            { day: "Mié", series: weekStats[2].series, xp: weekStats[2].xp },
            { day: "Jue", series: weekStats[3].series, xp: weekStats[3].xp },
            { day: "Vie", series: weekStats[4].series, xp: weekStats[4].xp },
            { day: "Sáb", series: weekStats[5].series, xp: weekStats[5].xp },
            { day: "Dom", series: weekStats[6].series, xp: weekStats[6].xp },
          ];

          // Fitness Stats
          const progress = await db.getUserProgress(ctx.user.id);
          const fitnessStats = {
             weeklyTotalSeries,
             weeklyTotalXP,
             totalWorkouts: allChecklists.filter((c: any) => c.isCompleted === 1).length,
             streak: progress?.streak || 0,
             level: progress?.level || 1,
          };
          
          // Get key exercises progress
          const ehRecords = await database.select().from(exerciseHistory).where(eq(exerciseHistory.userId, ctx.user.id)).orderBy(exerciseHistory.completedAt);
          // Group by exercise name
          const exerciseData: Record<string, any[]> = {};
          for (const eh of ehRecords) {
             if (eh.isCompleted === 1 && eh.weight && eh.weight > 0) {
                 if (!exerciseData[eh.exerciseName]) exerciseData[eh.exerciseName] = [];
                 exerciseData[eh.exerciseName].push({ date: eh.completedAt, weight: eh.weight, reps: eh.completedReps });
             }
          }
          // Get top 2 exercises with most data points
          const sortedExercises = Object.entries(exerciseData)
             .filter(([name, data]) => data.length >= 2)
             .sort((a, b) => b[1].length - a[1].length)
             .slice(0, 2);
          
          const keyExercisesProgress = sortedExercises.map(([name, data]) => {
             const maxWeight = Math.max(...data.map(d => d.weight));
             const maxReps = Math.max(...data.map(d => {
                const repsMatch = (d.reps || "").toString().match(/\d+/);
                return repsMatch ? parseInt(repsMatch[0]) : 0;
             }));
             return {
                name,
                maxWeight,
                maxReps,
                data: data.slice(-5).map(d => d.weight) // last 5 sessions
             };
          });

          const weeklyChart = [
            { day: "Lun", count: weekCounts[0] },
            { day: "Mar", count: weekCounts[1] },
            { day: "Mié", count: weekCounts[2] },
            { day: "Jue", count: weekCounts[3] },
            { day: "Vie", count: weekCounts[4] },
            { day: "Sáb", count: weekCounts[5] },
            { day: "Dom", count: weekCounts[6] },
          ];

          // Recent workouts: last 3 completed checklists
          const completed = allChecklists
            .filter((c: any) => c.isCompleted === 1)
            .sort((a: any, b: any) => new Date(b.date).getTime() - new Date(a.date).getTime())
            .slice(0, 3);

          const plan = await db.getActiveTrainingPlan(ctx.user.id);
          let planContent: any = null;
          if (plan?.generatedContent) {
            try { planContent = JSON.parse(plan.generatedContent); } catch {}
          }

          const recentWorkouts = completed.map((c: any, i: number) => {
            const daysAgo = Math.floor((now.getTime() - new Date(c.date).getTime()) / (1000 * 60 * 60 * 24));
            const dayLabel = daysAgo === 0 ? "Hoy" : daysAgo === 1 ? "Ayer" : `Hace ${daysAgo} días`;
            const dayIndex = (new Date(c.date).getDay() + 6) % 7;
            const dayPlan = planContent?.days?.[dayIndex];
            const focus = dayPlan?.focus || "Entrenamiento completo";
            return {
              id: c.id,
              name: focus,
              type: plan?.type === "strength" ? "Rutina de fuerza" : "Rutina de hipertrofia",
              date: dayLabel,
              completedSeries: c.completedSeries,
              totalSeries: c.totalSeries,
              xpEarned: c.xpEarned || 0,
            };
          });

          // Activity feed: up to 3 milestone items
          const totalWorkouts = fitnessStats.totalWorkouts;
          const activityItems: { icon: string; title: string; description: string; time: string }[] = [];

          if (progress) {
            if (progress.streak && progress.streak >= 3) {
              activityItems.push({ icon: "flame", title: `¡Racha de ${progress.streak} días!`, description: "Seguís entrenando sin parar", time: "Hoy" });
            }
            if (progress.level && progress.level > 1) {
              activityItems.push({ icon: "trophy", title: `Nivel ${progress.level} alcanzado`, description: `Lograste ${progress.totalXP} XP en total`, time: "Reciente" });
            }
          }
          if (totalWorkouts >= 1) {
            activityItems.push({ icon: "dumbbell", title: `${totalWorkouts} entrenamiento${totalWorkouts > 1 ? "s" : ""} completado${totalWorkouts > 1 ? "s" : ""}`, description: "Seguís construyendo tu mejor versión", time: "Reciente" });
          }
          if (plan) {
            activityItems.push({ icon: "zap", title: "Plan activo", description: `Rutina de ${plan.daysPerWeek} días por semana en curso`, time: "Activo" });
          }
          // Default items if not enough
          if (activityItems.length === 0) {
            activityItems.push({ icon: "star", title: "¡Bienvenido a FerFit!", description: "Comenzá tu viaje fitness", time: "Hoy" });
            activityItems.push({ icon: "user", title: "Perfil creado", description: "Configuración inicial completada", time: "Hoy" });
            activityItems.push({ icon: "target", title: "Objetivo establecido", description: "Definí tu objetivo principal", time: "Hoy" });
          }

          return {
            weeklyChart,
            weeklyProgress,
            fitnessStats,
            keyExercisesProgress,
            recentWorkouts,
            activityFeed: activityItems.slice(0, 3),
          };
        } catch (error) {
          console.error("[getDashboardData] Error:", error);
          return { weeklyChart: [], recentWorkouts: [], activityFeed: [] };
        }
      }),

      getAITips: protectedProcedure.query(async ({ ctx }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        try {
          const progress = await db.getUserProgress(ctx.user.id);
          const allChecklists = await db.getUserChecklists(ctx.user.id);
          const plan = await db.getActiveTrainingPlan(ctx.user.id);
          const totalWorkouts = allChecklists.filter((c: any) => c.isCompleted === 1).length;

          let planContent: any = null;
          if (plan?.generatedContent) {
            try { planContent = JSON.parse(plan.generatedContent); } catch {}
          }

          const userContext = `
El usuario tiene los siguientes datos:
- XP Total: ${progress?.totalXP || 0}
- Nivel: ${progress?.level || 1}
- Racha actual: ${progress?.streak || 0} días consecutivos
- Total de entrenamientos completados: ${totalWorkouts}
- Series completadas históricamente: ${progress?.seriesCompletedHistorically || 0}
- Tiene plan activo: ${plan ? "Sí" : "No"}
- Días por semana entrenados: ${plan?.daysPerWeek || 0}
- Objetivo: ${planContent?.objective || "no especificado"}
`;

          const prompt = `Eres un entrenador personal experto y nutricionista. Basándote en el perfil del usuario, generá exactamente 3 consejos personalizados, concisos y motivadores.

${userContext}

Devolvé SOLO un JSON válido con este formato exacto, sin texto adicional:
{
  "tips": [
    { "icon": "droplets", "title": "Título corto", "description": "Descripción de 1-2 oraciones" },
    { "icon": "moon", "title": "Título corto", "description": "Descripción de 1-2 oraciones" },
    { "icon": "zap", "title": "Título corto", "description": "Descripción de 1-2 oraciones" }
  ]
}

Los iconos disponibles son: droplets, moon, zap, flame, apple, heart, activity, trophy, target, dumbbell, star, shield.
Personalizá los consejos según el nivel y comportamiento real del usuario.`;

          const result = await invokeLLM({
            messages: [
              { role: "system", content: "Eres un entrenador personal experto. Responde SOLO con JSON válido, sin markdown ni texto adicional." },
              { role: "user", content: prompt },
            ],
          });
          const content = result.choices[0]?.message.content;
          const rawText = typeof content === "string" ? content : JSON.stringify(content);
          const jsonMatch = rawText.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            const parsed = JSON.parse(jsonMatch[0]);
            if (parsed.tips && Array.isArray(parsed.tips)) {
              return { tips: parsed.tips };
            }
          }
          // Fallback tips
          return {
            tips: [
              { icon: "droplets", title: "Hidratate", description: "Recordá tomar al menos 2L de agua al día para optimizar tu rendimiento." },
              { icon: "moon", title: "Descansá bien", description: "Dormí 7-8 horas para una mejor recuperación muscular." },
              { icon: "zap", title: "Constancia es clave", description: "La clave está en la consistencia diaria, no en la intensidad puntual." },
            ],
          };
        } catch (error) {
          console.error("[getAITips] Error:", error);
          return {
            tips: [
              { icon: "droplets", title: "Hidratate", description: "Recordá tomar al menos 2L de agua al día." },
              { icon: "moon", title: "Descansá bien", description: "Dormí 7-8 horas para mejor recuperación." },
              { icon: "zap", title: "Constancia es clave", description: "La clave está en la consistencia diaria." },
            ],
          };
        }
      }),
  }),
  gamification: router({
    getDailyQuests: protectedProcedure.query(async ({ ctx }) => {
      if (!ctx.user) throw new Error("Not authenticated");
      const quests = await getOrGenerateTodayQuests(ctx.user.id);
      const notifications = buildChallengeNotifications(quests);
      return { quests, notifications };
    }),
    claimQuest: protectedProcedure
      .input(z.object({ questId: z.number() }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        return claimQuestReward(ctx.user.id, input.questId);
      }),
    submitCameraProof: protectedProcedure
      .input(
        z.object({
          questId: z.number(),
          durationSec: z.number().optional(),
          note: z.string().max(200).optional(),
          clientVerified: z.boolean().optional(),
        })
      )
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        return submitCameraProof(ctx.user.id, input.questId, {
          durationSec: input.durationSec,
          note: input.note,
          clientVerified: input.clientVerified,
        });
      }),
    gradeBattle: protectedProcedure
      .input(
        z.object({
          questId: z.number(),
          villainId: z.string(),
          deviceReps: z.number().optional(),
          durationSec: z.number().optional(),
          framesBase64: z.array(z.string()).max(6).optional(),
          note: z.string().max(200).optional(),
        })
      )
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        const { gradeBattleChallenge } = await import("./_core/battleGrade");
        return gradeBattleChallenge({
          userId: ctx.user.id,
          questId: input.questId,
          villainId: input.villainId,
          deviceReps: input.deviceReps,
          durationSec: input.durationSec,
          framesBase64: input.framesBase64,
          note: input.note,
        });
      }),
    getLeagueLeaderboard: protectedProcedure.query(async ({ ctx }) => {
      if (!ctx.user) throw new Error("Not authenticated");
      return {
        leagueName: "Liga Bronce",
        users: [
          { id: 1, name: "Maria", xp: 1200 },
          { id: ctx.user.id, name: ctx.user.name, xp: 850 },
          { id: 2, name: "Juan", xp: 450 },
        ]
      };
    }),

    // ─── FUNCIONALIDAD 5: Notificación motivacional dinámica ───────────────
    getMotivationalQuote: protectedProcedure.query(async ({ ctx }) => {
      if (!ctx.user) throw new Error("Not authenticated");
      try {
        const progress = await db.getUserProgress(ctx.user.id);
        const streak = progress?.streak ?? 0;
        const level = progress?.level ?? 1;
        const name = ctx.user.name?.split(" ")[0] || "campeón";
        const today = new Date();
        const dayName = ["Domingo","Lunes","Martes","Miércoles","Jueves","Viernes","Sábado"][today.getDay()];
        const systemPrompt = `Sos Feo, entrenador personal de FerFit. Tono profesional, motivador y claro (español rioplatense sin groserías). UNA sola oración, máximo 120 caracteres.`;
        const userPrompt = `Hoy es ${dayName}. Cliente: ${name}, nivel ${level}, racha ${streak} días. Mensaje breve para que complete su sesión con buena técnica.`;
        const result = await invokeLLM({
          messages: [
            { role: "system", content: systemPrompt },
            { role: "user", content: userPrompt },
          ],
          maxTokens: 80,
        });
        const text = (result as any).choices?.[0]?.message?.content || `¡${name}, hoy es día de mover el esqueleto! 🔥`;
        return { quote: String(text).trim() };
      } catch (e) {
        return { quote: `¡Hoy es tu día, dale que podés! 💪🔥` };
      }
    }),
  }),

  social: router({
    getFriendsFeed: protectedProcedure.query(async ({ ctx }) => {
      if (!ctx.user) throw new Error("Not authenticated");
      return [
        { id: 1, user: "Matias", action: "alcanzó el Nivel 5", time: "Hace 2h", highFives: 2 },
        { id: 2, user: "Sofi", action: "completó un entrenamiento", time: "Hace 4h", highFives: 5 },
      ];
    }),
  }),
  exercise: exerciseRouter,

  // ─── FUNCIONALIDAD 1: Chat con la mascota Feo ─────────────────────────
  feo: router({
    chatWithFeo: protectedProcedure
      .input(z.object({
        message: z.string().min(1).max(1000),
        history: z.array(z.object({
          role: z.enum(["user", "assistant"]),
          content: z.string(),
        })).optional(),
      }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        try {
          const progress = await db.getUserProgress(ctx.user.id);
          const streak = progress?.streak ?? 0;
          const level = progress?.level ?? 1;
          const coins = progress?.coins ?? 0;
          const name = ctx.user.name?.split(" ")[0] || "amigo";

          // Obtener plan activo para contexto
          let planContext = "";
          try {
            const plan = await db.getActiveTrainingPlan(ctx.user.id);
            if (plan?.generatedContent) {
              const content = typeof plan.generatedContent === "string"
                ? JSON.parse(plan.generatedContent)
                : plan.generatedContent;
              const obj = content?.objective || "";
              const days = content?.daysPerWeek || 0;
              planContext = `El usuario tiene una rutina activa de ${days} días/semana con objetivo de ${obj}.`;
            }
          } catch {}

          const systemPrompt = `Sos Feo, el entrenador personal de FerFit (mascota rayo verde). Tono profesional, claro y motivador — como un PT certificado, no un meme.
- Español rioplatense correcto ("vos", "dale") sin groserías ni infantilizar al cliente.
- Priorizá técnica, progresión, recuperación y prevención de lesiones.
- Mensajes concretos: qué hacer, por qué, y un ajuste si hace falta.
- Podés ser cálido y directo, pero siempre respetuoso.
- Emojis con moderación (máximo 1–2). Respondé en 2–4 oraciones.

REGLAS DE SEGURIDAD EXTREMA (CRÍTICO):
- NUNCA recomiendes ejercicios peligrosos, cargas extremas o ignorar el dolor.
- Si el usuario reporta dolor, molestia aguda o fatiga extrema, OBLÍGALO a descansar o consultar a un médico.
- La prevención de lesiones es tu prioridad número uno.
- Si el usuario sugiere hacer una locura, retalo con humor pero dejale claro que NO debe hacerlo.

CONTEXTO DEL USUARIO:
- Nombre: ${name}
- Nivel: ${level}
- Racha: ${streak} días
- FerCoins: ${coins}
${planContext}

Si te preguntan algo que no sea de fitness/nutrición, deciles que eso no es tu área y los redirigís al entrenamiento.`;


          const history = (input.history || []).map((m) => ({
            role: m.role as "user" | "assistant",
            content: m.content,
          }));

          const result = await invokeLLM({
            messages: [
              { role: "system", content: systemPrompt },
              ...history,
              { role: "user", content: input.message },
            ],
            maxTokens: 300,
          });

          const reply = (result as any).choices?.[0]?.message?.content
            || "Estoy con vos. Decime cómo te sentís hoy y ajustamos la sesión.";
          
          await progressQuest(ctx.user.id, "talk_to_feo", 1);
          
          return { reply: String(reply).trim() };
        } catch (e) {
          console.error("[chatWithFeo] Error:", e);
          return {
            reply:
              "Tuve un fallo técnico. Mientras tanto: priorizá técnica limpia y no fuerces si hay dolor agudo.",
          };
        }
      }),
  }),

  store: router({
    getInventory: protectedProcedure.query(async ({ ctx }) => {
      if (!ctx.user) throw new Error("Not authenticated");
      const progress = await db.getUserProgress(ctx.user.id);
      if (!progress) return { coins: 0, unlockedSkins: [], equippedSkin: null, catalog: [] };
      
      let unlockedSkins: string[] = [];
      try {
        if (progress.unlockedSkins) unlockedSkins = JSON.parse(progress.unlockedSkins);
      } catch (e) {}

      // Import STORE_CATALOG dynamically to avoid circular dependencies
      const { STORE_CATALOG } = await import("./_core/store");
      
      return {
        coins: progress.coins || 0,
        unlockedSkins,
        equippedSkin: progress.equippedSkin,
        catalog: STORE_CATALOG,
      };
    }),
    
    buyItem: protectedProcedure
      .input(z.object({ itemId: z.string() }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        const progress = await db.getUserProgress(ctx.user.id);
        if (!progress) throw new Error("No progress found");
        
        const { STORE_CATALOG } = await import("./_core/store");
        const item = STORE_CATALOG.find(i => i.id === input.itemId);
        if (!item) throw new Error("Item not found");
        
        if ((progress.coins || 0) < item.price) {
          throw new Error("Not enough FerCoins");
        }
        
        let unlockedSkins: string[] = [];
        try {
          if (progress.unlockedSkins) unlockedSkins = JSON.parse(progress.unlockedSkins);
        } catch (e) {}
        
        if (item.type === "skin" && unlockedSkins.includes(item.id)) {
          throw new Error("Skin already owned");
        }
        
        const database = await getDb();
        
        const newCoins = (progress.coins || 0) - item.price;
        if (item.type === "skin") {
          unlockedSkins.push(item.id);
          await database.update(userProgress).set({
            coins: newCoins,
            unlockedSkins: JSON.stringify(unlockedSkins),
          }).where(eq(userProgress.userId, ctx.user.id));
        } else {
          // It's a utility, maybe add a row to user_items or just deduct coins for now
          await database.update(userProgress).set({
            coins: newCoins,
          }).where(eq(userProgress.userId, ctx.user.id));
        }
        
        return { success: true, newBalance: newCoins };
      }),
      
    equipItem: protectedProcedure
      .input(z.object({ itemId: z.string().nullable() }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        const progress = await db.getUserProgress(ctx.user.id);
        if (!progress) throw new Error("No progress found");
        
        let unlockedSkins: string[] = [];
        try {
          if (progress.unlockedSkins) unlockedSkins = JSON.parse(progress.unlockedSkins);
        } catch (e) {}
        
        if (input.itemId !== null && !unlockedSkins.includes(input.itemId)) {
          throw new Error("Skin not owned");
        }
        
        const database = await getDb();
        await database.update(userProgress).set({
          equippedSkin: input.itemId,
        }).where(eq(userProgress.userId, ctx.user.id));
        
        return { success: true, equippedSkin: input.itemId };
      }),
  }),
  nutrition: router({
    // ─── FUNCIONALIDAD 2: Carga inteligente de alimentos por texto libre ───
    smartLog: protectedProcedure
      .input(z.object({
        description: z.string().min(3).max(1000),
      }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        const systemPrompt = `Sos un nutricionista experto. El usuario te va a describir en texto libre lo que comió. Devolvés ÚNICAMENTE un JSON con la siguiente estructura sin ningún texto extra:
{
  "foods": [
    { "name": "string (nombre del alimento en español)", "quantity": number, "unit": "string (g, ml, unidad, taza, etc.)", "calories": number, "protein": number, "carbs": number, "fats": number }
  ],
  "totalCalories": number,
  "totalProtein": number,
  "totalCarbs": number,
  "totalFats": number
}
Las macros deben ser en gramos. Estimá cantidades realistas si no se mencionan.`;
        try {
          const result = await invokeLLM({
            messages: [
              { role: "system", content: systemPrompt },
              { role: "user", content: `Lo que comí: ${input.description}` },
            ],
            maxTokens: 600,
            responseFormat: { type: "json_object" },
          });
          const raw = (result as any).choices?.[0]?.message?.content || "{}";
          const parsed = JSON.parse(raw);
          return { success: true, data: parsed };
        } catch (e) {
          console.error("[smartLog] Error:", e);
          throw new Error("No se pudo analizar la comida. Intentá describir con más detalle.");
        }
      }),

    // ─── FUNCIONALIDAD 4: Recetas con ingredientes disponibles ─────────────
    generateFridgeRecipe: protectedProcedure
      .input(z.object({
        ingredients: z.string().min(3).max(500),
        macrosLeft: z.object({
          calories: z.number().optional(),
          protein: z.number().optional(),
          carbs: z.number().optional(),
          fats: z.number().optional(),
        }).optional(),
      }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        const macroHint = input.macrosLeft
          ? `El usuario le quedan aprox. ${input.macrosLeft.calories ?? "?"} kcal, ${input.macrosLeft.protein ?? "?"} g de proteína, ${input.macrosLeft.carbs ?? "?"} g de carbs y ${input.macrosLeft.fats ?? "?"} g de grasas para el día.`
          : "";
        const systemPrompt = `Sos un chef nutricionista. El usuario tiene ciertos ingredientes disponibles. Creá UNA receta rápida, saludable y deliciosa usando solo esos ingredientes (podés asumir que tiene sal, aceite y especias básicas). Devolvés SOLO JSON:
{
  "title": "string",
  "prepTime": "string (ej: 10 minutos)",
  "ingredients": ["string"],
  "steps": ["string"],
  "macros": { "calories": number, "protein": number, "carbs": number, "fats": number },
  "tip": "string (consejo de Feo el entrenador en tono gracioso)"
}`;
        try {
          const result = await invokeLLM({
            messages: [
              { role: "system", content: systemPrompt },
              { role: "user", content: `Ingredientes disponibles: ${input.ingredients}. ${macroHint}` },
            ],
            maxTokens: 800,
            responseFormat: { type: "json_object" },
          });
          const raw = (result as any).choices?.[0]?.message?.content || "{}";
          const parsed = JSON.parse(raw);
          return { success: true, recipe: parsed };
        } catch (e) {
          console.error("[generateFridgeRecipe] Error:", e);
          throw new Error("No se pudo generar la receta. Intentá de nuevo.");
        }
      }),
    logMeal: protectedProcedure
      .input(z.object({
        trainingPlanId: z.number(),
        date: z.date(),
        mealNumber: z.number(),
        consumed: z.boolean(),
        notes: z.string().optional(),
      }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        const result = await db.logMeal(
          ctx.user.id,
          input.trainingPlanId,
          input.date,
          input.mealNumber,
          input.consumed,
          input.notes
        );
        if (input.consumed) {
          await db.updateUserProgress(ctx.user.id, 5, 1);
        }
        return result;
      }),

    unlogMeal: protectedProcedure
      .input(z.object({
        trainingPlanId: z.number(),
        date: z.date(),
        mealNumber: z.number(),
      }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        const result = await db.logMeal(
          ctx.user.id,
          input.trainingPlanId,
          input.date,
          input.mealNumber,
          false
        );
        return result;
      }),

    getDailyNutrition: protectedProcedure
      .input(z.object({
        trainingPlanId: z.number(),
        date: z.date().optional(),
      }))
      .query(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        const date = input.date || new Date();
        const logs = await db.getMealLogsForDate(ctx.user.id, input.trainingPlanId, date);
        return {
          date,
          logs: logs.map((log: any) => ({
            mealNumber: log.mealNumber,
            consumed: log.consumed === 1,
            notes: log.notes,
          })),
        };
      }),

    getAdherence: protectedProcedure
      .input(z.object({
        trainingPlanId: z.number(),
        days: z.number().default(7),
      }))
      .query(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        const endDate = new Date();
        const startDate = new Date();
        startDate.setDate(endDate.getDate() - input.days);
        const logs = await db.getMealLogsForDateRange(ctx.user.id, input.trainingPlanId, startDate, endDate);
        const consumed = logs.filter((log: any) => log.consumed === 1).length;
        const total = logs.length;
        return {
          consumed,
          total,
          percentage: total > 0 ? Math.round((consumed / total) * 100) : 0,
        };
      }),

    generateMealImage: protectedProcedure
      .input(z.object({
        mealNumber: z.number(),
        mealName: z.string(),
        foods: z.string(),
      }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        try {
          const { ENV } = await import("./_core/env");
          if (!ENV.forgeApiUrl || !ENV.forgeApiKey) {
            return {
              success: false,
              url: null,
              error: "Servicio de imagenes no configurado. Verifica BUILT_IN_FORGE_API_URL y BUILT_IN_FORGE_API_KEY en el .env.",
            };
          }
          const { generateImage } = await import("./_core/imageGeneration");
          const prompt = `Fotografia cenital de un plato de comida conteniendo exactamente: ${input.foods}. Composicion: plato blanco minimalista sobre mesa de madera clara, iluminacion natural desde arriba (cenital), estilo food photography profesional, colores vibrantes y naturales de los alimentos, 4k, hiperrealista, detalles texturados visibles`;
          const { url } = await generateImage({ prompt });
          return { success: true, url };
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);
          console.error("[generateMealImage] Error:", message);
          return { success: false, url: null, error: message };
        }
      }),

    createPlan: protectedProcedure
      .input(z.object({
        age: z.number().min(10).max(120),
        weight: z.number().min(20).max(300),
        height: z.number().min(100).max(250),
        gender: z.enum(["male", "female"]),
        activityLevel: z.enum(["sedentary", "light", "moderate", "active", "very_active"]),
        objective: z.enum(["fat_loss", "muscle_gain", "maintenance", "general_health"]),
        mealFrequency: z.union([z.literal(3), z.literal(4), z.literal(5), z.literal(6)]),
        dietaryRestrictions: z.array(z.string()).default([]),
        foodPreferences: z.array(z.string()).default([]),
        foodDislikes: z.array(z.string()).default([]),
        prepTime: z.enum(["<15min", "15-30min", "30-60min", ">60min"]).optional(),
        budget: z.enum(["budget", "medium", "premium"]).optional(),
        trainingPlanId: z.number().optional(),
      }))
      .mutation(async ({ ctx, input }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        try {
          const { generateNutritionPlan } = await import("./_core/NutritionPlanGenerator");
          const plan = generateNutritionPlan({
            age: input.age,
            weight: input.weight,
            height: input.height,
            gender: input.gender,
            activityLevel: input.activityLevel,
            objective: input.objective,
            mealFrequency: input.mealFrequency,
            dietaryRestrictions: input.dietaryRestrictions,
            foodPreferences: input.foodPreferences,
            foodDislikes: input.foodDislikes,
            prepTime: input.prepTime,
            budget: input.budget,
          });
          const content = JSON.stringify(plan);
          const result = await db.createNutritionPlan(ctx.user.id, content, input.trainingPlanId);
          return { success: true, plan, planId: result.insertId };
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);
          console.error("[nutrition.createPlan] Error:", message);
          return { success: false, error: message };
        }
      }),

    getActivePlan: protectedProcedure
      .query(async ({ ctx }) => {
        if (!ctx.user) throw new Error("Not authenticated");
        try {
          const plan = await db.getActiveNutritionPlan(ctx.user.id);
          if (!plan) return { hasPlan: false, plan: null };
          const content = typeof plan.generatedContent === "string"
            ? JSON.parse(plan.generatedContent)
            : plan.generatedContent;
          return { hasPlan: true, plan: content, planId: plan.id };
        } catch (error) {
          console.error("[nutrition.getActivePlan] Error:", error);
          return { hasPlan: false, plan: null };
        }
      }),
  }),
  /**
    * Alertas estilo Duolingo: "te extrañamos", racha en riesgo, cerca de objetivos.
    * Usado por web y por Flutter (también expuesto en /api/mobile/engagement/alerts).
    */
  engagement: router({
    getAlerts: protectedProcedure.query(async ({ ctx }) => {
      if (!ctx.user) throw new Error("Not authenticated");

      let progress = await db.getUserProgress(ctx.user.id);
      if (!progress) {
        await db.createUserProgress(ctx.user.id);
        progress = await db.getUserProgress(ctx.user.id);
      }

      const plan = await db.getActiveTrainingPlan(ctx.user.id);
      const checklist = await db.getTodayChecklist(ctx.user.id);

      const totalSeries = (checklist as any)?.totalSeries ?? 0;
      const completedSeries = (checklist as any)?.completedSeries ?? 0;
      const hasTrainingToday = totalSeries > 0 || Boolean((checklist as any)?.hasTrainingToday);
      const todayCompleted = (checklist as any)?.isCompleted === 1;
      const todayProgressRatio =
        totalSeries > 0 ? Math.min(1, completedSeries / totalSeries) : 0;

      return buildEngagement({
        hasActivePlan: Boolean(plan),
        daysPerWeek: plan?.daysPerWeek || 3,
        totalXP: progress?.totalXP || 0,
        level: progress?.level || 1,
        streak: progress?.streak || 0,
        lastWorkoutDate: progress?.lastWorkoutDate ?? null,
        hasTrainingToday,
        todayCompleted,
        todayProgressRatio,
        userName: ctx.user.name || ctx.user.email || null,
      });
    }),
  })
});

export type AppRouter = typeof appRouter;

/* ─── HELPERS ────────────────────────────────────────────── */

function calculateTDEE(
  age: number,
  weight: number,
  height: number,
  daysPerWeek: number,
  gender?: string,
  activityLevel?: string
): number {
  const isFemale = gender?.toLowerCase() === "female" || gender?.toLowerCase() === "femenino";
  const bmr = 10 * weight + 6.25 * height - 5 * age + (isFemale ? -161 : 5);

  let multiplier = 1.375; // light activity default
  if (activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case "sedentary":
      case "sedentario":
        multiplier = 1.2;
        break;
      case "light":
      case "ligero":
        multiplier = 1.375;
        break;
      case "moderate":
      case "moderado":
        multiplier = 1.55;
        break;
      case "active":
      case "activo":
        multiplier = 1.725;
        break;
      case "very_active":
      case "muy_activo":
        multiplier = 1.9;
        break;
    }
  } else {
    const activityMultipliers: Record<number, number> = { 2: 1.2, 3: 1.375, 4: 1.55, 5: 1.725, 6: 1.725 };
    multiplier = activityMultipliers[daysPerWeek] || 1.55;
  }

  return Math.round(bmr * multiplier);
}

function calculateMacros(objective: string, weight: number, tdee: number) {
  let calories = tdee;
  if (objective === "hypertrophy") calories = tdee + 300;
  else if (objective === "fat_loss") calories = tdee - 400;
  else if (objective === "recomposition") calories = tdee;
  const protein = Math.round(weight * 2.2);
  const fats = Math.round((calories * 0.25) / 9);
  const carbs = Math.round((calories - protein * 4 - fats * 9) / 4);
  return { protein, carbs, fats };
}

const EQUIPMENT_MAP: Record<string, string> = {
  full_gym: "gimnasio completo con máquinas, barras, mancuernas y poleas",
  dumbbells: "solo mancuernas (sin máquinas ni barras)",
  bodyweight: "solo peso corporal, sin equipamiento",
  limited: "equipo limitado (bandas elásticas, mancuernas ligeras)",
};

const OBJECTIVE_MAP: Record<string, string> = {
  hypertrophy: "hipertrofia muscular (ganar músculo)",
  strength: "fuerza máxima (sentadilla, press, peso muerto)",
  fat_loss: "pérdida de grasa (déficit calórico, cardio incluido)",
  recomposition: "recomposición corporal (ganar músculo y perder grasa simultáneamente)",
};

const LEVEL_MAP: Record<string, string> = {
  beginner: "principiante (menos de 1 año entrenando, ejercicios básicos, bajo volumen)",
  intermediate: "intermedio (1-3 años, puede usar técnicas avanzadas moderadas)",
  advanced: "avanzado (más de 3 años, puede usar periodización compleja)",
};

export function validateGeneratedPlan(plan: any, input: any) {
  const injuries = (input.injuries || "").toLowerCase();
  const equipment = input.equipment || "full_gym";

  const hasLegInjury = ["rodilla", "tobillo", "pie", "cadera", "pierna", "knee", "ankle", "foot", "hip", "leg"].some(term => injuries.includes(term));
  const hasShoulderInjury = ["hombro", "muñeca", "codo", "brazo", "shoulder", "wrist", "elbow", "arm"].some(term => injuries.includes(term));
  const hasBackInjury = ["espalda", "lumbar", "columna", "back", "spine"].some(term => injuries.includes(term));

  const BODYWEIGHT_REPLACEMENTS: Record<string, { name: string; notes?: string }> = {
    "bench press": { name: "Push-up", notes: "Versión peso corporal" },
    "dumbbell press": { name: "Push-up", notes: "Versión peso corporal" },
    "dumbbell bench press": { name: "Push-up", notes: "Versión peso corporal" },
    "barbell squat": { name: "Bodyweight Squat", notes: "Sentadilla con peso corporal" },
    "goblet squat": { name: "Bodyweight Squat", notes: "Sentadilla con peso corporal" },
    "dumbbell goblet squat": { name: "Bodyweight Squat", notes: "Sentadilla con peso corporal" },
    "leg press": { name: "Air Squat", notes: "Sentadilla con peso corporal" },
    "overhead press": { name: "Pike Push-up", notes: "Flexiones en pica" },
    "dumbbell overhead press": { name: "Pike Push-up", notes: "Flexiones en pica" },
    "dumbbell shoulder press": { name: "Pike Push-up", notes: "Flexiones en pica" },
    "bent over rows": { name: "Inverted Row", notes: "Usa una mesa o baranda" },
    "dumbbell row": { name: "Inverted Row", notes: "Usa una mesa o baranda" },
    "lat pulldown": { name: "Pull-up", notes: "Si no tienes barra de dominadas, haz Inverted Row" },
    "cable flyes": { name: "Push-up", notes: "Enfoque en contracción de pecho" },
    "rope pushdown": { name: "Bench Dips", notes: "Fondos en banco o silla" },
    "tricep dips": { name: "Bench Dips", notes: "Fondos en banco o silla" },
    "barbell curls": { name: "Chin-up", notes: "Dominadas con agarre supino" },
    "dumbbell curls": { name: "Chin-up", notes: "Dominadas con agarre supino" },
    "hammer curls": { name: "Chin-up", notes: "Dominadas con agarre supino" },
    "barbell deadlift": { name: "Single-leg Glute Bridge", notes: "Puente de glúteo a una pierna" },
    "dumbbell deadlift": { name: "Single-leg Glute Bridge", notes: "Puente de glúteo a una pierna" },
    "romanian deadlift": { name: "Single-leg Romanian Deadlift (Bodyweight)", notes: "Peso muerto rumano sin peso" },
    "dumbbell romanian deadlift": { name: "Single-leg Romanian Deadlift (Bodyweight)", notes: "Peso muerto rumano sin peso" },
    "lying leg curl": { name: "Glute Bridge", notes: "Puente de glúteo" },
    "leg curl": { name: "Glute Bridge", notes: "Puente de glúteo" },
    "leg extensions": { name: "Bodyweight Squat", notes: "Sentadilla con peso corporal" },
    "incline dumbbell press": { name: "Decline Push-up", notes: "Flexión declinada (pies elevados)" },
    "lateral raise": { name: "Arm Circles", notes: "Círculos con brazos estirados" },
    "dumbbell lateral raise": { name: "Arm Circles", notes: "Círculos con brazos estirados" }
  };

  const DUMBBELL_REPLACEMENTS: Record<string, { name: string; notes?: string }> = {
    "bench press": { name: "Dumbbell Bench Press", notes: "Versión con mancuernas" },
    "barbell squat": { name: "Dumbbell Goblet Squat", notes: "Sentadilla Goblet con mancuerna" },
    "barbell deadlift": { name: "Dumbbell Deadlift", notes: "Peso muerto con mancuernas" },
    "bent over rows": { name: "Dumbbell Row", notes: "Remo con mancuernas" },
    "lat pulldown": { name: "Dumbbell Row", notes: "Remo con mancuernas" },
    "overhead press": { name: "Dumbbell Shoulder Press", notes: "Prensa militar con mancuernas" },
    "tricep dips": { name: "Dumbbell Kickbacks", notes: "Patada de tríceps con mancuerna" },
    "cable flyes": { name: "Dumbbell Flyes", notes: "Aperturas con mancuernas" },
    "barbell curls": { name: "Dumbbell Curl", notes: "Curl de bíceps con mancuernas" }
  };

  const LOWER_BODY_EXERCISES = [
    "squat", "lunge", "deadlift", "leg press", "leg curl", "leg extension", "calf raise", "step-up", "thruster", "calf",
    "glute bridge", "hip thrust", "wall sit"
  ];
  const PRESSING_EXERCISES = [
    "bench press", "overhead press", "shoulder press", "push-up", "dips", "handstand", "pike push-up"
  ];

  const CORE_REPLACEMENTS = [
    { name: "Plank", muscleGroup: "Core", sets: 3, reps: "30-60s", restSeconds: 60, notes: "Activa el core", technique: "Cuerpo recto", alternatives: ["Side Plank"] },
    { name: "Dead Bug", muscleGroup: "Core", sets: 3, reps: "12 por lado", restSeconds: 45, notes: "Lento y controlado", technique: "Espalda plana", alternatives: ["Bird Dog"] },
    { name: "Bird Dog", muscleGroup: "Core", sets: 3, reps: "12 por lado", restSeconds: 45, notes: "Estabilidad lumbar", technique: "Sin balanceo", alternatives: ["Dead Bug"] },
    { name: "Abdominal Crunch", muscleGroup: "Abdomen", sets: 3, reps: "15-20", restSeconds: 45, notes: "Tensión en abdomen", technique: "No tires del cuello", alternatives: ["Russian Twists"] }
  ];

  const SHOULDER_REPLACEMENTS = [
    { name: "Plank", muscleGroup: "Core", sets: 3, reps: "30-60s", restSeconds: 60, notes: "Apóyate en antebrazos", technique: "Core activo", alternatives: ["Dead Bug"] },
    { name: "Abdominal Crunch", muscleGroup: "Abdomen", sets: 3, reps: "15-20", restSeconds: 45, notes: "Lento y controlado", technique: "Fuerza en abdomen", alternatives: ["Russian Twists"] },
    { name: "Lying Leg Raise", muscleGroup: "Abdomen", sets: 3, reps: "12-15", restSeconds: 60, notes: "Espalda apoyada", technique: "Controla bajada", alternatives: ["Plank"] }
  ];

  let coreIdx = 0;
  let shoulderIdx = 0;

  for (const day of plan.days || []) {
    day.exercises = (day.exercises || []).map((exercise: any) => {
      let nameLower = (exercise.name || "").toLowerCase().trim();

      // 1. Reemplazo de equipamiento
      if (equipment === "bodyweight" || equipment === "limited") {
        if (BODYWEIGHT_REPLACEMENTS[nameLower]) {
          const repl = BODYWEIGHT_REPLACEMENTS[nameLower];
          exercise.name = repl.name;
          exercise.notes = (exercise.notes || "") + ` (${repl.notes})`;
          nameLower = repl.name.toLowerCase();
        }
      } else if (equipment === "dumbbells") {
        if (DUMBBELL_REPLACEMENTS[nameLower]) {
          const repl = DUMBBELL_REPLACEMENTS[nameLower];
          exercise.name = repl.name;
          exercise.notes = (exercise.notes || "") + ` (${repl.notes})`;
          nameLower = repl.name.toLowerCase();
        }
      }

      // 2. Reemplazo por lesiones
      if (hasLegInjury && LOWER_BODY_EXERCISES.some(term => nameLower.includes(term))) {
        const repl = CORE_REPLACEMENTS[coreIdx % CORE_REPLACEMENTS.length];
        coreIdx++;
        exercise.name = repl.name;
        exercise.muscleGroup = repl.muscleGroup;
        exercise.sets = repl.sets;
        exercise.reps = repl.reps;
        if (repl.restSeconds) exercise.restSeconds = repl.restSeconds;
        exercise.notes = (exercise.notes || "") + " (Reemplazado por lesión en el miembro inferior)";
        exercise.technique = repl.technique;
        exercise.alternatives = repl.alternatives;
      } else if (hasShoulderInjury && PRESSING_EXERCISES.some(term => nameLower.includes(term))) {
        const repl = SHOULDER_REPLACEMENTS[shoulderIdx % SHOULDER_REPLACEMENTS.length];
        shoulderIdx++;
        exercise.name = repl.name;
        exercise.muscleGroup = repl.muscleGroup;
        exercise.sets = repl.sets;
        exercise.reps = repl.reps;
        if (repl.restSeconds) exercise.restSeconds = repl.restSeconds;
        exercise.notes = (exercise.notes || "") + " (Reemplazado por dolor/lesión de hombro o brazo)";
        exercise.technique = repl.technique;
        exercise.alternatives = repl.alternatives;
      }

      return exercise;
    });

    // Eliminar ejercicios duplicados dentro del mismo día (mantiene el primero)
    const seenNames = new Set<string>();
    day.exercises = (day.exercises || []).filter((ex: any) => {
      const key = (ex.name || "").toLowerCase().trim();
      if (!key || seenNames.has(key)) return false;
      seenNames.add(key);
      return true;
    });
  }

  return plan;
}

export async function generatePersonalizedPlanWithNutrition(input: {
  objective: string;
  experienceLevel: string;
  age: number;
  weight: number;
  height: number;
  daysPerWeek: number;
  equipment: string;
  injuries?: string;
  preferences?: string;
  dietaryRestrictions?: string | string[];
  gender?: string;
  activityLevel?: string;
  trainingTimeMinutes?: number;
  userContext?: string;
}) {
  try {
    const dietaryRestrictionsArray = input.dietaryRestrictions
      ? (typeof input.dietaryRestrictions === "string"
        ? input.dietaryRestrictions.split(",").map(s => s.trim()).filter(Boolean)
        : input.dietaryRestrictions)
      : [];
    const imc = (input.weight / ((input.height / 100) ** 2)).toFixed(1);
    const tdee = calculateTDEE(
      input.age,
      input.weight,
      input.height,
      input.daysPerWeek,
      input.gender,
      input.activityLevel
    );
    const macros = calculateMacros(input.objective, input.weight, tdee);
    const equipmentDesc = EQUIPMENT_MAP[input.equipment] || input.equipment;
    const objectiveDesc = OBJECTIVE_MAP[input.objective] || input.objective;
    const levelDesc = LEVEL_MAP[input.experienceLevel] || input.experienceLevel;

    const preferencesLower = (input.preferences || "").toLowerCase();
    const isCoreFocused = preferencesLower.includes("core") || 
                          preferencesLower.includes("zona media") || 
                          preferencesLower.includes("abdominal") || 
                          preferencesLower.includes("abdominales") || 
                          preferencesLower.includes("abs");

    const isOnlyCore = isCoreFocused && (
      preferencesLower.includes("solo") || 
      preferencesLower.includes("only") || 
      preferencesLower.includes("únicamente") || 
      preferencesLower.includes("unicamente")
    );

    let coreRules = "";
    if (isCoreFocused) {
      coreRules = `\n10. EL USUARIO SOLICITÓ ENFOQUE EN CORE/ZONA MEDIA. Debes priorizar ejercicios específicos para fortalecer el abdomen y la zona media, como planchas (Planks), abdominales (Crunches), elevaciones de piernas (Leg Raises), giros rusos (Russian Twists), etc.`;
      if (isOnlyCore) {
        coreRules += `\n11. ¡ATENCIÓN CRÍTICA! EL USUARIO SOLICITÓ *ÚNICAMENTE* CORE/ZONA MEDIA. Los días del plan de entrenamiento DEBEN contener EXCLUSIVAMENTE ejercicios de core/zona media (planchas, abdominales, lumbares, etc.). NO incluyas ningún ejercicio para otros grupos musculares como pecho, piernas, brazos, hombros o espalda superior.`;
      }
    }

    let structureRule = "10. REGLA ESTRICTA DE ESTRUCTURA: CADA día DEBE empezar siempre con 'warmup' enfocado en MOVILIDAD, luego la lista de 'exercises' debe tener EXACTAMENTE entre 6 y 8 ejercicios distintos (SIN repetir el mismo nombre de ejercicio dentro de un mismo día), y CADA ejercicio debe tener 3 series.";
    if (input.trainingTimeMinutes && input.trainingTimeMinutes <= 20) {
      structureRule = "10. REGLA ESTRICTA DE ESTRUCTURA PARA TIEMPO LIMITADO (20 MINUTOS): Dado que el usuario solo dispone de 20 minutos de entrenamiento diario, CADA día debe ser extremadamente eficiente y denso. DEBE tener EXACTAMENTE entre 3 y 4 ejercicios distintos. CADA ejercicio debe tener de 2 a 3 series. Estructura el entrenamiento como superseries (supersets) o un circuito de alta intensidad (HIIT/AMRAP) para maximizar la densidad y optimizar el tiempo. Reduce los descansos a 30-45 segundos.";
    } else if (input.trainingTimeMinutes && input.trainingTimeMinutes <= 35) {
      structureRule = "10. REGLA ESTRICTA DE ESTRUCTURA PARA TIEMPO LIMITADO (30-35 MINUTOS): Dado que el usuario dispone de 30-35 minutos diarios, CADA día debe tener EXACTAMENTE 4 a 5 ejercicios distintos, cada uno con 3 series. Agrupa ejercicios de forma eficiente para optimizar el tiempo.";
    }

    const restrictionsStr = dietaryRestrictionsArray.length > 0 
      ? dietaryRestrictionsArray.join(", ") 
      : "Ninguna";

    const prompt = `Eres un Personal Trainer y Nutricionista experto. Genera un plan de entrenamiento y nutrición COMPLETAMENTE PERSONALIZADO en JSON.

PERFIL DEL CLIENTE:
- Objetivo: ${objectiveDesc}
- Nivel: ${levelDesc}
- Edad: ${input.age} años | Peso: ${input.weight}kg | Altura: ${input.height}cm | IMC: ${imc}
- Sexo: ${input.gender || "No especificado"}
- Nivel de actividad diaria: ${input.activityLevel || "No especificado"}
- Tiempo de entrenamiento disponible: ${input.trainingTimeMinutes ? `${input.trainingTimeMinutes} minutos` : "45-60 minutos"}
- Días de entrenamiento: ${input.daysPerWeek} días/semana
- Equipo disponible: ${equipmentDesc}
- Lesiones/limitaciones: ${input.injuries || "Ninguna"}
- Preferencias: ${input.preferences || "Sin preferencias específicas"}
- Restricciones alimentarias: ${restrictionsStr}
- TDEE calculado: ${tdee} kcal/día
${input.userContext ? `\nCONTEXTO REAL DEL USUARIO (historial de entrenamiento):\n${input.userContext}\nEres el MOTOR RECOMENDADOR de la rutina: usa este historial para elegir la MEJOR rutina posible y define una progresión explícita (aumento de peso y/o reps semana a semana) coherente con la capacidad REAL del usuario (nivel, racha y series históricas), no solo con su nivel auto-reportado en el formulario.` : ""}

REGLAS CRÍTICAS:
1. La rutina DEBE estar ESTRICTAMENTE adaptada al perfil del cliente detallado arriba (lesiones, equipo, días, etc.).
2. Los ejercicios DEBEN ser compatibles con el equipo disponible (${equipmentDesc})
3. El volumen y complejidad DEBE corresponder al nivel ${input.experienceLevel}
4. Si hay lesiones, EVITAR ejercicios que las agraven
5. El objetivo condiciona la selección de ejercicios, series, reps y descansos
6. Para principiantes: ejercicios compuestos básicos, 3 series, 10-15 reps
7. Para avanzados: técnicas como drop sets, supersets, mayor volumen
8. Usa nombres de ejercicios en INGLÉS (para búsqueda en API de ejercicios)
9. DEBES incluir 'instructions' (instrucciones detalladas paso a paso en español) y 'tips' (consejos útiles en español) para CADA ejercicio.${coreRules}
${structureRule}
11. RAG CATALOG:
${getCatalogPromptString()}
IMPORTANTE: DEBES elegir TODOS los nombres de 'exercises' EXCLUSIVAMENTE de este catálogo. PROHIBIDO INVENTAR EJERCICIOS QUE NO ESTÉN EN EL CATÁLOGO.
12. RESTRICCIONES ALIMENTARIAS: Si el usuario declaró restricciones (${restrictionsStr}), TODAS las comidas del plan nutricional DEBEN respetarlas. Si es vegano/vegetariano, NO incluyas carne, huevos, lácteos ni pescado. Si es sin gluten, NO incluyas trigo/avena/cebada/centeno. Si es sin lactosa, NO incluyas lácteos. Si es alérgico a algún alimento, EXCLUYELO por completo.
13. FORMATO DE ALIMENTOS: Cada elemento de 'foods' DEBE ser un objeto JSON con: { "name": string, "quantity": number, "unit": string }. Ejemplo: { "name": "Pollo", "quantity": 150, "unit": "g" }. Las cantidades deben ser realistas y medibles. Prohibido devolver strings planos en 'foods'.`;

    const planSchema = {
      type: "object",
      properties: {
        summary: { type: "string" },
        objective: { type: "string" },
        durationWeeks: { type: "number" },
        daysPerWeek: { type: "number" },
        progressionStrategy: { type: "string" },
        days: {
          type: "array",
          items: {
            type: "object",
            properties: {
              dayNumber: { type: "number" },
              focus: { type: "string" },
              warmup: { type: "string" },
              exercises: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    name: { type: "string" },
                    muscleGroup: { type: "string" },
                    sets: { type: "number" },
                    reps: { type: "string" },
                    restSeconds: { type: "number" },
                    instructions: { type: "string" },
                    tips: { type: "string" },
                    alternatives: { type: "array", items: { type: "string" } }
                  },
                  required: ["name", "muscleGroup", "sets", "reps", "restSeconds", "instructions", "tips", "alternatives"],
                  additionalProperties: false
                }
              },
              cooldown: { type: "string" },
              notes: { type: "string" }
            },
            required: ["dayNumber", "focus", "warmup", "exercises", "cooldown", "notes"],
            additionalProperties: false
          }
        },
        nutrition: {
          type: "object",
          properties: {
            dailyCalories: { type: "number" },
            dailyMacros: { 
              type: "object", 
              properties: { protein: { type: "number" }, carbs: { type: "number" }, fats: { type: "number" } },
              required: ["protein", "carbs", "fats"],
              additionalProperties: false
            },
            mealFrequency: { type: "number" },
            meals: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  mealNumber: { type: "number" },
                  time: { type: "string" },
                  name: { type: "string" },
                  foods: {
                    type: "array",
                    items: {
                      type: "object",
                      properties: {
                        name: { type: "string" },
                        quantity: { type: "number" },
                        unit: { type: "string" },
                      },
                      required: ["name"],
                      additionalProperties: false,
                    },
                  },
                  macros: { 
                    type: "object", 
                    properties: { protein: { type: "number" }, carbs: { type: "number" }, fats: { type: "number" } },
                    required: ["protein", "carbs", "fats"],
                    additionalProperties: false
                  },
                  calories: { type: "number" },
                  notes: { type: "string" }
                },
                required: ["mealNumber", "time", "name", "foods", "macros", "calories", "notes"],
                additionalProperties: false
              }
            },
            tips: { type: "array", items: { type: "string" } },
            hydration: { type: "string" },
            supplementation: { type: "string" },
            notes: { type: "string" }
          },
          required: ["dailyCalories", "dailyMacros", "mealFrequency", "meals", "tips", "hydration", "supplementation", "notes"],
          additionalProperties: false
        },
        generalAdvice: { type: "string" }
      },
      required: ["summary", "objective", "durationWeeks", "daysPerWeek", "progressionStrategy", "days", "nutrition", "generalAdvice"],
      additionalProperties: false
    };

    const response = await invokeLLM({
      messages: [
        { role: "system", content: "Eres un experto en fitness y nutrición. Genera la rutina en el JSON exacto. SÉ EXTREMADAMENTE BREVE en las descripciones para no exceder los límites de tiempo. Solo lo esencial." },
        { role: "user", content: prompt },
      ],
      maxTokens: 4000,
      outputSchema: {
        name: "PersonalizedFitnessPlan",
        schema: planSchema,
        strict: true
      }
    });

    const content = response.choices[0]?.message.content;
    if (!content) return generateBasicPlan(input, tdee, macros);

    const textContent = typeof content === "string" ? content : content.filter(c => c.type === "text").map(c => (c as any).text).join("");
    const parsed = JSON.parse(textContent);
    const validatedPlan = validateGeneratedPlan(parsed, input);
    
    // Enrich with media URLs (absolute http/https only — never relative /exercises/*)
    const { getExerciseMediaUrl, isUsableMediaUrl } = await import("./_core/musclewiki");
    const { translateExerciseToSpanish } = await import("./_core/translations");
    for (const day of validatedPlan.days || []) {
      for (const ex of day.exercises || []) {
        if (ex.name) {
          const media = await getExerciseMediaUrl(ex.name);
          if (media && isUsableMediaUrl(media.url)) {
            ex.gifUrl = media.url;
          }

          // Keep English name for reference, change displayed name to Spanish
          ex.nameEn = ex.name;
          ex.name = translateExerciseToSpanish(ex.name);
        }
      }
    }

    console.log("[LLM] Plan generated and enriched with media successfully");
    return validatedPlan;
    
  } catch (error) {
    console.error("[LLM] Error:", error instanceof Error ? error.message : String(error));
    const tdee = calculateTDEE(input.age, input.weight, input.height, input.daysPerWeek);
    const macros = calculateMacros(input.objective, input.weight, tdee);
    return generateBasicPlan(input, tdee, macros);
  }
}

export async function generateBasicPlan(input: any, tdee: number, macros: any) {
  const equip = input.equipment || "full_gym";
  const experience = input.experienceLevel || input.experience || "intermediate";
  const objective = input.objective || "hypertrophy";
  const preferences = (input.preferences || "").toLowerCase();

  // Reglas de Volumen y Repeticiones según Experiencia y Objetivo
  const isBeginner = experience === "beginner";
  let sets = isBeginner ? 2 : 3;
  let reps = "8-12";
  let restSeconds = 60;

  if (objective === "strength") {
    reps = "4-6";
    restSeconds = 120;
  } else if (objective === "fat_loss" || objective === "weight_loss" || objective === "recomposition") {
    reps = "12-15";
    restSeconds = 45;
  }

  let maxExercises = 7;
  if (input.trainingTimeMinutes && input.trainingTimeMinutes <= 20) {
    sets = 2;
    maxExercises = 3;
  } else if (input.trainingTimeMinutes && input.trainingTimeMinutes <= 35) {
    maxExercises = 5;
  }

  const mobilityWarmup = "Calentamiento de movilidad articular (Rotaciones de hombros, caderas, sentadilla profunda y giros de torso) durante 5-10 minutos.";

  // Análisis de preferencias (Core)
  const isOnlyCore = preferences.includes("solo core") || preferences.includes("solo zona media") || preferences.includes("solo abdominales");
  const wantsCore = preferences.includes("core") || preferences.includes("zona media") || preferences.includes("abdomen") || preferences.includes("abdominales");

  // Build exercise pools from the catalog based on equipment
  const { EXERCISE_CATALOG } = await import("./_core/catalog");

  function makeExercise(name: string, muscleGroup: string, altReps?: string, altRest?: number) {
    return {
      name,
      muscleGroup,
      sets,
      reps: altReps ?? reps,
      restSeconds: altRest ?? restSeconds,
      instructions: `Realizá ${name} con técnica controlada.`,
      tips: "Mantené la tensión muscular y respirá de forma constante.",
      alternatives: [],
    };
  }

  const bodyweightChest = ["Push-up", "Decline Push-up", "Incline Push-up", "Diamond Push-up", "Pike Push-up", "Bench Dip"].map(n => makeExercise(n, n === "Pike Push-up" ? "Hombros" : "Pecho"));
  const bodyweightBack = ["Pull-up", "Chin-up", "Inverted Row", "Superman"].map(n => makeExercise(n, n === "Chin-up" ? "Bíceps" : "Espalda"));
  const bodyweightLegs = ["Bodyweight Squat", "Lunges", "Walking Lunges", "Glute Bridge", "Hip Thrust", "Calf Raise", "Step-up"].map(n => makeExercise(n, "Piernas"));

  const dumbbellChest = ["Dumbbell Bench Press", "Incline Dumbbell Press", "Dumbbell Flyes"].map(n => makeExercise(n, "Pecho"));
  const dumbbellBack = ["Dumbbell Row", "Dumbbell Curl", "Hammer Curl"].map(n => makeExercise(n, n.includes("Row") ? "Espalda" : "Bíceps"));
  const dumbbellLegs = ["Goblet Squat", "Dumbbell Deadlift", "Dumbbell Lunge", "Romanian Deadlift", "Bulgarian Split Squat", "Calf Raise"].map(n => makeExercise(n, "Piernas"));
  const dumbbellShoulders = ["Dumbbell Shoulder Press", "Lateral Raise", "Arnold Press"].map(n => makeExercise(n, "Hombros"));

  const gymChest = ["Bench Press", "Incline Bench Press", "Decline Bench Press", "Dumbbell Bench Press", "Dumbbell Flyes", "Cable Crossover", "Machine Chest Press"].map(n => makeExercise(n, "Pecho"));
  const gymBack = ["Barbell Row", "Pull-up", "Chin-up", "Lat Pulldown", "Deadlift", "T-Bar Row", "Seated Cable Row"].map(n => makeExercise(n, ["Chin-up", "Dumbbell Curl"].some(x => n.includes(x)) ? "Bíceps" : "Espalda"));
  const gymLegs = ["Barbell Squat", "Front Squat", "Romanian Deadlift", "Leg Press", "Leg Curl", "Leg Extension", "Hip Thrust", "Calf Raise"].map(n => makeExercise(n, "Piernas"));
  const gymShoulders = ["Overhead Press", "Dumbbell Shoulder Press", "Lateral Raise", "Face Pull", "Upright Row"].map(n => makeExercise(n, "Hombros"));
  const gymArms = ["Barbell Curl", "Dumbbell Curl", "Hammer Curl", "Triceps Pushdown", "Skullcrusher", "Close Grip Bench Press"].map(n => makeExercise(n, n.toLowerCase().includes("curl") ? "Bíceps" : "Tríceps"));

  const coreExercises = [
    makeExercise("Crunch", "Core", "15-20", 45),
    makeExercise("Plank", "Core", "30-60s", 45),
    makeExercise("Russian Twist", "Core", "15-20", 45),
    makeExercise("Hanging Leg Raise", "Core", "10-15", 45),
    makeExercise("Dead Bug", "Core", "10-12", 45),
    makeExercise("Bicycle Crunch", "Core", "15-20", 45),
  ];

  let chestPool: any[] = [];
  let backPool: any[] = [];
  let legsPool: any[] = [];
  let shouldersPool: any[] = [];
  let armsPool: any[] = [];

  if (equip === "bodyweight" || equip === "limited") {
    chestPool = bodyweightChest;
    backPool = bodyweightBack;
    legsPool = bodyweightLegs;
  } else if (equip === "dumbbells") {
    chestPool = dumbbellChest;
    backPool = dumbbellBack;
    legsPool = dumbbellLegs;
    shouldersPool = dumbbellShoulders;
  } else {
    chestPool = gymChest;
    backPool = gymBack;
    legsPool = gymLegs;
    shouldersPool = gymShoulders;
    armsPool = gymArms;
  }

  // Si el usuario quiere enfocarse en core, agregamos ejercicios de core a las rutinas
  if (wantsCore && !isOnlyCore) {
    chestPool = [...chestPool.slice(0, 5), coreExercises[0], coreExercises[1]];
    backPool = [...backPool.slice(0, 5), coreExercises[2], coreExercises[3]];
    legsPool = [...legsPool.slice(0, 5), coreExercises[4], coreExercises[5]];
  }

  function sliceUnique(pool: any[], count: number) {
    const seen = new Set<string>();
    const result: any[] = [];
    for (const ex of pool) {
      const key = ex.name.toLowerCase();
      if (!seen.has(key)) {
        seen.add(key);
        result.push(ex);
      }
      if (result.length === count) break;
    }
    return result;
  }

  let days: any[] = [];

  if (isOnlyCore) {
    for (let i = 0; i < input.daysPerWeek; i++) {
      days.push({
        dayNumber: i + 1,
        focus: "Core & Zona Media",
        warmup: mobilityWarmup,
        exercises: sliceUnique(coreExercises, maxExercises),
        cooldown: "Estiramientos de abdomen y lumbar.",
        notes: "Enfócate en la contracción muscular del core."
      });
    }
  } else if (input.daysPerWeek === 3) {
    days = [
      { dayNumber: 1, focus: "Push (Pecho, Hombros, Tríceps)", warmup: mobilityWarmup, exercises: sliceUnique([...chestPool, ...shouldersPool, ...armsPool.filter(a => a.muscleGroup === "Tríceps")], maxExercises), cooldown: "Estiramientos ligeros de pecho y tríceps.", notes: "Enfócate en la técnica." },
      { dayNumber: 2, focus: "Pull (Espalda, Bíceps)", warmup: mobilityWarmup, exercises: sliceUnique([...backPool, ...armsPool.filter(a => a.muscleGroup === "Bíceps")], maxExercises), cooldown: "Estiramientos de espalda y bíceps.", notes: "Controla el movimiento excéntrico." },
      { dayNumber: 3, focus: "Legs (Piernas)", warmup: mobilityWarmup, exercises: sliceUnique(legsPool, maxExercises), cooldown: "Estiramientos de piernas.", notes: "No descuides el rango de movimiento." },
    ];
  } else {
    const upperLimit = Math.max(2, Math.floor(maxExercises / 2));
    const upper1 = sliceUnique([...chestPool, ...shouldersPool, ...backPool], maxExercises);
    const upper2 = sliceUnique([...backPool, ...chestPool, ...armsPool], maxExercises);
    const lower = sliceUnique(legsPool, maxExercises);
    const fullBody = sliceUnique([...legsPool.slice(0, upperLimit), ...chestPool.slice(0, 1), ...backPool.slice(0, maxExercises - upperLimit - 1)], maxExercises);
    days = [
      { dayNumber: 1, focus: "Upper Body", warmup: mobilityWarmup, exercises: upper1, cooldown: "Estiramientos superiores.", notes: "Mantén intensidad." },
      { dayNumber: 2, focus: "Lower Body", warmup: mobilityWarmup, exercises: lower, cooldown: "Estiramientos inferiores.", notes: "Día pesado." },
      { dayNumber: 3, focus: "Upper Body", warmup: mobilityWarmup, exercises: upper2, cooldown: "Estiramientos superiores.", notes: "Más aislamiento." },
      { dayNumber: 4, focus: "Full Body", warmup: mobilityWarmup, exercises: fullBody, cooldown: "Estiramientos completos.", notes: "Recuperación activa." },
    ].slice(0, input.daysPerWeek);
  }

  // Generate personalized nutrition using the real algorithm
  const { generateNutritionPlan } = await import("./_core/NutritionPlanGenerator");
  const nutritionObjective: "fat_loss" | "muscle_gain" | "maintenance" | "general_health" =
    objective === "strength" || objective === "hypertrophy" ? "muscle_gain" :
    objective === "fat_loss" || objective === "weight_loss" ? "fat_loss" : "maintenance";
  const nutritionInput = {
    age: input.age ?? 30,
    weight: input.weight ?? 75,
    height: input.height ?? 175,
    gender: (input.gender === "female" ? "female" : "male") as "male" | "female",
    activityLevel: (input.activityLevel ? String(input.activityLevel).toLowerCase() : "moderate") as any,
    objective: nutritionObjective,
    mealFrequency: 5 as 3 | 4 | 5 | 6,
    dietaryRestrictions: Array.isArray(input.dietaryRestrictions) ? input.dietaryRestrictions : (input.dietaryRestrictions ? String(input.dietaryRestrictions).split(",").map((s: string) => s.trim()).filter(Boolean) : []),
  };
  const nutritionPlan = generateNutritionPlan(nutritionInput);

  const basicPlan = {
    summary: `Plan personalizado de contingencia de ${input.daysPerWeek} días/semana para ${input.objective} (${experience})`,
    objective: input.objective,
    durationWeeks: 12,
    daysPerWeek: input.daysPerWeek,
    progressionStrategy: "Aumenta peso cada semana en 2-5% o agrega 1-2 reps",
    days,
    nutrition: nutritionPlan,
    generalAdvice: "Sigue el plan consistentemente, descansa adecuadamente y ajusta según tu progreso",
  };

  // Aplica el mismo filtro de equipo/lesiones que usa el camino con IA,
  // para que el fallback (sin LLM) también respete lesiones declaradas.
  return validateGeneratedPlan(basicPlan, input);
}

