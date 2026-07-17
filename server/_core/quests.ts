/**
 * Motor de misiones diarias + desafíos del coach (Feo, tono entrenador personal).
 */
import { getDb } from "../db";
import { dailyQuests, userProgress } from "../../drizzle/schema";
import { eq, and } from "drizzle-orm";
import {
  VILLAINS,
  getVillainById,
  pickVillainForDay,
  exerciseMatchesVillain,
  type VillainDef,
} from "./villains";

export type QuestPayload = {
  title: string;
  description: string;
  coachNote?: string;
  requiresCamera?: boolean;
  villainId?: string;
  villainName?: string;
  exerciseKeywords?: string[];
  /** Horas locales sugeridas para notificar el desafío */
  notifyHours?: number[];
  kind?: "daily" | "challenge" | "villain";
  battle?: unknown;
  portraitAsset?: string;
  fightClipAsset?: string;
};

export type QuestTypeDef = {
  type: string;
  title: string;
  description: string;
  targetValue: number;
  rewardCoins: number;
  coachNote: string;
  requiresCamera?: boolean;
  kind: "daily" | "challenge" | "villain";
  notifyHours?: number[];
  weight: number;
};

/** Catálogo base — tono profesional de entrenador personal */
export const QUEST_CATALOG: QuestTypeDef[] = [
  {
    type: "complete_series",
    title: "Volumen de calidad",
    description: "Completá 12 series con buena técnica en tu sesión de hoy.",
    targetValue: 12,
    rewardCoins: 25,
    coachNote: "Priorizá control del movimiento. Si la forma se rompe, bajá la carga.",
    kind: "daily",
    weight: 3,
  },
  {
    type: "complete_day",
    title: "Cierre de sesión",
    description: "Completá todos los ejercicios programados para hoy.",
    targetValue: 1,
    rewardCoins: 50,
    coachNote: "Una sesión terminada vale más que tres a medias. Cerrá el plan del día.",
    kind: "daily",
    weight: 3,
  },
  {
    type: "talk_to_feo",
    title: "Consulta con el coach",
    description: "Hablá con Feo 2 veces (dudas de forma, carga o recuperación).",
    targetValue: 2,
    rewardCoins: 15,
    coachNote: "Usá el chat para afinar la sesión. Preguntas claras, mejores ajustes.",
    kind: "daily",
    weight: 2,
  },
  {
    type: "workout_early",
    title: "Sesión matutina",
    description: "Completá al menos 1 serie antes de las 10:00.",
    targetValue: 1,
    rewardCoins: 30,
    coachNote: "Entrena temprano cuando puedas: mejor adherencia y menos interferencias.",
    kind: "challenge",
    notifyHours: [7, 9],
    weight: 2,
  },
  {
    type: "camera_proof",
    title: "Evidencia de ejecución",
    description: "Grabá un clip corto (cámara) de un ejercicio de tu plan para validar la misión.",
    targetValue: 1,
    rewardCoins: 40,
    coachNote:
      "Grabá de perfil o ¾, cuerpo completo a la vista. No buscamos estética: buscamos técnica.",
    requiresCamera: true,
    kind: "challenge",
    notifyHours: [12, 17],
    weight: 2,
  },
  {
    type: "defeat_villain",
    title: "Enfrentá al villano",
    description: "Derrotá al villano del día con series del grupo muscular indicado.",
    targetValue: 8,
    rewardCoins: 35,
    coachNote: "Cada serie del grupo objetivo avanza el combate. Mantene el foco.",
    kind: "villain",
    notifyHours: [8, 15, 19],
    weight: 3,
  },
];

function dayKey(d = new Date()): string {
  return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
}

function isSameLocalDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

function parsePayload(raw: unknown): QuestPayload {
  if (!raw) return { title: "Misión", description: "" };
  if (typeof raw === "object") return raw as QuestPayload;
  try {
    return JSON.parse(String(raw)) as QuestPayload;
  } catch {
    return { title: "Misión", description: String(raw || "") };
  }
}

function serializePayload(p: QuestPayload): string {
  return JSON.stringify(p);
}

