CREATE TABLE `nutrition_plans` (
  `id` int AUTO_INCREMENT PRIMARY KEY,
  `userId` int NOT NULL,
  `trainingPlanId` int,
  `isActive` int DEFAULT 1 NOT NULL,
  `generatedContent` text,
  `createdAt` timestamp DEFAULT NOW() NOT NULL,
  `updatedAt` timestamp DEFAULT NOW() ON UPDATE NOW() NOT NULL
);
