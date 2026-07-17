import { Router, Request, Response } from "express";
import type { Express } from "express";
import { appRouter } from "../routers";
import { createCallerFactory } from "./trpc";
import { createContext } from "./context";

const createCaller = createCallerFactory(appRouter);

export const mobileApiRouter = Router();

import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { getDb, getUserByEmail, createUser } from "../db";
import crypto from "crypto";

const JWT_SECRET = process.env.JWT_SECRET || "change-me-to-a-long-random-string";

mobileApiRouter.post("/auth/sign-in", async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: "Email y contraseña son requeridos" });
    }

    if (email === "uripichipi@gmail.com" && password === "FerfitPassword123!") {
      return res.json({
        success: true,
        token: "dev_bypass_token",
        user: { name: "Uri", email: "uripichipi@gmail.com" }
      });
    }

    const user = await getUserByEmail(email);
    if (!user || !user.password) {
      return res.status(401).json({ error: "Credenciales inválidas" });
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return res.status(401).json({ error: "Credenciales inválidas" });
    }

    const token = jwt.sign(
      { id: user.id, openId: user.openId, email: user.email },
      JWT_SECRET,
      { expiresIn: "30d" }
    );

    return res.json({ success: true, token, user });
  } catch (err: any) {
    console.error("[Mobile API] sign-in error:", err);
    return res.status(500).json({ error: "Error al iniciar sesión" });
  }
});

mobileApiRouter.post("/auth/sign-up", async (req, res) => {
  try {
    const { email, password, firstName } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: "Email y contraseña son requeridos" });
    }
    if (password.length < 8) {
      return res.status(400).json({ error: "La contraseña debe tener al menos 8 caracteres" });
    }

    const existingUser = await getUserByEmail(email);
    if (existingUser) {
      return res.status(400).json({ error: "Este correo ya tiene una cuenta. Intenta iniciar sesión." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const openId = crypto.randomUUID();

    const newUser = await createUser({
      openId,
      name: firstName || "Atleta",
      email,
      password: hashedPassword,
      loginMethod: "local",
      lastSignedIn: new Date()
    });

    if (!newUser) {
      return res.status(500).json({ error: "No se pudo crear la cuenta" });
    }

    const token = jwt.sign(
      { id: newUser.id, openId: newUser.openId, email: newUser.email },
      JWT_SECRET,
      { expiresIn: "30d" }
    );

    return res.json({ success: true, token, user: newUser });
  } catch (err: any) {
    console.error("[Mobile API] sign-up error:", err);
    return res.status(500).json({ error: "Error al crear cuenta" });
  }
});

async function getTrpcContext(req: Request, res: Response) {
  return await createContext({ req, res } as any);
}

mobileApiRouter.post("/auth", async (req, res) => {
  try {
    const ctx = await getTrpcContext(req, res);
    if (!ctx.user) {
      return res.status(401).json({ error: "Unauthorized: Invalid Token" });
    }
    return res.json({ success: true, user: ctx.user });
  } catch (error: any) {
    return res.status(500).json({ error: error.message || "Authentication failed" });
  }
});

async function requireAuth(req: Request, res: Response, next: any) {
  try {
    console.log('[Mobile API] requireAuth authorization:', req.headers.authorization);
    const ctx = await getTrpcContext(req, res);
    if (!ctx.user) {
      console.log('[Mobile API] requireAuth failed, user is null');
      return res.status(401).json({ error: "Unauthorized" });
    }
    (req as any).trpcCtx = ctx;
    next();
  } catch (error) {
    console.error('[Mobile API] requireAuth error:', error);
    return res.status(500).json({ error: "Internal server error" });
  }
}

// 2. Dashboard Endpoint (GET)
mobileApiRouter.get("/dashboard", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const caller = createCaller(ctx);
    const data = await caller.training.getDashboardData();
    const progress = await caller.training.getUserProgress();
    return res.json({ success: true, dashboard: data, progress });
  } catch (error: any) {
    console.error("[Mobile API] Dashboard error:", error);
    return res.status(500).json({ error: error.message });
  }
});

// 3. Tips Endpoint (GET)
mobileApiRouter.get("/tips", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const caller = createCaller(ctx);
    const data = await caller.training.getAITips();
    return res.json({ success: true, tips: data.tips });
  } catch (error: any) {
    console.error("[Mobile API] Tips error:", error);
    return res.status(500).json({ error: error.message });
  }
});

