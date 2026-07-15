ALTER TABLE `user_progress` ADD `coins` int DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE `user_progress` ADD `equippedSkin` varchar(100);--> statement-breakpoint
ALTER TABLE `user_progress` ADD `unlockedSkins` text;