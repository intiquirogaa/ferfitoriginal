import { eq, and, desc } from "drizzle-orm";
import { drizzle } from "drizzle-orm/mysql2";
import { InsertUser, users, trainingPlans, dailyChecklists, userProgress, exerciseHistory, InsertExerciseHistory, achievements, userAchievements, mealLogs, nutritionPlans, InsertNutritionPlan } from "../drizzle/schema";
import { ENV } from "./_core/env";

import mysql from "mysql2/promise";

let _db: any = null;
let _pool: mysql.Pool | null = null;

async function seedAchievements(db: any) {
  try {
    const existing = await db.select().from(achievements).limit(1);
    if (existing.length === 0) {
      console.log("Seeding default achievements...");
      await db.insert(achievements).values([
        { name: "Primer Paso", description: "Completa tu primera serie", icon: "zap", conditionType: "series_completed", conditionValue: 1 },
        { name: "Constancia Inicial", description: "Alcanza una racha de 3 días", icon: "flame", conditionType: "streak_days", conditionValue: 3 },
        { name: "Guerrero de Hierro", description: "Completa 10 entrenamientos", icon: "dumbbell", conditionType: "workouts_done", conditionValue: 10 },
        { name: "Acumulador de XP", description: "Consigue 1000 XP total", icon: "trophy", conditionType: "total_xp", conditionValue: 1000 },
      ]);
      console.log("Achievements seeded successfully!");
    }
  } catch (error) {
    console.warn("Could not seed achievements (table might not exist yet):", error);
  }
}

export async function getDb() {
  if (!_db && process.env.DATABASE_URL) {
    console.log("Conectando con pool robusto...");
    _pool = mysql.createPool({
      uri: process.env.DATABASE_URL,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      enableKeepAlive: true,
      keepAliveInitialDelay: 10000,
    });
    _db = drizzle(_pool);
    seedAchievements(_db).catch(console.error);
  }
  return _db;
}

/* ─── USERS ─────────────────────────────────────────────── */

export async function upsertUser(user: InsertUser): Promise<void> {
  if (!user.openId) throw new Error("User openId is required for upsert");
  const db = await getDb();
  if (!db) { console.warn("[Database] Cannot upsert user: database not available"); return; }
  try {
    const values: InsertUser = { openId: user.openId };
    const updateSet: Record<string, unknown> = {};
    const textFields = ["name", "email", "loginMethod"] as const;
    type TextField = (typeof textFields)[number];
    const assignNullable = (field: TextField) => {
      const value = user[field];
      if (value === undefined) return;
      const normalized = value ?? null;
      values[field] = normalized;
      updateSet[field] = normalized;
    };
    textFields.forEach(assignNullable);
    if (user.lastSignedIn !== undefined) { values.lastSignedIn = user.lastSignedIn; updateSet.lastSignedIn = user.lastSignedIn; }
    if (user.role !== undefined) { values.role = user.role; updateSet.role = user.role; }
    else if (user.openId === ENV.ownerOpenId) { values.role = "admin"; updateSet.role = "admin"; }
    if (!values.lastSignedIn) values.lastSignedIn = new Date();
    if (Object.keys(updateSet).length === 0) updateSet.lastSignedIn = new Date();
    await db.insert(users).values(values).onDuplicateKeyUpdate({ set: updateSet });
  } catch (error) {
    console.error("[Database] Failed to upsert user:", error);
    throw error;
  }
}

export async function getUserByOpenId(openId: string) {
  const db = await getDb();
  if (!db) { console.warn("[Database] Cannot get user: database not available"); return undefined; }
  const result = await db.select().from(users).where(eq(users.openId, openId)).limit(1);
  return result.length > 0 ? result[0] : undefined;
}

export async function getUserByEmail(email: string) {
  const db = await getDb();
  if (!db) return undefined;
  const result = await db.select().from(users).where(eq(users.email, email)).limit(1);
  return result.length > 0 ? result[0] : undefined;
}

export async function createUser(user: InsertUser) {
  const db = await getDb();
  if (!db) throw new Error("[Database] Cannot create user: database not available");
  
  if (!user.lastSignedIn) user.lastSignedIn = new Date();
  
  const result = await db.insert(users).values(user);
  // Return the newly created user (or insertId)
  return await getUserByOpenId(user.openId);
}

/* ─── TRAINING PLANS ─────────────────────────────────────── */

