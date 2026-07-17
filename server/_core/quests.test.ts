import { describe, it, expect } from "vitest";
import {
  exerciseMatchesVillain,
  pickVillainForDay,
  getVillainById,
} from "./villains";
import { buildChallengeNotifications, QUEST_CATALOG } from "./quests";

describe("villains", () => {
  it("matches exercises for Sedentario", () => {
    const v = getVillainById("sedentario")!;
    expect(exerciseMatchesVillain("Barbell Squat", v)).toBe(true);
    expect(exerciseMatchesVillain("Sentadilla goblet", v)).toBe(true);
    expect(exerciseMatchesVillain("Bench Press", v)).toBe(false);
  });

  it("picks stable villain for day seed", () => {
    const a = pickVillainForDay(42, "2026-7-16");
    const b = pickVillainForDay(42, "2026-7-16");
    expect(a.id).toBe(b.id);
  });

  it("core_flojo battle requires 20 crunch video", () => {
    const v = getVillainById("core_flojo")!;
    expect(v.battle.targetReps).toBe(20);
    expect(v.battle.exerciseNameEn.toLowerCase()).toContain("crunch");
    expect(v.battle.requiresVideo).toBe(true);
    expect(v.portraitAsset).toContain("core_flojo");
  });
});

describe("quests catalog", () => {
  it("has camera and villain types", () => {
    const types = QUEST_CATALOG.map((q) => q.type);
    expect(types).toContain("camera_proof");
    expect(types).toContain("defeat_villain");
    expect(types).toContain("complete_series");
  });

  it("builds future notifications only", () => {
    const hour = new Date().getHours();
    const quests = [
      {
        id: 1,
        done: false,
        isCompleted: false,
        kind: "challenge",
        title: "Test",
        coachNote: "Nota",
        notifyHours: [hour + 1 > 23 ? 23 : hour + 1, 3],
        villainName: null,
        description: "Desc",
      },
    ];
    const notifs = buildChallengeNotifications(quests);
    for (const n of notifs) {
      expect(n.hour).toBeGreaterThan(hour);
    }
  });
});