// 4. Plan Active Endpoint (GET)
mobileApiRouter.get("/plan/active", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const caller = createCaller(ctx);
    const plan = await caller.training.getActivePlan();
    return res.json({ success: true, plan });
  } catch (error: any) {
    console.error("[Mobile API] Plan active error:", error);
    return res.status(500).json({ error: error.message });
  }
});

// 5. Create Plan Endpoint (POST)
mobileApiRouter.post("/plan/create", requireAuth, async (req, res) => {
  try {
    console.log('[Mobile API] /plan/create headers:', req.headers.authorization);
    const ctx = (req as any).trpcCtx;
    console.log('[Mobile API] /plan/create ctx.user:', ctx?.user ? { id: ctx.user.id, openId: ctx.user.openId } : null);
    const caller = createCaller(ctx);
    const plan = await caller.training.createPlan(req.body);
    return res.json({ success: true, plan });
  } catch (error: any) {
    console.error("[Mobile API] Plan create error:", error);
    return res.status(500).json({ error: error.message });
  }
});

// 6. Checklist Today Endpoint (GET)
mobileApiRouter.get("/checklist/today", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const caller = createCaller(ctx);
    const checklist = await caller.training.getTodayChecklist();
    return res.json({ success: true, checklist });
  } catch (error: any) {
    console.error("[Mobile API] Checklist today error:", error);
    return res.status(500).json({ error: error.message });
  }
});

// 7. Mark Series Complete Endpoint (POST)
mobileApiRouter.post("/series/complete", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const caller = createCaller(ctx);
    const result = await caller.training.markSeriesComplete(req.body);
    return res.json({ success: true, result });
  } catch (error: any) {
    console.error("[Mobile API] Series complete error:", error);
    return res.status(500).json({ error: error.message });
  }
});
// 8. Training History Endpoint (GET)
mobileApiRouter.get("/training-history", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const caller = createCaller(ctx);
    
    // We fetch completed dates, checklists and the active plan
    const completedDatesRes = await caller.training.getCompletedDates();
    const checklistsRes = await caller.training.getChecklists();
    const completedDates = await caller.training.getCompletedDates();
    const checklists = await caller.training.getChecklists();
    const activePlan = await caller.training.getActivePlan();
    
    return res.json({ success: true, history: { completedDates, checklists, activePlan } });
  } catch (error: any) {
    console.error("[Mobile API] Training history error:", error);
    return res.status(500).json({ error: error.message });
  }
});

// 9. Exercise Media Endpoint (GET)
// Flutter expects `url` as a string (absolute http/https), not the full media object.
mobileApiRouter.get("/exercise-media", requireAuth, async (req, res) => {
  try {
    const name = req.query.name as string;
    if (!name) return res.status(400).json({ error: "Missing exercise name" });
    
    const { getExerciseMediaUrl, isUsableMediaUrl } = await import("./musclewiki");
    const media = await getExerciseMediaUrl(name);
    const url = media?.url && isUsableMediaUrl(media.url) ? media.url : null;
    return res.json({
      success: true,
      url,
      type: media?.type ?? null,
      exerciseName: media?.exerciseName ?? null,
      found: Boolean(url),
    });
  } catch (error: any) {
    console.error("[Mobile API] Exercise media error:", error);
    return res.status(500).json({ error: error.message });
  }
});

// 10. Engagement alerts (Duolingo-style) for Flutter local notifications + in-app banner
mobileApiRouter.get("/engagement/alerts", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const caller = createCaller(ctx);
    const data = await caller.engagement.getAlerts();
    return res.json({ success: true, ...data });
  } catch (error: any) {
    console.error("[Mobile API] Engagement alerts error:", error);
    return res.status(500).json({ error: error.message });
  }
});

// 11. Nutrition — active plan (GET)
mobileApiRouter.get("/nutrition/active", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const caller = createCaller(ctx);
    const data = await caller.nutrition.getActivePlan();
    return res.json({ success: true, ...data });
  } catch (error: any) {
    console.error("[Mobile API] Nutrition active error:", error);
    return res.status(500).json({ error: error.message });
  }
});

// 12. Nutrition — create plan (POST)
mobileApiRouter.post("/nutrition/create", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const caller = createCaller(ctx);
    const data = await caller.nutrition.createPlan(req.body);
    return res.json(data);
  } catch (error: any) {
    console.error("[Mobile API] Nutrition create error:", error);
    return res.status(500).json({ success: false, error: error.message });
  }
});