export async function createTrainingPlan(
  userId: number,
  type: "strength" | "hypertrophy",
  daysPerWeek: number,
  generatedContent: string
) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");
  
  const incompleteChecklists = await db.select().from(dailyChecklists).where(and(eq(dailyChecklists.userId, userId), eq(dailyChecklists.isCompleted, 0)));
  for (const checklist of incompleteChecklists) {
    await db.delete(exerciseHistory).where(eq(exerciseHistory.dailyChecklistId, checklist.id));
    await db.delete(dailyChecklists).where(eq(dailyChecklists.id, checklist.id));
  }

  await db.update(trainingPlans).set({ isActive: 0 }).where(eq(trainingPlans.userId, userId));
  const result = await db.insert(trainingPlans).values({
    userId,
    type,
    daysPerWeek,
    durationWeeks: 12,
    isActive: 1,
    generatedContent,
    startDate: new Date(),
  });
  return result[0];
}

export async function updateTrainingPlanContent(planId: number, generatedContent: string) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");
  await db.update(trainingPlans).set({ generatedContent }).where(eq(trainingPlans.id, planId));
}

export async function getActiveTrainingPlan(userId: number) {
  const db = await getDb();
  if (!db) return null;
  const result = await db
    .select()
    .from(trainingPlans)
    .where(and(eq(trainingPlans.userId, userId), eq(trainingPlans.isActive, 1)))
    .limit(1);
  return result.length > 0 ? result[0] : null;
}

/* ─── DAILY CHECKLISTS ───────────────────────────────────── */

export async function createDailyChecklist(
  userId: number,
  trainingPlanId: number,
  dayOfWeek: string,
  totalSeries: number
) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const existing = await db
    .select()
    .from(dailyChecklists)
    .where(and(eq(dailyChecklists.userId, userId), eq(dailyChecklists.trainingPlanId, trainingPlanId)))
    .limit(1);
  if (existing.length > 0) return existing[0];
  const result = await db.insert(dailyChecklists).values({
    userId,
    trainingPlanId,
    dayOfWeek,
    totalSeries,
    completedSeries: 0,
    isCompleted: 0,
    xpEarned: 0,
    date: new Date(),
  });
  return result[0];
}

export async function getTodayChecklist(userId: number) {
  const db = await getDb();
  if (!db) return null;
  const result = await db
    .select()
    .from(dailyChecklists)
    .where(eq(dailyChecklists.userId, userId))
    .orderBy(desc(dailyChecklists.createdAt))
    .limit(1);
  
  if (result.length > 0) {
    const checklist = result[0];
    const today = new Date();
    const checklistDate = new Date(checklist.createdAt);
    // Verificar si el checklist es de hoy (ignorando la hora)
    if (
      checklistDate.getFullYear() === today.getFullYear() &&
      checklistDate.getMonth() === today.getMonth() &&
      checklistDate.getDate() === today.getDate()
    ) {
      return checklist;
    }
  }
  return null;
}

export async function updateChecklistProgress(
  checklistId: number,
  completedSeries: number,
  xpEarned: number
) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");
  const isCompleted = completedSeries > 0 ? 1 : 0;
  await db
    .update(dailyChecklists)
    .set({ completedSeries, xpEarned, isCompleted })
    .where(eq(dailyChecklists.id, checklistId));
  return { success: true };
}

/* ─── USER PROGRESS ──────────────────────────────────────── */

export async function getUserProgress(userId: number) {
  const db = await getDb();
  if (!db) return null;
  const result = await db.select().from(userProgress).where(eq(userProgress.userId, userId)).limit(1);
  return result.length > 0 ? result[0] : null;
}

export async function createUserProgress(userId: number) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");
  await db.insert(userProgress).values({
    userId,
    totalXP: 0,
    level: 1,
    streak: 0,
    coins: 200, // 200 FerCoins iniciales para el usuario
    unlockedSkins: JSON.stringify([]),
    seriesCompletedHistorically: 0,
    seriesProgrammed: 0,
  });
}

export async function updateUserProgress(
  userId: number,
  xpToAdd: number,
  seriesCompleted: number,
  daysPerWeek?: number
) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");
  const current = await getUserProgress(userId);
  if (!current) return;
  // XP y series nunca bajan de 0 (evita valores negativos al desmarcar series)
  const newXP = Math.max(0, (current.totalXP || 0) + xpToAdd);
  const newLevel = Math.floor(newXP / 500) + 1;
  const newSeries = Math.max(0, (current.seriesCompletedHistorically || 0) + seriesCompleted);
  const coinsEarned = Math.floor(xpToAdd / 2);
  const newCoins = Math.max(0, (current.coins || 0) + coinsEarned);

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  let newStreak = current.streak || 0;
  if (current.lastWorkoutDate) {
    const lastDate = new Date(current.lastWorkoutDate);
    lastDate.setHours(0, 0, 0, 0);
    const diffDays = Math.floor((today.getTime() - lastDate.getTime()) / (1000 * 60 * 60 * 24));
    if (diffDays === 0) {
      // Mismo día: la racha no cambia
      newStreak = current.streak || 0;
    } else {
      // Racha tolerante a la frecuencia semanal del plan (misma lógica que antes en markSeriesComplete)
      const frequency = daysPerWeek && daysPerWeek >= 2 ? daysPerWeek : 3;
      const maxAllowedGap = Math.ceil(7 / frequency) + 1;
      if (diffDays <= maxAllowedGap) newStreak = (current.streak || 0) + 1;
      else newStreak = 1;
    }
  } else {
    newStreak = 1;
  }
  await db.update(userProgress).set({
    totalXP: newXP,
    level: newLevel,
    streak: newStreak,
    coins: newCoins,
    seriesCompletedHistorically: newSeries,
    lastWorkoutDate: new Date(),
  }).where(eq(userProgress.userId, userId));
}

