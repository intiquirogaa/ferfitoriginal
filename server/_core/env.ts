import "dotenv/config";

const INSECURE_JWT_DEFAULT = "change-me-to-a-long-random-string";

/**
 * Resuelve el secreto usado para firmar/verificar los JWT propios (auth móvil
 * y contexto tRPC). En producción falla de forma dura si el secreto está
 * ausente, es el valor de ejemplo o es demasiado corto: firmar/verificar con un
 * secreto público permitiría a cualquiera forjar un token para cualquier email.
 */
function resolveJwtSecret(): string {
  const secret = process.env.JWT_SECRET ?? "";
  const isProduction = process.env.NODE_ENV === "production";
  const isInsecure = !secret || secret === INSECURE_JWT_DEFAULT || secret.length < 32;

  if (isProduction && isInsecure) {
    throw new Error(
      "JWT_SECRET inseguro o ausente en producción. Definí JWT_SECRET con un valor aleatorio de al menos 32 caracteres (ej. `openssl rand -hex 32`)."
    );
  }
  if (isInsecure) {
    console.warn(
      "[SECURITY] JWT_SECRET usa un valor por defecto/inseguro. Solo aceptable en desarrollo; configuralo antes de desplegar."
    );
  }
  return secret || INSECURE_JWT_DEFAULT;
}

export const ENV = {
  appId: process.env.VITE_APP_ID ?? "",
  cookieSecret: process.env.JWT_SECRET ?? "",
  jwtSecret: resolveJwtSecret(),
  databaseUrl: process.env.DATABASE_URL ?? "",
  oAuthServerUrl: process.env.OAUTH_SERVER_URL ?? "",
  ownerOpenId: process.env.OWNER_OPEN_ID ?? "",
  isProduction: process.env.NODE_ENV === "production",
  forgeApiUrl: process.env.BUILT_IN_FORGE_API_URL ?? "",
  forgeApiKey: process.env.BUILT_IN_FORGE_API_KEY ?? "",
  muscleWikiApiKey: process.env.MUSCLE_WIKI_API_KEY ?? "",
  clerkPublishableKey:
    process.env.CLERK_PUBLISHABLE_KEY ??
    process.env.VITE_CLERK_PUBLISHABLE_KEY ??
    "",
  clerkJwksUrl: process.env.CLERK_JWKS_URL ?? "",
  // ─── LLM providers (OpenAI-compatible chat/completions) ───
  // Proveedor activo: "groq" | "opencodego" | "forge". Vacío = auto-detección.
  llmProvider: process.env.LLM_PROVIDER ?? "",
  // Groq
  groqApiKey: process.env.GROQ_SECRET_KEY ?? "",
  groqBaseUrl: process.env.GROQ_BASE_URL ?? "https://api.groq.com/openai/v1",
  groqModel: process.env.GROQ_MODEL ?? "llama-3.3-70b-versatile",
  // OpenCodeGo
  opencodegoApiKey: process.env.OPENCODEGO_SECRET_KEY ?? "",
  opencodegoBaseUrl: process.env.OPENCODEGO_BASE_URL ?? "https://api.opencodego.com/v1",
  opencodegoModel: process.env.OPENCODEGO_MODEL ?? "gpt-4o-mini",
  // Mistral
  mistralApiKey: process.env.MISTRAL_SECRET_KEY ?? "",
  mistralBaseUrl: process.env.MISTRAL_BASE_URL ?? "https://api.mistral.ai/v1",
  mistralModel: process.env.MISTRAL_MODEL ?? "mistral-large-latest",
  // Modelo global opcional que sobreescribe el default de cada provider
  llmModel: process.env.LLM_MODEL ?? "",
  allowedOrigins: (
    process.env.ALLOWED_ORIGINS ??
    "http://localhost:3000,http://127.0.0.1:3000,http://localhost:3001,http://127.0.0.1:3001,http://localhost:5173,http://127.0.0.1:5173"
  )
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean),
};
