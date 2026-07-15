import { int, mysqlEnum, mysqlTable, text, timestamp, varchar } from "drizzle-orm/mysql-core";

export const users = mysqlTable("users", {
  id: int("id").autoincrement().primaryKey(),
  openId: varchar("openId", { length: 64 }).notNull().unique(),
  name: text("name"),
  email: varchar("email", { length: 320 }),
  password: varchar("password", { length: 255 }),
  loginMethod: varchar("loginMethod", { length: 64 }),
  role: mysqlEnum("role", ["user", "admin"]).default("user").notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
  lastSignedIn: timestamp("lastSignedIn").defaultNow().notNull(),
});

export type User = typeof users.$inferSelect;
export type InsertUser = typeof users.$inferInsert;

export const trainingPlans = mysqlTable("training_plans", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("userId").notNull(),
  type: mysqlEnum("type", ["strength", "hypertrophy"]).notNull(),
  daysPerWeek: int("daysPerWeek").notNull(),
  durationWeeks: int("durationWeeks").default(12).notNull(),
  startDate: timestamp("startDate").defaultNow().notNull(),
  isActive: int("isActive").default(1).notNull(),
  generatedContent: text("generatedContent"),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type TrainingPlan = typeof trainingPlans.$inferSelect;
export type InsertTrainingPlan = typeof trainingPlans.$inferInsert;

export const dailyChecklists = mysqlTable("daily_checklists", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("userId").notNull(),
  trainingPlanId: int("trainingPlanId").notNull(),
  date: timestamp("date").defaultNow().notNull(),
  dayOfWeek: varchar("dayOfWeek", { length: 20 }).notNull(),
  totalSeries: int("totalSeries").notNull(),
  completedSeries: int("completedSeries").default(0).notNull(),
  isCompleted: int("isCompleted").default(0).notNull(),
  xpEarned: int("xpEarned").default(0).notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type DailyChecklist = typeof dailyChecklists.$inferSelect;
export type InsertDailyChecklist = typeof dailyChecklists.$inferInsert;

export const userProgress = mysqlTable("user_progress", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("userId").notNull().unique(),
  totalXP: int("totalXP").default(0).notNull(),
  level: int("level").default(1).notNull(),
  streak: int("streak").default(0).notNull(),
  coins: int("coins").default(0).notNull(),
  equippedSkin: varchar("equippedSkin", { length: 100 }),
  unlockedSkins: text("unlockedSkins"), // JSON string
  activePersonality: varchar("activePersonality", { length: 100 }).default("feo_clasico").notNull(),
  unlockedPersonalities: text("unlockedPersonalities"), // JSON string
  seriesCompletedHistorically: int("seriesCompletedHistorically").default(0).notNull(),
  seriesProgrammed: int("seriesProgrammed").default(0).notNull(),
  lastWorkoutDate: timestamp("lastWorkoutDate"),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type UserProgress = typeof userProgress.$inferSelect;
export type InsertUserProgress = typeof userProgress.$inferInsert;

export const exerciseHistory = mysqlTable("exercise_history", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("userId").notNull(),
  trainingPlanId: int("trainingPlanId").notNull(),
  dailyChecklistId: int("dailyChecklistId").notNull(),
  exerciseName: varchar("exerciseName", { length: 255 }).notNull(),
  dayNumber: int("dayNumber").notNull(),
  exerciseIndex: int("exerciseIndex").notNull(),
  plannedSets: int("plannedSets").notNull(),
  plannedReps: varchar("plannedReps", { length: 50 }).notNull(),
  completedSets: int("completedSets").default(0).notNull(),
  completedReps: varchar("completedReps", { length: 50 }),
  weight: int("weight"),
  duration: int("duration"),
  notes: text("notes"),
  isCompleted: int("isCompleted").default(0).notNull(),
  completedAt: timestamp("completedAt"),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type ExerciseHistory = typeof exerciseHistory.$inferSelect;
export type InsertExerciseHistory = typeof exerciseHistory.$inferInsert;

export const achievements = mysqlTable("achievements", {
  id: int("id").autoincrement().primaryKey(),
  name: varchar("name", { length: 255 }).notNull(),
  description: text("description").notNull(),
  icon: varchar("icon", { length: 50 }).notNull(),
  conditionType: varchar("conditionType", { length: 50 }).notNull(), // 'total_xp', 'streak_days', 'workouts_done', 'series_completed'
  conditionValue: int("conditionValue").notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
});

export type Achievement = typeof achievements.$inferSelect;
export type InsertAchievement = typeof achievements.$inferInsert;

export const userAchievements = mysqlTable("user_achievements", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("userId").notNull(),
  achievementId: int("achievementId").notNull(),
  unlockedAt: timestamp("unlockedAt").defaultNow().notNull(),
});

export type UserAchievement = typeof userAchievements.$inferSelect;
export type InsertUserAchievement = typeof userAchievements.$inferInsert;

export const mealLogs = mysqlTable("meal_logs", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("userId").notNull(),
  trainingPlanId: int("trainingPlanId").notNull(),
  date: timestamp("date").defaultNow().notNull(),
  mealNumber: int("mealNumber").notNull(),
  consumed: int("consumed").default(0).notNull(),
  notes: text("notes"),
  loggedAt: timestamp("loggedAt").defaultNow().notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type MealLog = typeof mealLogs.$inferSelect;
export type InsertMealLog = typeof mealLogs.$inferInsert;

export const nutritionPlans = mysqlTable("nutrition_plans", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("userId").notNull(),
  trainingPlanId: int("trainingPlanId"),
  isActive: int("isActive").default(1).notNull(),
  generatedContent: text("generatedContent"),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type NutritionPlan = typeof nutritionPlans.$inferSelect;
export type InsertNutritionPlan = typeof nutritionPlans.$inferInsert;

// --- FASE 4: MISIONES DIARIAS Y COFRES ---

export const dailyQuests = mysqlTable("daily_quests", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("userId").notNull(),
  date: timestamp("date").defaultNow().notNull(), // Fecha de la misión
  questType: varchar("questType", { length: 50 }).notNull(), // ej: 'series', 'xp', 'workout'
  targetValue: int("targetValue").notNull(), // ej: 10 (series) o 100 (xp)
  currentValue: int("currentValue").default(0).notNull(),
  rewardCoins: int("rewardCoins").default(10).notNull(),
  isCompleted: int("isCompleted").default(0).notNull(),
  chestClaimed: int("chestClaimed").default(0).notNull(),
});

export type DailyQuest = typeof dailyQuests.$inferSelect;
export type InsertDailyQuest = typeof dailyQuests.$inferInsert;

// --- FASE 5: LIGAS (LEADERBOARDS) ---

export const leagueParticipants = mysqlTable("league_participants", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("userId").notNull(),
  leagueId: int("leagueId").notNull(), // 1: Bronce, 2: Plata, 3: Oro, etc.
  groupId: int("groupId").notNull(), // Id del grupo de 30 personas
  weekStartDate: timestamp("weekStartDate").notNull(),
  weeklyXP: int("weeklyXP").default(0).notNull(),
  lastRank: int("lastRank"),
});

export type LeagueParticipant = typeof leagueParticipants.$inferSelect;
export type InsertLeagueParticipant = typeof leagueParticipants.$inferInsert;

// --- FASE 6: SOCIAL (AMIGOS Y FEED) ---

export const friends = mysqlTable("friends", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("userId").notNull(),
  friendId: int("friendId").notNull(),
  status: varchar("status", { length: 20 }).default("accepted").notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
});

export type Friend = typeof friends.$inferSelect;
export type InsertFriend = typeof friends.$inferInsert;

export const activityFeed = mysqlTable("activity_feed", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("userId").notNull(),
  type: varchar("type", { length: 50 }).notNull(), // ej: 'workout_complete', 'level_up', 'new_league'
  content: text("content"), // JSON con detalles
  highFives: int("highFives").default(0).notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
});

export type ActivityFeed = typeof activityFeed.$inferSelect;
export type InsertActivityFeed = typeof activityFeed.$inferInsert;