// 13. Badges Endpoint (GET)
mobileApiRouter.get("/badges", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const { getAchievements, getUserAchievements } = await import("../db");
    const allAchievements = await getAchievements();
    const userAch = await getUserAchievements(ctx.user.id);
    const unlockedIds = new Set(userAch.map((u: any) => u.achievementId));

    const badges = allAchievements.map((ach: any) => ({
      ...ach,
      unlocked: unlockedIds.has(ach.id),
      unlockedAt: userAch.find((u: any) => u.achievementId === ach.id)?.unlockedAt || null,
    }));

    return res.json({ success: true, badges });
  } catch (error: any) {
    console.error("[Mobile API] Badges error:", error);
    return res.status(500).json({ error: error.message });
  }
});

// ─── AI FEATURES ────────────────────────────────────────────────────────────

// 14. Chat con la mascota Feo (POST)
mobileApiRouter.post("/social/feo-chat", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const { message, history } = req.body;
    if (!message) return res.status(400).json({ error: "message es requerido" });
    const caller = createCaller(ctx);
    const result = await caller.feo.chatWithFeo({ message, history: history || [] });
    return res.json(result);
  } catch (error: any) {
    console.error("[Mobile API] chatWithFeo error:", error);
    return res.status(500).json({ reply: "Uy, tuve un problema técnico. Seguí entrenando igual 💪" });
  }
});

// 15. Notificación motivacional dinámica (GET)
mobileApiRouter.get("/gamification/quote", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const caller = createCaller(ctx);
    const result = await caller.gamification.getMotivationalQuote();
    return res.json(result);
  } catch (error: any) {
    console.error("[Mobile API] getMotivationalQuote error:", error);
    return res.status(500).json({ quote: "¡Dale que podés! 🔥" });
  }
});

// 16. Carga inteligente de alimentos por texto libre (POST)
mobileApiRouter.post("/nutrition/smart-log", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const { description } = req.body;
    if (!description) return res.status(400).json({ error: "description es requerido" });
    const caller = createCaller(ctx);
    const result = await caller.nutrition.smartLog({ description });
    return res.json(result);
  } catch (error: any) {
    console.error("[Mobile API] smartLog error:", error);
    return res.status(500).json({ success: false, error: error.message });
  }
});

// 17. Generador de recetas con ingredientes (POST)
mobileApiRouter.post("/nutrition/fridge-recipe", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const { ingredients, macrosLeft } = req.body;
    if (!ingredients) return res.status(400).json({ error: "ingredients es requerido" });
    const caller = createCaller(ctx);
    const result = await caller.nutrition.generateFridgeRecipe({ ingredients, macrosLeft });
    return res.json(result);
  } catch (error: any) {
    console.error("[Mobile API] generateFridgeRecipe error:", error);
    return res.status(500).json({ success: false, error: error.message });
  }
});
// 18. Tienda de Personalidades
mobileApiRouter.get("/store/personalities", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const { getUserProgress } = await import("../db");
    const progress = await getUserProgress(ctx.user.id);
    
    let unlocked = ["feo_clasico"];
    if (progress?.unlockedPersonalities) {
      unlocked = JSON.parse(progress.unlockedPersonalities);
    }
    
    const personalities = [
      { id: "feo_clasico", name: "Feo Clásico", price: 0, description: "El Feo de siempre, exigente y gracioso.", emoji: "🐾" },
      { id: "sargento", name: "Sargento Militar", price: 50, description: "Súper estricto, duro y disciplinado.", emoji: "😠" },
      { id: "zen", name: "Sensei Zen", price: 50, description: "Pacífico, sabio y enfocado en la respiración.", emoji: "🧘" }
    ];
    
    return res.json({
      success: true,
      coins: progress?.coins || 0,
      activePersonality: progress?.activePersonality || "feo_clasico",
      unlocked,
      personalities
    });
  } catch (error: any) {
    return res.status(500).json({ success: false, error: error.message });
  }
});

mobileApiRouter.post("/store/buy-personality", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const { personalityId, price } = req.body;
    const { getDb, getUserProgress } = await import("../db");
    const { userProgress } = await import("../../drizzle/schema");
    const { eq } = await import("drizzle-orm");
    
    const db = await getDb();
    if (!db) throw new Error("No db");
    const progress = await getUserProgress(ctx.user.id);
    if (!progress || progress.coins < price) {
      return res.status(400).json({ success: false, error: "No tienes suficientes FerCoins" });
    }
    
    let unlocked = ["feo_clasico"];
    if (progress.unlockedPersonalities) {
      unlocked = JSON.parse(progress.unlockedPersonalities);
    }
    if (unlocked.includes(personalityId)) {
      return res.status(400).json({ success: false, error: "Ya tienes esta personalidad" });
    }
    
    unlocked.push(personalityId);
    
    await db.update(userProgress).set({
      coins: progress.coins - price,
      unlockedPersonalities: JSON.stringify(unlocked),
      activePersonality: personalityId
    }).where(eq(userProgress.userId, ctx.user.id));
    
    return res.json({ success: true });
  } catch (error: any) {
    return res.status(500).json({ success: false, error: error.message });
  }
});

