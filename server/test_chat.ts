import "dotenv/config";
import { appRouter } from "./routers";
import { createContext } from "./_core/context";

async function testChat() {
  const caller = appRouter.createCaller({
    user: { id: "test_user", name: "Tester", email: "test@test.com" } as any,
    req: {} as any,
    res: {} as any,
  });

  console.log("=== Testing Feo Chat ===");
  try {
    const res = await caller.social.chatWithFeo({
      message: "Hola Feo, ¿cómo estás?",
      history: []
    });
    console.log("Feo replied:", res.reply);
  } catch (error) {
    console.error("Feo Chat Error:", error);
  }
}

testChat();
