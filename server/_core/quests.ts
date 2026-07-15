import { getDb } from "../db";
import { dailyQuests } from "../../drizzle/schema";
import { eq, and } from "drizzle-orm";

export const QUEST_TYPES = [
  {
    type: "complete_series",
    description: "Completá 15 series en tus entrenamientos.",
    targetValue: 15,
    rewardCoins: 25,
  },
  {
    type: "talk_to_feo",
    description: "Hablá con Feo en el chat 3 veces.",
    targetValue: 3,
    rewardCoins: 10,
  },
  {
    type: "workout_early",
    description: "Entrená antes de las 10 AM.",
    targetValue: 1,
    rewardCoins: 30,
  },
  {
    type: "complete_day",
    description: "Completá todos los ejercicios del día.",
    targetValue: 1,
    rewardCoins: 50,
  },
];

export async function getOrGenerateTodayQuests(userId: number) {
  const db = await getDb();
  if (!db) return [];

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Fetch all quests for user
  const allQuests = await db
    .select()
    .from(dailyQuests)
    .where(eq(dailyQuests.userId, userId));

  // Filter for today's quests (done in JS to avoid complex SQL date comparisons)
  const todayQuests = allQuests.filter((q) => {
    const qDate = new Date(q.date);
    return (
      qDate.getFullYear() === today.getFullYear() &&
      qDate.getMonth() === today.getMonth() &&
      qDate.getDate() === today.getDate()
    );
  });

  if (todayQuests.length > 0) {
    return todayQuests;
  }

  // Generate 3 random unique quests
  const shuffled = [...QUEST_TYPES].sort(() => 0.5 - Math.random());
  const selected = shuffled.slice(0, 3);

  const insertedIds = [];
  for (const quest of selected) {
    const result = await db.insert(dailyQuests).values({
      userId,
      questType: quest.type,
      description: quest.description,
      targetValue: quest.targetValue,
      currentValue: 0,
      rewardCoins: quest.rewardCoins,
      isCompleted: 0,
      date: new Date(),
    });
    insertedIds.push(result[0].insertId);
  }

  // Fetch the newly inserted quests to return complete objects
  const newQuests = await db
    .select()
    .from(dailyQuests)
    .where(eq(dailyQuests.userId, userId));
    
  return newQuests.filter((q) => {
    const qDate = new Date(q.date);
    return (
      qDate.getFullYear() === today.getFullYear() &&
      qDate.getMonth() === today.getMonth() &&
      qDate.getDate() === today.getDate()
    );
  });
}

export async function progressQuest(userId: number, questType: string, amount: number = 1) {
  const db = await getDb();
  if (!db) return;
  
  const quests = await getOrGenerateTodayQuests(userId);
  const quest = quests.find(q => q.questType === questType && q.isCompleted === 0);
  
  if (quest) {
    const newValue = Math.min(quest.currentValue + amount, quest.targetValue);
    const isCompleted = newValue >= quest.targetValue ? 1 : 0;
    
    await db.update(dailyQuests)
      .set({ 
        currentValue: newValue,
        isCompleted: isCompleted,
      })
      .where(eq(dailyQuests.id, quest.id));
      
    // If just completed, maybe we don't grant coins immediately (the user claims the chest)
    // For now, let's keep it simple: coins are granted when they click the chest in the UI.
  }
}