/** Adjunta campos legibles al cliente */
export function serializeQuestRow(row: any) {
  const payload = parsePayload(row.payload ?? row.description);
  const completed = Number(row.isCompleted) === 1;
  const claimed = Number(row.chestClaimed) === 1;
  return {
    id: row.id,
    questType: row.questType,
    type: row.questType,
    title: payload.title || row.questType,
    description: payload.description || payload.title || "",
    coachNote: payload.coachNote || "",
    targetValue: row.targetValue,
    target: row.targetValue,
    currentValue: row.currentValue,
    current: row.currentValue,
    rewardCoins: row.rewardCoins,
    coins: row.rewardCoins,
    isCompleted: completed,
    done: completed,
    chestClaimed: claimed,
    claimed,
    requiresCamera: !!payload.requiresCamera,
    kind: payload.kind || "daily",
    notifyHours: payload.notifyHours || [],
    villainId: payload.villainId,
    villainName: payload.villainName,
    exerciseKeywords: payload.exerciseKeywords || [],
    battle: payload.battle || null,
    portraitAsset: payload.portraitAsset || null,
    fightClipAsset: payload.fightClipAsset || null,
    payload,
  };
}

function buildVillainQuest(villain: VillainDef): {
  def: QuestTypeDef;
  payload: QuestPayload;
} {
  const b = villain.battle;
  return {
    def: {
      type: "defeat_villain",
      title: `Combate: ${villain.name}`,
      description: `${b.defenseLine} (también suman series del grupo: ${villain.seriesRequired}).`,
      targetValue: 1, // se completa al ganar el combate con video+IA (o al llenar series del grupo)
      rewardCoins: villain.rewardCoins,
      coachNote: villain.coachBrief,
      kind: "villain",
      notifyHours: [8, 15, 19],
      weight: 3,
      requiresCamera: true,
    },
    payload: {
      title: `Combate: ${villain.name} ${villain.icon}`,
      description: `${b.attackLine} ${b.defenseLine}`,
      coachNote: villain.coachBrief,
      kind: "villain",
      requiresCamera: true,
      villainId: villain.id,
      villainName: villain.name,
      exerciseKeywords: villain.exerciseKeywords,
      notifyHours: [8, 15, 19],
      battle: b,
      portraitAsset: villain.portraitAsset,
      fightClipAsset: villain.fightClipAsset,
    } as QuestPayload,
  };
}

function weightedPick(pool: QuestTypeDef[], n: number, seed: number): QuestTypeDef[] {
  const copy = [...pool];
  const picked: QuestTypeDef[] = [];
  let s = seed;
  while (picked.length < n && copy.length > 0) {
    const total = copy.reduce((a, q) => a + q.weight, 0);
    s = (s * 1103515245 + 12345) >>> 0;
    let r = s % total;
    let idx = 0;
    for (let i = 0; i < copy.length; i++) {
      r -= copy[i].weight;
      if (r < 0) {
        idx = i;
        break;
      }
    }
    picked.push(copy[idx]);
    copy.splice(idx, 1);
  }
  return picked;
}

