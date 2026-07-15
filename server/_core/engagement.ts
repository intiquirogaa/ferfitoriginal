/**
 * Motor de alertas estilo Duolingo para FerFit.
 * Genera mensajes in-app + instrucciones de notificaciones locales
 * según racha, XP, plan activo y días sin entrenar.
 */

export type EngagementAlertType =
  | "missed_you"
  | "streak_at_risk"
  | "close_to_level"
  | "close_to_streak_goal"
  | "daily_nudge"
  | "welcome_back"
  | "no_plan"
  | "keep_streak";

export type EngagementAction =
  | "open_workout"
  | "open_dashboard"
  | "create_plan";

export interface EngagementAlert {
  id: string;
  type: EngagementAlertType;
  priority: number;
  emoji: string;
  title: string;
  body: string;
  cta: string;
  action: EngagementAction;
  dismissible: boolean;
}

export interface ScheduledNotificationHint {
  /** ID estable para cancelar/reprogramar en el cliente */
  id: number;
  type: EngagementAlertType | "daily_reminder";
  title: string;
  body: string;
  schedule: {
    kind: "daily_at" | "in_days_at" | "today_at";
    hour: number;
    minute: number;
    /** Solo para in_days_at */
    daysFromNow?: number;
  };
}

export interface EngagementInput {
  hasActivePlan: boolean;
  daysPerWeek: number;
  totalXP: number;
  level: number;
  streak: number;
  lastWorkoutDate: Date | string | null;
  /** Si el checklist de hoy tiene series y no está completo */
  hasTrainingToday: boolean;
  todayCompleted: boolean;
  todayProgressRatio: number; // 0..1
  userName?: string | null;
  now?: Date;
}

export interface EngagementResult {
  alerts: EngagementAlert[];
  primary: EngagementAlert | null;
  scheduledNotifications: ScheduledNotificationHint[];
  meta: {
    daysSinceLastWorkout: number | null;
    maxAllowedGap: number;
    xpToNextLevel: number;
    xpProgressRatio: number;
    trainedToday: boolean;
  };
}

const STREAK_MILESTONES = [3, 7, 14, 30, 60, 100];
const XP_PER_LEVEL = 500;

function startOfDay(d: Date): Date {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x;
}

function daysBetween(a: Date, b: Date): number {
  const ms = startOfDay(b).getTime() - startOfDay(a).getTime();
  return Math.floor(ms / (1000 * 60 * 60 * 24));
}

function pickName(name?: string | null): string {
  const n = (name || "").trim().split(/\s+/)[0];
  return n || "campeón";
}

function maxGapForFrequency(daysPerWeek: number): number {
  const frequency = daysPerWeek >= 2 ? daysPerWeek : 3;
  return Math.ceil(7 / frequency) + 1;
}

function nextStreakMilestone(streak: number): number | null {
  return STREAK_MILESTONES.find((m) => m > streak) ?? null;
}

/** Nombre oficial de la mascota de FerFit */
export const MASCOT_NAME = "Feo";

/** Variantes de copy para no repetir siempre lo mismo (habla Feo) */
function missedYouCopy(days: number, name: string, streak: number): { title: string; body: string; emoji: string } {
  if (days >= 7) {
    return {
      emoji: "💔",
      title: `${name}, ${MASCOT_NAME} te extraña mucho`,
      body: `Hace ${days} días que no entrenás. ${MASCOT_NAME} sigue acá con tu plan — un día a la vez y volvés.`,
    };
  }
  if (days >= 4) {
    return {
      emoji: "😢",
      title: `¡Hey ${name}, ${MASCOT_NAME} te extraña!`,
      body: `Llevás ${days} días sin entrenar. ${MASCOT_NAME} no es lo mismo sin vos. ¿Arrancamos hoy?`,
    };
  }
  if (streak > 0) {
    return {
      emoji: "👀",
      title: `${name}, ${MASCOT_NAME} cuida tu racha`,
      body: `Hace ${days} días del último entrenamiento. ${MASCOT_NAME} te espera para no perder el ritmo.`,
    };
  }
  return {
    emoji: "💪",
    title: `¡${MASCOT_NAME} te extraña, ${name}!`,
    body: `Hace ${days} días sin moverte. Un entrenamiento corto ya cuenta — vamos con ${MASCOT_NAME}.`,
  };
}

