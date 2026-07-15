-- Migration: meal_logs table for nutrition tracking
CREATE TABLE IF NOT EXISTS `meal_logs` (
  `id` int AUTO_INCREMENT PRIMARY KEY,
  `userId` int NOT NULL,
  `trainingPlanId` int NOT NULL,
  `date` timestamp DEFAULT NOW() NOT NULL,
  `mealNumber` int NOT NULL,
  `consumed` int DEFAULT 0 NOT NULL,
  `notes` text,
  `loggedAt` timestamp DEFAULT NOW() NOT NULL,
  `createdAt` timestamp DEFAULT NOW() NOT NULL,
  `updatedAt` timestamp DEFAULT NOW() ON UPDATE NOW() NOT NULL
);