/* ─── EXERCISE HISTORY ──────────────────────────────────── */

export async function createExerciseHistory(data: InsertExerciseHistory) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");
  const result = await db.insert(exerciseHistory).values(data);
  return result[0];
}

export async function getExerciseHistoryByDay(userId: number, dailyChecklistId: number) {
  const db = await getDb();
  if (!db) return [];
  const result = await db
    .select()
    .from(exerciseHistory)
    .where(and(eq(exerciseHistory.userId, userId), eq(exerciseHistory.dailyChecklistId, dailyChecklistId)))
    .orderBy(exerciseHistory.exerciseIndex);
  return result;
}

export async function updateExerciseHistory(
  exerciseHistoryId: number,
  data: Partial<InsertExerciseHistory>
) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");
  await db.update(exerciseHistory).set(data).where(eq(exerciseHistory.id, exerciseHistoryId));
}

export async function getExerciseProgressStats(userId: number, exerciseName: string) {
  const db = await getDb();
  if (!db) return [];
  const result = await db
    .select()
    .from(exerciseHistory)
    .where(and(eq(exerciseHistory.userId, userId), eq(exerciseHistory.exerciseName, exerciseName)))
    .orderBy(exerciseHistory.completedAt);
  return result;
}

/* ─── CALENDAR / COMPLETED DATES ─────────────────────────── */

export async function getCompletedDates(userId: number): Promise<Date[]> {
  const db = await getDb();
  if (!db) return [];
  try {
    const result = await db
      .select({ date: dailyChecklists.date })
      .from(dailyChecklists)
      .where(and(eq(dailyChecklists.userId, userId), eq(dailyChecklists.isCompleted, 1)))
      .orderBy(dailyChecklists.date);
    return result.map((r: { date: Date | string | number }) => new Date(r.date));
  } catch (error) {
    console.error("[Database] Failed to get completed dates:", error);
    return [];
  }
}

export async function getDayDetails(userId: number, date: Date) {
  const db = await getDb();
  if (!db) return null;
  try {
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const allChecklists = await db
      .select()
      .from(dailyChecklists)
      .where(eq(dailyChecklists.userId, userId));

    const checklist = allChecklists.find((c: any) => {
      const checklistDate = new Date(c.date);
      checklistDate.setHours(0, 0, 0, 0);
      return checklistDate.getTime() === startOfDay.getTime();
    });

    if (!checklist) return null;

    const plan = await db
      .select()
      .from(trainingPlans)
      .where(eq(trainingPlans.id, checklist.trainingPlanId))
      .limit(1);

    if (plan.length === 0) return null;

    return {
      checklist,
      plan: plan[0],
    };
  } catch (error) {
    console.error("[Database] Failed to get day details:", error);
    return null;
  }
}

/* ─── ACHIEVEMENTS ───────────────────────────────────────── */

export async function getAchievements() {
  const db = await getDb();
  if (!db) return [];
  return await db.select().from(achievements);
}

export async function getUserAchievements(userId: number) {
  const db = await getDb();
  if (!db) return [];
  return await db.select().from(userAchievements).where(eq(userAchievements.userId, userId));
}

export async function unlockAchievement(userId: number, achievementId: number) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");
  await db.insert(userAchievements).values({
    userId,
    achievementId,
    unlockedAt: new Date(),
  });
}

