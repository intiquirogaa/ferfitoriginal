/**
 * Califica un desafío de combate (video/frames) con IA + reglas del coach.
 */
import { invokeLLM } from "./llm";
import { getVillainById, type VillainDef } from "./villains";
import { progressQuest } from "./quests";

export type GradeBattleInput = {
  userId: number;
  questId: number;
  villainId: string;
  /** Frames JPEG/PNG en data URL o base64 puro (máx ~6) */
  framesBase64?: string[];
  /** Conteo de reps estimado en el dispositivo (pose) */
  deviceReps?: number;
  durationSec?: number;
  note?: string;
};

export type GradeBattleResult = {
  success: boolean;
  passed: boolean;
  estimatedReps: number;
  targetReps: number;
  formScore: number; // 0-100
  coachFeedback: string;
  attackResolved: boolean;
  coinsHint: number;
  villainName: string;
  phase: "victory" | "retry" | "partial";
};

function toDataUrl(raw: string): string {
  const s = raw.trim();
  if (s.startsWith("data:")) return s;
  return `data:image/jpeg;base64,${s}`;
}

function parseJsonLoose(text: string): any {
  try {
    return JSON.parse(text);
  } catch {
    const m = text.match(/\{[\s\S]*\}/);
    if (m) {
      try {
        return JSON.parse(m[0]);
      } catch {
        return null;
      }
    }
    return null;
  }
}

export async function gradeBattleChallenge(
  input: GradeBattleInput
): Promise<GradeBattleResult> {
  const villain = getVillainById(input.villainId);
  if (!villain) {
    throw new Error("Villano no encontrado");
  }
  const battle = villain.battle;
  const target = battle.targetReps;
  const deviceReps = Math.max(0, Math.floor(input.deviceReps ?? 0));
  const frames = (input.framesBase64 || []).slice(0, 6).map(toDataUrl);

  let aiReps = deviceReps;
  let formScore = deviceReps >= target ? 70 : Math.round((deviceReps / target) * 60);
  let coachFeedback =
    "Evaluación local de movimiento. Mantené el control y el rango completo.";

  if (frames.length > 0) {
    try {
      const content: any[] = [
        {
          type: "text",
          text: `Sos Feo, entrenador personal profesional de FerFit. Evaluá si el cliente realizó el desafío de combate.

EJERCICIO ESPERADO: ${battle.exerciseNameEs} (${battle.exerciseNameEn})
REPETICIONES OBJETIVO: ${target}
CONTEO DEL DISPOSITIVO (pose): ${deviceReps}
DURACIÓN CLIP (s): ${input.durationSec ?? "n/d"}

Mirás los fotogramas del video. Respondé SOLO JSON válido:
{
  "estimatedReps": number,
  "formScore": number,          // 0-100 técnica
  "isCorrectExercise": boolean,
  "passed": boolean,            // true si reps>=objetivo y ejercicio correcto y formScore>=50
  "coachFeedback": string       // 1-2 oraciones, tono profesional PT, español rioplatense correcto
}

Criterios:
- Contá solo repeticiones con rango razonable.
- Si no se ve el ejercicio o la cámara es inválida, passed=false y formScore bajo.
- No seas permisivo con 0 movimiento visible.
- Sé justo: si el conteo del dispositivo es alto y los frames son coherentes, podés confiar en él.`,
        },
        ...frames.map((url) => ({
          type: "image_url" as const,
          image_url: { url, detail: "low" as const },
        })),
      ];

      const result = await invokeLLM({
        messages: [
          {
            role: "system",
            content:
              "Evaluás técnica y cumplimiento de desafíos de fitness. Respuestas solo JSON.",
          },
          { role: "user", content },
        ],
        maxTokens: 400,
        responseFormat: { type: "json_object" },
      });

      const raw = String((result as any).choices?.[0]?.message?.content || "");
      const parsed = parseJsonLoose(raw);
      if (parsed) {
        aiReps = Math.max(
          deviceReps,
          Math.floor(Number(parsed.estimatedReps) || 0)
        );
        // Si la IA estima menos pero el device contó bien y dice ejercicio correcto, promediar
        if (
          parsed.isCorrectExercise !== false &&
          deviceReps > 0 &&
          (Number(parsed.estimatedReps) || 0) < deviceReps
        ) {
          aiReps = Math.round((deviceReps + Number(parsed.estimatedReps || 0)) / 2);
          if (deviceReps >= target && Number(parsed.formScore) >= 45) {
            aiReps = Math.max(aiReps, deviceReps);
          }
        }
        formScore = Math.max(
          0,
          Math.min(100, Math.floor(Number(parsed.formScore) || formScore))
        );
        coachFeedback =
          String(parsed.coachFeedback || coachFeedback).slice(0, 400) ||
          coachFeedback;
      }
    } catch (e) {
      console.warn("[battleGrade] LLM vision failed, using device reps", e);
      coachFeedback =
        deviceReps >= target
          ? "Validación por sensores del dispositivo. Buen trabajo; revisá la técnica en el espejo."
          : `Detecté ~${deviceReps}/${target} reps en el dispositivo. Completá el objetivo y reintentá.`;
    }
  } else if (deviceReps <= 0) {
    coachFeedback =
      "No recibí frames ni conteo de movimiento. Grabá de nuevo con el cuerpo a la vista.";
    formScore = 0;
  }

  const passed =
    aiReps >= target && formScore >= 45 && (frames.length > 0 || deviceReps >= target);

  if (passed) {
    // Completar misión villano del día
    await progressQuest(input.userId, "defeat_villain", 999, {
      exerciseName: battle.exerciseNameEn,
    });
    // Si hay questId específico, forzar complete vía progress ya cubierto
    await progressQuest(input.userId, "camera_proof", 99);
  }

  return {
    success: true,
    passed,
    estimatedReps: aiReps,
    targetReps: target,
    formScore,
    coachFeedback: passed
      ? `${villain.battle.successLine} ${coachFeedback}`
      : `${villain.battle.failLine} ${coachFeedback}`,
    attackResolved: passed,
    coinsHint: passed ? villain.rewardCoins : 0,
    villainName: villain.name,
    phase: passed ? "victory" : aiReps >= Math.ceil(target * 0.5) ? "partial" : "retry",
  };
}

export function battleBrief(villain: VillainDef) {
  return {
    villain: {
      id: villain.id,
      name: villain.name,
      epithet: villain.epithet,
      icon: villain.icon,
      portraitAsset: villain.portraitAsset,
      defeatLine: villain.defeatLine,
    },
    battle: villain.battle,
    feoDefendAsset: "assets/battle/feo_defend.jpg",
    feoVictoryAsset: "assets/battle/feo_victory.jpg",
    fightClipAsset: villain.fightClipAsset,
    victoryClipAsset: "assets/battle/fight_victory.mp4",
  };
}
