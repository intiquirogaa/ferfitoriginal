import { createCaller } from "./routers";
import { createContext } from "./_core/context";
import * as db from "./db";

async function run() {
  const openId = "user_3GNZObd2gPisfnF6RlnRLIIY4C8";
  const user = await db.getUserByOpenId(openId);
  const ctx = { req: {} as any, res: {} as any, user };
  const caller = createCaller(ctx);

  const plan = await caller.training.getActivePlan();
  console.log("Plan ID:", plan?.id);

  try {
    const result = await caller.training.markSeriesComplete({
      trainingPlanId: plan!.id,
      dayNumber: 1,
      exerciseIndex: 0,
      seriesIndex: 0,
      completed: true,
    });
    console.log("Result:", result);
  } catch (error: any) {
    console.error("Error:", error);
  }
}

run();
