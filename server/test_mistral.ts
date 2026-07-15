import "dotenv/config";
import { invokeLLM } from "./_core/llm";
import { ENV } from "./_core/env";

async function testMistral() {
  console.log("Using Provider:", ENV.llmProvider);
  console.log("Model:", ENV.mistralModel);
  try {
    const res = await invokeLLM({
      messages: [{ role: "user", content: "Hola, ¿funcionas como Mistral?" }],
      maxTokens: 50,
    });
    console.log("Mistral Success Reply:", JSON.stringify(res.choices[0].message.content));
  } catch (e) {
    console.error("Mistral Error:", e);
  }
}

testMistral();
