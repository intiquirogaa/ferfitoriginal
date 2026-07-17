import { describe, expect, it } from "vitest";
import {
  findExerciseGroup,
  getReplacementCandidates,
  pickReplacementExercise,
  resolveCatalogName,
} from "./catalog";

describe("catalog replace helpers", () => {
  it("finds muscle group for known exercises", () => {
    expect(findExerciseGroup("Bench Press")).toBe("CHEST");
    expect(findExerciseGroup("pull-up")).toBe("BACK");
    expect(findExerciseGroup("Bodyweight Squat")).toBe("LEGS");
  });

  it("resolves canonical catalog names", () => {
    expect(resolveCatalogName("bench press")).toBe("Bench Press");
    expect(resolveCatalogName("Dumbbell Curl")).toBe("Dumbbell Curl");
  });

  it("excludes current and day exercises from candidates", () => {
    const { group, candidates } = getReplacementCandidates({
      currentName: "Bench Press",
      dayExerciseNames: ["Bench Press", "Push-up", "Incline Bench Press"],
    });
    expect(group).toBe("CHEST");
    expect(candidates).not.toContain("Bench Press");
    expect(candidates).not.toContain("Push-up");
    expect(candidates).not.toContain("Incline Bench Press");
    expect(candidates.length).toBeGreaterThan(0);
  });

  it("picks preferred replacement when valid", () => {
    const picked = pickReplacementExercise({
      currentName: "Bench Press",
      dayExerciseNames: ["Bench Press"],
      preferredName: "Dumbbell Flyes",
    });
    expect(picked?.name).toBe("Dumbbell Flyes");
    expect(picked?.alternatives).not.toContain("Dumbbell Flyes");
  });

  it("auto-picks a different exercise from same group", () => {
    const picked = pickReplacementExercise({
      currentName: "Plank",
      dayExerciseNames: ["Plank"],
    });
    expect(picked).not.toBeNull();
    expect(picked!.name).not.toBe("Plank");
    expect(findExerciseGroup(picked!.name)).toBe("CORE");
  });
});
