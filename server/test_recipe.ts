import "dotenv/config";
import { invokeLLM } from "./_core/llm";

async function testRecipe() {
  console.log("Testing Mistral Recipe Generation...");
  try {
    const res = await invokeLLM({
      messages: [
        { role: "system", content: "Sos un chef nutricionista. Creá UNA receta rápida. Devolvés SOLO JSON." },
        { role: "user", content: "Ingredientes disponibles: Pollo, arroz, cebolla." }
      ],
      maxTokens: 800,
      responseFormat: { type: "json_object" },
    });
    console.log("Mistral Success Reply:", JSON.stringify(res.choices[0].message.content));
  } catch (e) {
    console.error("Mistral Error:", e);
  }
}

testRecipe();