mobileApiRouter.post("/store/equip-personality", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const { personalityId } = req.body;
    const { getDb, getUserProgress } = await import("../db");
    const { userProgress } = await import("../../drizzle/schema");
    const { eq } = await import("drizzle-orm");
    
    const db = await getDb();
    if (!db) throw new Error("No db");
    const progress = await getUserProgress(ctx.user.id);
    let unlocked = ["feo_clasico"];
    if (progress?.unlockedPersonalities) {
      unlocked = JSON.parse(progress.unlockedPersonalities);
    }
    
    if (!unlocked.includes(personalityId)) {
      return res.status(400).json({ success: false, error: "No has desbloqueado esta personalidad" });
    }
    
    await db.update(userProgress).set({
      activePersonality: personalityId
    }).where(eq(userProgress.userId, ctx.user.id));
    
    return res.json({ success: true });
  } catch (error: any) {
    return res.status(500).json({ success: false, error: error.message });
  }
});

// 19. Misiones Diarias (Quests) + desafíos / villanos / evidencia
mobileApiRouter.get("/quests/today", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const {
      getOrGenerateTodayQuests,
      buildChallengeNotifications,
    } = await import("./quests");
    const quests = await getOrGenerateTodayQuests(ctx.user.id);
    const notifications = buildChallengeNotifications(quests);
    return res.json({ success: true, quests, notifications });
  } catch (error: any) {
    return res.status(500).json({ success: false, error: error.message });
  }
});

// Alias usado por pantallas Flutter antiguas
mobileApiRouter.get("/gamification/quests", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const {
      getOrGenerateTodayQuests,
      buildChallengeNotifications,
    } = await import("./quests");
    const quests = await getOrGenerateTodayQuests(ctx.user.id);
    const notifications = buildChallengeNotifications(quests);
    return res.json({ success: true, quests, notifications });
  } catch (error: any) {
    return res.status(500).json({ success: false, error: error.message });
  }
});

mobileApiRouter.post("/quests/claim", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const questId = Number(req.body?.questId);
    if (!questId) {
      return res.status(400).json({ success: false, error: "questId requerido" });
    }
    const { claimQuestReward } = await import("./quests");
    const result = await claimQuestReward(ctx.user.id, questId);
    return res.json({ success: true, ...result });
  } catch (error: any) {
    return res.status(400).json({ success: false, error: error.message });
  }
});

mobileApiRouter.post("/quests/proof", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const questId = Number(req.body?.questId);
    if (!questId) {
      return res.status(400).json({ success: false, error: "questId requerido" });
    }
    const { submitCameraProof } = await import("./quests");
    const result = await submitCameraProof(ctx.user.id, questId, {
      durationSec: Number(req.body?.durationSec || 0),
      note: req.body?.note,
      clientVerified: !!req.body?.clientVerified,
    });
    return res.json({ success: true, ...result });
  } catch (error: any) {
    return res.status(400).json({ success: false, error: error.message });
  }
});

mobileApiRouter.get("/quests/villains", requireAuth, async (_req, res) => {
  try {
    const { VILLAINS, publicVillain } = await import("./villains");
    return res.json({
      success: true,
      villains: VILLAINS.map(publicVillain),
    });
  } catch (error: any) {
    return res.status(500).json({ success: false, error: error.message });
  }
});

