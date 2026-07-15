import { describe, it, expect } from "vitest";
import { buildEngagement } from "./engagement";

describe("buildEngagement", () => {
  const base = {
    hasActivePlan: true,
    daysPerWeek: 3,
    totalXP: 450,
    level: 1,
    streak: 5,
    lastWorkoutDate: null as Date | null,
    hasTrainingToday: true,
    todayCompleted: false,
    todayProgressRatio: 0,
    userName: "Inti",
    now: new Date("2026-07-08T15:00:00"),
  };

  it("genera missed_you cuando pasan varios días sin entrenar", () => {
    const last = new Date("2026-07-03T12:00:00");
    const result = buildEngagement({ ...base, lastWorkoutDate: last });
    const missed = result.alerts.find((a) => a.type === "missed_you");
    expect(missed).toBeTruthy();
    expect(missed!.title.toLowerCase()).toMatch(/feo|extrañ/);
    expect(result.meta.daysSinceLastWorkout).toBe(5);
  });

  it("marca racha en riesgo si hay streak y no entrenó hoy", () => {
    const last = new Date("2026-07-07T12:00:00");
    const result = buildEngagement({
      ...base,
      lastWorkoutDate: last,
      streak: 6,
    });
    expect(result.alerts.some((a) => a.type === "streak_at_risk")).toBe(true);
  });

  it("avisa cuando está cerca de subir de nivel", () => {
    const result = buildEngagement({
      ...base,
      totalXP: 470,
      lastWorkoutDate: new Date("2026-07-08T10:00:00"),
      todayCompleted: false,
      todayProgressRatio: 0,
    });
    const close = result.alerts.find((a) => a.type === "close_to_level");
    expect(close).toBeTruthy();
    expect(result.meta.xpToNextLevel).toBe(30);
  });

  it("sugiere crear plan si no hay plan activo", () => {
    const result = buildEngagement({
      ...base,
      hasActivePlan: false,
      lastWorkoutDate: null,
    });
    expect(result.primary?.type).toBe("no_plan");
    expect(result.scheduledNotifications.some((n) => n.type === "no_plan")).toBe(true);
  });

  it("incluye recordatorio diario en scheduledNotifications", () => {
    const result = buildEngagement({
      ...base,
      lastWorkoutDate: new Date("2026-07-08T09:00:00"),
    });
    expect(result.scheduledNotifications.some((n) => n.id === 1001)).toBe(true);
  });
});
