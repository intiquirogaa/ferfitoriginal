ALTER TABLE `user_progress` ADD `activePersonality` varchar(100) DEFAULT 'feo_clasico' NOT NULL;--> statement-breakpoint
ALTER TABLE `user_progress` ADD `unlockedPersonalities` text;--> statement-breakpoint
ALTER TABLE `users` ADD `password` varchar(255);