import { publicProcedure, router } from "../_core/trpc";
import { z } from "zod";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const EXERCISES_DIR = path.join(__dirname, "../_core/exercises");

export const exerciseRouter = router({
  getIdealPosture: publicProcedure
    .input(z.object({ exerciseName: z.string() }))
    .query(async ({ input }) => {
      try {
        const fileName = input.exerciseName.toLowerCase().replace(/\s+/g, "_") + ".json";
        const filePath = path.join(EXERCISES_DIR, fileName);
        
        if (!fs.existsSync(filePath)) {
          throw new Error(`Exercise posture file not found: ${fileName}`);
        }
        
        const fileContent = fs.readFileSync(filePath, "utf-8");
        const postureData = JSON.parse(fileContent);
        
        return postureData;
      } catch (error) {
        console.error("Error loading ideal posture:", error);
        throw new Error("Failed to load ideal posture");
      }
    }),
});