export async function checkAndUnlockAchievements(userId: number) {
  const db = await getDb();
  if (!db) return [];

  try {
    const progress = await db.select().from(userProgress).where(eq(userProgress.userId, userId)).limit(1);
    if (progress.length === 0) return [];
    const p = progress[0];

    const completedChecklists = await db
      .select()
      .from(dailyChecklists)
      .where(and(eq(dailyChecklists.userId, userId), eq(dailyChecklists.isCompleted, 1)));
    const workoutsDone = completedChecklists.length;

    const stats = {
      total_xp: p.totalXP,
      streak_days: p.streak,
      series_completed: p.seriesCompletedHistorically,
      workouts_done: workoutsDone,
    };

    const allAchievements = await db.select().from(achievements);
    const unlocked = await db.select().from(userAchievements).where(eq(userAchievements.userId, userId));
    const unlockedIds = new Set(unlocked.map((u: any) => u.achievementId));

    const newlyUnlocked = [];

    for (const ach of allAchievements) {
      if (!unlockedIds.has(ach.id)) {
        const type = ach.conditionType as keyof typeof stats;
        const value = stats[type];
        if (value !== undefined && value >= ach.conditionValue) {
          await db.insert(userAchievements).values({
            userId,
            achievementId: ach.id,
            unlockedAt: new Date(),
          });
          newlyUnlocked.push(ach);
        }
      }
    }

    return newlyUnlocked;
  } catch (error) {
    console.error("[Achievements] Error checking achievements, skipping:", error);
    return [];
  }
}

export async function getUserChecklists(userId: number) {
  const db = await getDb();
  if (!db) return [];
  return await db.select().from(dailyChecklists).where(eq(dailyChecklists.userId, userId));
}

/* ─── MEAL LOGS ──────────────────────────────────────────── */

export async function logMeal(
  userId: number,
  trainingPlanId: number,
  date: Date,
  mealNumber: number,
  consumed: boolean,
  notes?: string
) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");

  const startOfDay = new Date(date);
  startOfDay.setHours(0, 0, 0, 0);
  const endOfDay = new Date(date);
  endOfDay.setHours(23, 59, 59, 999);

  const existing = await db
    .select()
    .from(mealLogs)
    .where(
      and(
        eq(mealLogs.userId, userId),
        eq(mealLogs.trainingPlanId, trainingPlanId),
        eq(mealLogs.mealNumber, mealNumber)
      )
    );

  const existingForDate = existing.find((log: any) => {
    const logDate = new Date(log.date);
    return logDate >= startOfDay && logDate <= endOfDay;
  });

  if (existingForDate) {
    await db
      .update(mealLogs)
      .set({ consumed: consumed ? 1 : 0, notes, loggedAt: new Date() })
      .where(eq(mealLogs.id, existingForDate.id));
    return { id: existingForDate.id, updated: true };
  }

  const result = await db.insert(mealLogs).values({
    userId,
    trainingPlanId,
    date,
    mealNumber,
    consumed: consumed ? 1 : 0,
    notes,
    loggedAt: new Date(),
  });
  return { id: (result as any).insertId, updated: false };
}

export async function getMealLogsForDate(
  userId: number,
  trainingPlanId: number,
  date: Date
) {
  const db = await getDb();
  if (!db) return [];

  const startOfDay = new Date(date);
  startOfDay.setHours(0, 0, 0, 0);
  const endOfDay = new Date(date);
  endOfDay.setHours(23, 59, 59, 999);

  const result = await db
    .select()
    .from(mealLogs)
    .where(
      and(
        eq(mealLogs.userId, userId),
        eq(mealLogs.trainingPlanId, trainingPlanId)
      )
    );

  return result.filter((log: any) => {
    const logDate = new Date(log.date);
    return logDate >= startOfDay && logDate <= endOfDay;
  });
}

export async function getMealLogsForDateRange(
  userId: number,
  trainingPlanId: number,
  startDate: Date,
  endDate: Date
) {
  const db = await getDb();
  if (!db) return [];

  const result = await db
    .select()
    .from(mealLogs)
    .where(
      and(
        eq(mealLogs.userId, userId),
        eq(mealLogs.trainingPlanId, trainingPlanId)
      )
    );

  return result.filter((log: any) => {
    const logDate = new Date(log.date);
    return logDate >= startDate && logDate <= endDate;
  });
}

/* ─── NUTRITION PLANS ────────────────────────────────────── */

export async function createNutritionPlan(
  userId: number,
  generatedContent: string,
  trainingPlanId?: number
) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");
  await db.update(nutritionPlans).set({ isActive: 0 }).where(eq(nutritionPlans.userId, userId));
  const result = await db.insert(nutritionPlans).values({
    userId,
    trainingPlanId: trainingPlanId ?? null,
    isActive: 1,
    generatedContent,
  });
  return result[0];
}

export async function getActiveNutritionPlan(userId: number) {
  const db = await getDb();
  if (!db) return null;
  const result = await db
    .select()
    .from(nutritionPlans)
    .where(and(eq(nutritionPlans.userId, userId), eq(nutritionPlans.isActive, 1)))
    .limit(1);
  return result.length > 0 ? result[0] : null;
}

export async function updateNutritionPlanContent(planId: number, generatedContent: string) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");
  await db.update(nutritionPlans).set({ generatedContent }).where(eq(nutritionPlans.id, planId));
}
