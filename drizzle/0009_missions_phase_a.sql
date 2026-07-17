-- Phase A: misiones, villanos, evidencia de cámara (payload flexible)
ALTER TABLE `daily_quests` ADD COLUMN `description` text;
--> statement-breakpoint
ALTER TABLE `daily_quests` ADD COLUMN `payload` text;