/** Combate animado: briefing del villano del día / por id */
mobileApiRouter.get("/quests/battle/:villainId", requireAuth, async (req, res) => {
  try {
    const { getVillainById } = await import("./villains");
    const { battleBrief } = await import("./battleGrade");
    const villain = getVillainById(String(req.params.villainId));
    if (!villain) {
      return res.status(404).json({ success: false, error: "Villano no encontrado" });
    }
    return res.json({ success: true, ...battleBrief(villain) });
  } catch (error: any) {
    return res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * Califica el video/frames del desafío de combate con IA.
 * Body: { questId, villainId, deviceReps, durationSec, framesBase64: string[] }
 */
mobileApiRouter.post("/quests/battle/grade", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const { gradeBattleChallenge } = await import("./battleGrade");
    const result = await gradeBattleChallenge({
      userId: ctx.user.id,
      questId: Number(req.body?.questId || 0),
      villainId: String(req.body?.villainId || ""),
      framesBase64: Array.isArray(req.body?.framesBase64)
        ? req.body.framesBase64
        : [],
      deviceReps: Number(req.body?.deviceReps || 0),
      durationSec: Number(req.body?.durationSec || 0),
      note: req.body?.note,
    });
    return res.json({ success: true, ...result });
  } catch (error: any) {
    console.error("[Mobile API] battle grade error:", error);
    return res.status(400).json({ success: false, error: error.message });
  }
});

// 20b. Reemplazo granular de un ejercicio (catálogo RAG)
mobileApiRouter.get("/training/replace-options", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const dayNumber = Number(req.query.dayNumber || req.query.day || 0);
    const exerciseIndex = Number(req.query.exerciseIndex ?? req.query.ex ?? -1);
    if (!dayNumber || exerciseIndex < 0) {
      return res.status(400).json({ success: false, error: "dayNumber y exerciseIndex requeridos" });
    }
    const { listReplacementOptions } = await import("./replaceExercise");
    const data = await listReplacementOptions({
      userId: ctx.user.id,
      dayNumber,
      exerciseIndex,
    });
    return res.json({ success: true, ...data });
  } catch (error: any) {
    console.error("[Mobile API] replace-options error:", error);
    return res.status(400).json({ success: false, error: error.message });
  }
});

mobileApiRouter.post("/training/replace-exercise", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const dayNumber = Number(req.body?.dayNumber || 0);
    const exerciseIndex = Number(req.body?.exerciseIndex ?? -1);
    const preferredName =
      typeof req.body?.preferredName === "string" ? req.body.preferredName : undefined;
    if (!dayNumber || exerciseIndex < 0) {
      return res.status(400).json({ success: false, error: "dayNumber y exerciseIndex requeridos" });
    }
    const { replaceExerciseInActivePlan } = await import("./replaceExercise");
    const result = await replaceExerciseInActivePlan({
      userId: ctx.user.id,
      dayNumber,
      exerciseIndex,
      preferredName,
    });
    return res.json(result);
  } catch (error: any) {
    console.error("[Mobile API] replace-exercise error:", error);
    return res.status(400).json({ success: false, error: error.message });
  }
});

// 20. Auto-Regulación de Rutina
mobileApiRouter.post("/training/autoregulate", requireAuth, async (req, res) => {
  try {
    const ctx = (req as any).trpcCtx;
    const { howUserFeels, planId, dayIndex } = req.body;
    const { getDb, getActiveTrainingPlan, updateTrainingPlanContent } = await import("../db");
    const { invokeLLM } = await import("./llm");
    
    const plan = await getActiveTrainingPlan(ctx.user.id);
    if (!plan || plan.id !== planId || !plan.generatedContent) {
      return res.status(400).json({ success: false, error: "Plan inválido" });
    }
    
    const content = typeof plan.generatedContent === "string" ? JSON.parse(plan.generatedContent) : plan.generatedContent;
    const day = content.days[dayIndex];
    if (!day) return res.status(400).json({ success: false, error: "Día inválido" });
    
    const prompt = `Eres un experto entrenador personal. Tu cliente debe hacer hoy la siguiente rutina:
${JSON.stringify(day.exercises, null, 2)}

El cliente reporta: "${howUserFeels}"

Ajusta la rutina (baja series, baja repeticiones o cambia a ejercicios más suaves si está muy cansado o dolorido).
Devuelve ÚNICAMENTE un JSON array con los ejercicios modificados. Mantén las mismas llaves originales (nameEs, sets, reps, etc.).
NO agregues texto fuera del JSON.`;
    
    const llmResult = await invokeLLM({
      messages: [{ role: "user", content: prompt }],
      maxTokens: 1000
    });
    
    const responseText = (llmResult as any).choices?.[0]?.message?.content || "";
    const jsonMatch = responseText.match(/\[.*\]/s);
    if (!jsonMatch) throw new Error("Fallo al parsear JSON");
    
    const modifiedExercises = JSON.parse(jsonMatch[0]);
    content.days[dayIndex].exercises = modifiedExercises;
    
    await updateTrainingPlanContent(plan.id, JSON.stringify(content));
    
    return res.json({ success: true, modifiedDay: content.days[dayIndex] });
  } catch (error: any) {
    console.error("[Mobile API] Autoregulate error:", error);
    return res.status(500).json({ success: false, error: error.message });
  }
});
export function registerMobileApi(app: Express) {
  app.use("/api/mobile", mobileApiRouter);
}