export async function getOrGenerateTodayQuests(userId: number) {
  const db = await getDb();
  if (!db) return [];

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const allQuests = await db
    .select()
    .from(dailyQuests)
    .where(eq(dailyQuests.userId, userId));

  const todayQuests = allQuests.filter((q) => isSameLocalDay(new Date(q.date), today));

  if (todayQuests.length > 0) {
    return todayQuests.map(serializeQuestRow);
  }

  const seed = userId * 1000 + today.getDate() + today.getMonth() * 31;
  const villain = pickVillainForDay(userId, dayKey(today));
  const villainBuilt = buildVillainQuest(villain);

  // 1 villano + 2 misiones del catálogo (sin duplicar defeat_villain)
  const pool = QUEST_CATALOG.filter((q) => q.type !== "defeat_villain");
  const extras = weightedPick(pool, 2, seed);

  const toInsert: Array<{ def: QuestTypeDef; payload: QuestPayload }> = [
    villainBuilt,
    ...extras.map((def) => ({
      def,
      payload: {
        title: def.title,
        description: def.description,
        coachNote: def.coachNote,
        requiresCamera: def.requiresCamera,
        kind: def.kind,
        notifyHours: def.notifyHours,
      } as QuestPayload,
    })),
  ];

  for (const item of toInsert) {
    const values: any = {
      userId,
      questType: item.def.type,
      targetValue: item.def.targetValue,
      currentValue: 0,
      rewardCoins: item.def.rewardCoins,
      isCompleted: 0,
      chestClaimed: 0,
      date: new Date(),
    };
    // description / payload si existen en el schema
    values.description = item.payload.description;
    values.payload = serializePayload(item.payload);
    try {
      await db.insert(dailyQuests).values(values);
    } catch (e) {
      // Fallback si faltan columnas nuevas: insert mínimo
      console.warn("[quests] insert with payload failed, retrying minimal", e);
      await db.insert(dailyQuests).values({
        userId,
        questType: item.def.type,
        targetValue: item.def.targetValue,
        currentValue: 0,
        rewardCoins: item.def.rewardCoins,
        isCompleted: 0,
        chestClaimed: 0,
        date: new Date(),
      });
    }
  }

  const refreshed = await db
    .select()
    .from(dailyQuests)
    .where(eq(dailyQuests.userId, userId));

  return refreshed
    .filter((q) => isSameLocalDay(new Date(q.date), today))
    .map(serializeQuestRow);
}

/**
 * Avanza progreso de misiones. amount puede ser negativo al desmarcar.
 * exerciseName opcional: para villanos y contexto de camera_proof.
 */
export async function progressQuest(
  userId: number,
  questType: string,
  amount: number = 1,
  opts?: { exerciseName?: string; hourLocal?: number }
) {
  const db = await getDb();
  if (!db) return { updated: [] as number[] };

  const quests = await getOrGenerateTodayQuests(userId);
  const updated: number[] = [];

  // workout_early: solo cuenta si es antes de las 10
  if (questType === "complete_series" || questType === "workout_early") {
    const hour = opts?.hourLocal ?? new Date().getHours();
    if (hour < 10) {
      await bumpQuest(db, quests, userId, "workout_early", amount > 0 ? 1 : 0, updated);
    }
  }

  if (questType === "complete_series") {
    await bumpQuest(db, quests, userId, "complete_series", amount, updated);
    // El villano del día se completa por combate (video + IA), no por series sueltas.
    return { updated };
  }

  // Completar villano (p.ej. tras gradeBattleChallenge con amount alto)
  if (questType === "defeat_villain") {
    await bumpQuest(db, quests, userId, "defeat_villain", amount, updated);
    return { updated };
  }

  await bumpQuest(db, quests, userId, questType, amount, updated);
  return { updated };
}

function isQuestOpen(q: any): boolean {
  if (!q) return false;
  if (q.done === true) return false;
  if (q.isCompleted === true) return false;
  if (Number(q.isCompleted) === 1) return false;
  return true;
}

async function bumpQuest(
  db: any,
  quests: any[],
  _userId: number,
  questType: string,
  amount: number,
  updated: number[]
) {
  if (amount === 0) return;
  const quest = quests.find((q) => q.questType === questType && isQuestOpen(q));
  if (!quest) return;

  const target = Number(quest.targetValue ?? quest.target ?? 1);
  const current = Number(quest.currentValue ?? quest.current ?? 0);
  const newValue = Math.max(0, Math.min(current + amount, target));
  const isCompleted = newValue >= target ? 1 : 0;

  await db
    .update(dailyQuests)
    .set({
      currentValue: newValue,
      isCompleted,
    })
    .where(eq(dailyQuests.id, quest.id));

  updated.push(quest.id);
  quest.currentValue = newValue;
  quest.current = newValue;
  quest.isCompleted = isCompleted === 1;
  quest.done = isCompleted === 1;
}

