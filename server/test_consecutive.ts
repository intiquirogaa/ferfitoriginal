import "dotenv/config";
import { invokeLLM } from "./_core/llm";

async function testConsecutiveUser() {
  console.log("Testing Mistral Chat API with consecutive user messages...");
  try {
    const res = await invokeLLM({
      messages: [
        { role: "system", content: "Sos Feo, un bulldog." },
        { role: "user", content: "Hola!" },
        { role: "user", content: "Cómo estás?" }
      ],
      maxTokens: 300,
    });
    console.log("Mistral Success Reply:", JSON.stringify(res.choices[0].message.content));
  } catch (e) {
    console.error("Mistral Error:", e);
  }
}

testConsecutiveUser();
