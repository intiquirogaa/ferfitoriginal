CREATE TABLE `activity_feed` (
	`id` int AUTO_INCREMENT NOT NULL,
	`userId` int NOT NULL,
	`type` varchar(50) NOT NULL,
	`content` text,
	`highFives` int NOT NULL DEFAULT 0,
	`createdAt` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `activity_feed_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `daily_quests` (
	`id` int AUTO_INCREMENT NOT NULL,
	`userId` int NOT NULL,
	`date` timestamp NOT NULL DEFAULT (now()),
	`questType` varchar(50) NOT NULL,
	`targetValue` int NOT NULL,
	`currentValue` int NOT NULL DEFAULT 0,
	`rewardCoins` int NOT NULL DEFAULT 10,
	`isCompleted` int NOT NULL DEFAULT 0,
	`chestClaimed` int NOT NULL DEFAULT 0,
	CONSTRAINT `daily_quests_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `friends` (
	`id` int AUTO_INCREMENT NOT NULL,
	`userId` int NOT NULL,
	`friendId` int NOT NULL,
	`status` varchar(20) NOT NULL DEFAULT 'accepted',
	`createdAt` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `friends_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `league_participants` (
	`id` int AUTO_INCREMENT NOT NULL,
	`userId` int NOT NULL,
	`leagueId` int NOT NULL,
	`groupId` int NOT NULL,
	`weekStartDate` timestamp NOT NULL,
	`weeklyXP` int NOT NULL DEFAULT 0,
	`lastRank` int,
	CONSTRAINT `league_participants_id` PRIMARY KEY(`id`)
);