export function buildEngagement(input: EngagementInput): EngagementResult {
  const now = input.now ?? new Date();
  const name = pickName(input.userName);
  const daysPerWeek = input.daysPerWeek || 3;
  const maxAllowedGap = maxGapForFrequency(daysPerWeek);
  const totalXP = Math.max(0, input.totalXP || 0);
  const level = input.level || Math.floor(totalXP / XP_PER_LEVEL) + 1;
  const xpInLevel = totalXP % XP_PER_LEVEL;
  const xpToNextLevel = XP_PER_LEVEL - xpInLevel;
  const xpProgressRatio = xpInLevel / XP_PER_LEVEL;

  let daysSinceLastWorkout: number | null = null;
  if (input.lastWorkoutDate) {
    const last = new Date(input.lastWorkoutDate);
    if (!Number.isNaN(last.getTime())) {
      daysSinceLastWorkout = Math.max(0, daysBetween(last, now));
    }
  }

  const trainedToday =
    input.todayCompleted ||
    daysSinceLastWorkout === 0 ||
    (input.todayProgressRatio > 0 && input.hasTrainingToday);

  const alerts: EngagementAlert[] = [];

  // 1) Sin plan
  if (!input.hasActivePlan) {
    alerts.push({
      id: "no_plan",
      type: "no_plan",
      priority: 90,
      emoji: "🎯",
      title: `${name}, ${MASCOT_NAME} quiere tu plan`,
      body: `Todavía no tenés una rutina. Generala con IA y ${MASCOT_NAME} te acompaña día a día.`,
      cta: "Crear plan",
      action: "create_plan",
      dismissible: true,
    });
  }

  // 1b) Tiene plan pero nunca entrenó
  if (input.hasActivePlan && daysSinceLastWorkout === null && !trainedToday) {
    alerts.push({
      id: "first_workout",
      type: "daily_nudge",
      priority: 85,
      emoji: "🚀",
      title: `${name}, ¡${MASCOT_NAME} te espera en el gym!`,
      body: `Todavía no registraste un entrenamiento. El primer día es el más importante — ${MASCOT_NAME} va con vos.`,
      cta: "Empezar hoy",
      action: "open_workout",
      dismissible: true,
    });
  }

  // 2) Te extrañamos (inactividad)
  if (input.hasActivePlan && daysSinceLastWorkout !== null && daysSinceLastWorkout >= 2 && !trainedToday) {
    const copy = missedYouCopy(daysSinceLastWorkout, name, input.streak || 0);
    alerts.push({
      id: `missed_you_${daysSinceLastWorkout}`,
      type: "missed_you",
      priority: 100 + Math.min(daysSinceLastWorkout, 14),
      emoji: copy.emoji,
      title: copy.title,
      body: copy.body,
      cta: "Entrenar ahora",
      action: "open_workout",
      dismissible: true,
    });
  }

  // 3) Racha en riesgo
  if (
    input.hasActivePlan &&
    (input.streak || 0) >= 2 &&
    !trainedToday &&
    daysSinceLastWorkout !== null &&
    daysSinceLastWorkout >= 1 &&
    daysSinceLastWorkout < maxAllowedGap
  ) {
    const daysLeft = maxAllowedGap - daysSinceLastWorkout;
    alerts.push({
      id: "streak_at_risk",
      type: "streak_at_risk",
      priority: 95,
      emoji: "🔥",
      title: `¡${MASCOT_NAME} ve tu racha de ${input.streak} en peligro!`,
      body:
        daysLeft <= 1
          ? `${name}, si no entrenás hoy podés perder la racha. ¡${MASCOT_NAME} no quiere que caiga!`
          : `Te quedan ~${daysLeft} día${daysLeft === 1 ? "" : "s"}. ${MASCOT_NAME} dice: un rato alcanza.`,
      cta: "Salvar racha",
      action: "open_workout",
      dismissible: true,
    });
  }

  // 4) Cerca del siguiente nivel
  if (input.hasActivePlan && xpToNextLevel > 0 && xpToNextLevel <= 100) {
    alerts.push({
      id: "close_to_level",
      type: "close_to_level",
      priority: 80,
      emoji: "⭐",
      title: `¡${MASCOT_NAME} ve el nivel ${level + 1} cerca!`,
      body: `Te faltan solo ${xpToNextLevel} XP. Un par de series y lo desbloqueás.`,
      cta: "Sumar XP",
      action: "open_workout",
      dismissible: true,
    });
  } else if (input.hasActivePlan && xpProgressRatio >= 0.8 && xpToNextLevel > 100) {
    alerts.push({
      id: "close_to_level_soft",
      type: "close_to_level",
      priority: 70,
      emoji: "🚀",
      title: `${MASCOT_NAME}: vas ${Math.round(xpProgressRatio * 100)}% al nivel ${level + 1}`,
      body: `Quedan ${xpToNextLevel} XP. La constancia te acerca al siguiente nivel.`,
      cta: "Seguir",
      action: "open_workout",
      dismissible: true,
    });
  }

  // 5) Cerca de hito de racha
  const nextMilestone = nextStreakMilestone(input.streak || 0);
  if (input.hasActivePlan && nextMilestone && nextMilestone - (input.streak || 0) === 1 && trainedToday === false) {
    alerts.push({
      id: `streak_goal_${nextMilestone}`,
      type: "close_to_streak_goal",
      priority: 75,
      emoji: "🏆",
      title: `¡${MASCOT_NAME}: a 1 día del hito de ${nextMilestone}!`,
      body: `Entrená hoy y llegás a ${nextMilestone} días de racha. ${MASCOT_NAME} ya está celebrando.`,
      cta: "Completar día",
      action: "open_workout",
      dismissible: true,
    });
  }

  // 6) Empujón diario si hay entrenamiento pendiente
  if (
    input.hasActivePlan &&
    input.hasTrainingToday &&
    !input.todayCompleted &&
    !trainedToday &&
    (daysSinceLastWorkout === null || daysSinceLastWorkout <= 1)
  ) {
    const pct = Math.round((input.todayProgressRatio || 0) * 100);
    alerts.push({
      id: "daily_nudge",
      type: "daily_nudge",
      priority: 60,
      emoji: pct > 0 ? "⚡" : "📅",
      title: pct > 0 ? `${MASCOT_NAME}: llevás ${pct}% del día` : `${MASCOT_NAME}: hoy se entrena`,
      body:
        pct > 0
          ? `Ya arrancaste — terminá las series. ${MASCOT_NAME} te banca.`
          : `${name}, tu rutina de hoy te espera. ¡Dale con ${MASCOT_NAME}!`,
      cta: pct > 0 ? "Continuar" : "Empezar",
      action: "open_workout",
      dismissible: true,
    });
  }

  // 7) Mantener racha (refuerzo positivo si entrenó hoy y tiene racha)
  if (trainedToday && (input.streak || 0) >= 2) {
    alerts.push({
      id: "keep_streak",
      type: "keep_streak",
      priority: 40,
      emoji: "🔥",
      title: `¡${MASCOT_NAME} celebra tu racha de ${input.streak}!`,
      body: "Imparable. Mañana Feo te espera de nuevo para no romperla.",
      cta: "Ver progreso",
      action: "open_dashboard",
      dismissible: true,
    });
  }

  // 8) Bienvenida de vuelta si volvió después de gap largo (entrenó hoy y gap previo grande)
  if (trainedToday && daysSinceLastWorkout === 0 && (input.streak || 0) <= 1) {
    // no last long gap info in same day; skip or soft welcome
  }

  alerts.sort((a, b) => b.priority - a.priority);
  const primary = alerts[0] ?? null;

  // ─── Notificaciones locales sugeridas ─────────────────────────
  const scheduledNotifications: ScheduledNotificationHint[] = [];

  if (input.hasActivePlan) {
    scheduledNotifications.push({
      id: 1001,
      type: "daily_reminder",
      title: `⏰ ${MASCOT_NAME}: hora de moverte`,
      body: `${name}, ¿entrenamos hoy? ${MASCOT_NAME} y tu plan te esperan.`,
      schedule: { kind: "daily_at", hour: 18, minute: 0 },
    });

    if ((input.streak || 0) >= 2) {
      scheduledNotifications.push({
        id: 1002,
        type: "streak_at_risk",
        title: `🔥 ${MASCOT_NAME}: no pierdas tu racha`,
        body: `Tu racha de ${input.streak} días te necesita. Un entrenamiento corto alcanza.`,
        schedule: { kind: "daily_at", hour: 20, minute: 30 },
      });
    }

    if (daysSinceLastWorkout === null || daysSinceLastWorkout >= 1) {
      const baseDays = daysSinceLastWorkout === null ? 2 : Math.max(1, 2 - daysSinceLastWorkout);
      scheduledNotifications.push({
        id: 1003,
        type: "missed_you",
        title: `😢 ${MASCOT_NAME} te extraña`,
        body: `${name}, hace rato que no pasás. Volvé un rato — ${MASCOT_NAME} te espera.`,
        schedule: { kind: "in_days_at", hour: 10, minute: 30, daysFromNow: Math.max(1, baseDays) },
      });
      scheduledNotifications.push({
        id: 1004,
        type: "missed_you",
        title: `💔 ${MASCOT_NAME}: ¿todo bien?`,
        body: `Tu plan sigue listo. Un día a la vez — ${MASCOT_NAME} no se va a ninguna parte.`,
        schedule: { kind: "in_days_at", hour: 11, minute: 0, daysFromNow: Math.max(2, baseDays + 2) },
      });
    }

    if (xpToNextLevel <= 100 && xpToNextLevel > 0 && !trainedToday) {
      scheduledNotifications.push({
        id: 1005,
        type: "close_to_level",
        title: `⭐ ${MASCOT_NAME}: a ${xpToNextLevel} XP del nivel ${level + 1}`,
        body: "Estás a un entrenamiento de subir de nivel. ¡Dale!",
        schedule: { kind: "today_at", hour: 17, minute: 0 },
      });
    }
  } else {
    scheduledNotifications.push({
      id: 1006,
      type: "no_plan",
      title: `🎯 ${MASCOT_NAME} quiere tu plan`,
      body: "En 2 minutos armamos tu rutina personalizada con IA.",
      schedule: { kind: "in_days_at", hour: 12, minute: 0, daysFromNow: 1 },
    });
  }

  return {
    alerts,
    primary,
    scheduledNotifications,
    meta: {
      daysSinceLastWorkout,
      maxAllowedGap,
      xpToNextLevel,
      xpProgressRatio,
      trainedToday,
    },
  };
}
