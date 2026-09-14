import "dotenv/config";
import express from "express";
import { createServer } from "http";
import cors from "cors";
import { createExpressMiddleware } from "@trpc/server/adapters/express";
import { registerStorageProxy } from "./storageProxy";
import { appRouter } from "../routers";
import { createContext } from "./context";
import { registerMobileApi } from "./mobileApi";
import { registerOAuthRoutes } from "./oauth";
import { ENV } from "./env";

function isAllowedOrigin(origin) {
  if (!origin) return true;
  if (ENV.allowedOrigins.includes(origin)) return true;
  try {
    const host = new URL(origin).hostname;
    return host.endsWith(".vercel.app") || host === "localhost" || host === "127.0.0.1";
  } catch {
    return false;
  }
}

export function createApp() {
  const app = express();
  const corsOptions = {
    origin: (origin, callback) => {
      if (isAllowedOrigin(origin)) callback(null, true);
      else callback(new Error("Origen no permitido por CORS: " + origin));
    },
    credentials: true,
    methods: ["GET", "HEAD", "PUT", "PATCH", "POST", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "Cookie", "X-Requested-With", "Accept"],
  };
  app.use(cors(corsOptions));
  app.options("*", cors(corsOptions));
  app.use(express.json({ limit: "50mb" }));
  app.use(express.urlencoded({ limit: "50mb", extended: true }));
  registerStorageProxy(app);
  registerOAuthRoutes(app);
  app.get("/health", (_req, res) => res.status(200).json({ ok: true, service: "ferfit" }));
  app.get("/api/mobile/health", (_req, res) => res.status(200).json({ ok: true, service: "ferfit-mobile" }));
  registerMobileApi(app);
  app.use("/api/trpc", createExpressMiddleware({ router: appRouter, createContext }));
  return app;
}

const app = createApp();

async function startLocalServer() {
  const server = createServer(app);
  if (process.env.NODE_ENV === "development") {
    const { setupVite } = await import("./vite");
    await setupVite(app, server);
  } else {
    const { serveStatic } = await import("./vite");
    serveStatic(app);
  }
  const port = parseInt(process.env.PORT || "3000", 10);
  server.listen(port, "0.0.0.0", () => {
    console.log("Server running on http://0.0.0.0:" + port + "/");
  });
}

if (!process.env.VERCEL) {
  startLocalServer().catch(console.error);
}

export default app;
