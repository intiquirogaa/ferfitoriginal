import "dotenv/config";
import express from "express";
import cors from "cors";
import { createExpressMiddleware } from "@trpc/server/adapters/express";
import { registerStorageProxy } from "./server/_core/storageProxy";
import { appRouter } from "./server/routers";
import { createContext } from "./server/_core/context";
import { registerMobileApi } from "./server/_core/mobileApi";
import { registerOAuthRoutes } from "./server/_core/oauth";
import { ENV } from "./server/_core/env";

export const config = { maxDuration: 300 };

const app = express();
app.use(
  cors({
    origin: (origin, cb) => {
      if (!origin) return cb(null, true);
      try {
        const host = new URL(origin).hostname;
        if (ENV.allowedOrigins.includes(origin) || host.endsWith(".vercel.app")) return cb(null, true);
      } catch {}
      cb(new Error("CORS: " + origin));
    },
    credentials: true,
  })
);
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ limit: "50mb", extended: true }));
registerStorageProxy(app);
registerOAuthRoutes(app);
app.get("/health", (_req, res) => res.json({ ok: true, service: "ferfit" }));
app.get("/api/mobile/health", (_req, res) => res.json({ ok: true, service: "ferfit-mobile" }));
registerMobileApi(app);
app.use("/api/trpc", createExpressMiddleware({ router: appRouter, createContext }));
export default app;
