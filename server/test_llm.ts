import * as dotenv from "dotenv";
dotenv.config();

import { invokeLLM } from "./_core/llm";
import { ENV } from "./_core/env";

async function run() {
  console.log("Using Provider:", ENV.llmProvider);
  console.log("Model:", ENV.groqModel);
  try {
    const res = await invokeLLM({
      messages: [{ role: "user", content: "Hola, ¿funcionas?" }],
      maxTokens: 50,
    });
    console.log("Success:", JSON.stringify(res.choices[0].message.content));
  } catch (e) {
    console.error("Error:", e);
  }
}

run();