export async function claimQuestReward(userId: number, questId: number) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");

  const rows = await db
    .select()
    .from(dailyQuests)
    .where(and(eq(dailyQuests.id, questId), eq(dailyQuests.userId, userId)));

  const quest = rows[0];
  if (!quest) throw new Error("Misión no encontrada");
  if (Number(quest.isCompleted) !== 1) throw new Error("La misión aún no está completa");
  if (Number(quest.chestClaimed) === 1) {
    return { alreadyClaimed: true, coins: 0, totalCoins: 0, message: "Recompensa ya reclamada." };
  }

  const reward = quest.rewardCoins || 0;
  const progressRows = await db
    .select()
    .from(userProgress)
    .where(eq(userProgress.userId, userId));
  const progress = progressRows[0];
  if (!progress) throw new Error("Progreso de usuario no encontrado");

  const totalCoins = (progress.coins || 0) + reward;
  await db
    .update(userProgress)
    .set({ coins: totalCoins })
    .where(eq(userProgress.userId, userId));

  await db
    .update(dailyQuests)
    .set({ chestClaimed: 1 })
    .where(eq(dailyQuests.id, questId));

  const payload = parsePayload((quest as any).payload ?? (quest as any).description);
  let defeatLine: string | undefined;
  if (quest.questType === "defeat_villain" && payload.villainId) {
    defeatLine = getVillainById(payload.villainId)?.defeatLine;
  }

  return {
    alreadyClaimed: false,
    coins: reward,
    totalCoins,
    message:
      defeatLine ||
      "Recompensa acreditada. Buen trabajo: la consistencia construye resultados.",
    villainName: payload.villainName,
  };
}

/** Valida evidencia de cámara: marca camera_proof como completa */
export async function submitCameraProof(
  userId: number,
  questId: number,
  meta?: { durationSec?: number; note?: string; clientVerified?: boolean }
) {
  const db = await getDb();
  if (!db) throw new Error("Database not available");

  const rows = await db
    .select()
    .from(dailyQuests)
    .where(and(eq(dailyQuests.id, questId), eq(dailyQuests.userId, userId)));
  const quest = rows[0];
  if (!quest) throw new Error("Misión no encontrada");
  if (quest.questType !== "camera_proof" && quest.questType !== "defeat_villain") {
    // Permitimos proof opcional en otras misiones, pero el progreso principal es camera_proof
  }

  // Mínimo 3s de grabación o verificación cliente
  const duration = meta?.durationSec ?? 0;
  if (duration > 0 && duration < 3 && !meta?.clientVerified) {
    throw new Error("El clip debe durar al menos 3 segundos.");
  }

  // Completar camera_proof del día
  await progressQuest(userId, "camera_proof", 99);

  // Si el questId era camera_proof, forzar complete
  if (quest.questType === "camera_proof") {
    await db
      .update(dailyQuests)
      .set({
        currentValue: quest.targetValue,
        isCompleted: 1,
      })
      .where(eq(dailyQuests.id, questId));
  }

  // Guardar nota de proof en payload si hay columna
  try {
    const payload = parsePayload((quest as any).payload);
    const next = {
      ...payload,
      proof: {
        submittedAt: new Date().toISOString(),
        durationSec: duration,
        note: meta?.note || "clip_local",
        clientVerified: !!meta?.clientVerified,
      },
    };
    await db
      .update(dailyQuests)
      .set({ payload: serializePayload(next) } as any)
      .where(eq(dailyQuests.id, questId));
  } catch {
    // columna payload opcional
  }

  return {
    success: true,
    message:
      "Evidencia registrada. Revisá el progreso de la misión y reclamá la recompensa al completarla.",
  };
}

/** Payload para programar notificaciones locales de desafíos */
export function buildChallengeNotifications(quests: any[]) {
  const now = new Date();
  const notifications: Array<{
    id: number;
    title: string;
    body: string;
    hour: number;
    questId: number;
  }> = [];

  for (const q of quests) {
    if (q.done || q.isCompleted) continue;
    const hours: number[] = q.notifyHours || [];
    if (!hours.length) continue;
    for (const hour of hours) {
      if (hour <= now.getHours()) continue;
      notifications.push({
        id: 7000 + Number(q.id) * 10 + hour,
        title:
          q.kind === "villain"
            ? `Desafío: ${q.villainName || q.title}`
            : `Desafío del coach · ${q.title}`,
        body:
          q.coachNote ||
          q.description ||
          "Tu entrenador dejó un desafío para esta franja horaria.",
        hour,
        questId: Number(q.id),
      });
    }
  }
  return notifications;
}

export { VILLAINS, getVillainById };
