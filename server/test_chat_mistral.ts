import "dotenv/config";
import { invokeLLM } from "./_core/llm";

async function testChat() {
  console.log("Testing Mistral Chat API...");
  try {
    const res = await invokeLLM({
      messages: [
        { role: "system", content: "Sos Feo, un bulldog." },
        { role: "user", content: "Hola!" }
      ],
      maxTokens: 300,
    });
    console.log("Mistral Success Reply:", JSON.stringify(res.choices[0].message.content));
  } catch (e) {
    console.error("Mistral Error:", e);
  }
}

testChat();
