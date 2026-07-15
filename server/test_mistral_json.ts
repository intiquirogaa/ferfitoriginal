import "dotenv/config";
import { invokeLLM } from "./_core/llm";
import { ENV } from "./_core/env";

async function testMistralJson() {
  console.log("Using Provider:", ENV.llmProvider);
  console.log("Model:", ENV.mistralModel);
  try {
    const res = await invokeLLM({
      messages: [{ role: "user", content: "Genera un usuario de prueba. Devuelve nombre y edad." }],
      maxTokens: 100,
      outputSchema: {
        name: "TestUser",
        schema: {
          type: "object",
          properties: {
            nombre: { type: "string" },
            edad: { type: "number" }
          },
          required: ["nombre", "edad"]
        },
        strict: true
      }
    });
    console.log("Mistral Success Reply:", JSON.stringify(res.choices[0].message.content));
  } catch (e) {
    console.error("Mistral Error:", e);
  }
}

testMistralJson();
