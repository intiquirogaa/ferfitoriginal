import type { CreateExpressContextOptions } from "@trpc/server/adapters/express";
import type { User } from "../../drizzle/schema";
import * as db from "../db";
import { ENV } from "./env";
import jwt from "jsonwebtoken";

export type TrpcContext = {
  req: CreateExpressContextOptions["req"];
  res: CreateExpressContextOptions["res"];
  user: User | null;
};

type LocalClaims = {
  id: number;
  openId: string;
  email: string;
};

async function verifyLocalToken(token: string): Promise<LocalClaims | null> {
  try {
    const secret = process.env.JWT_SECRET || "change-me-to-a-long-random-string";
    const decoded = jwt.verify(token, secret) as LocalClaims;
    return decoded;
  } catch (error) {
    return null;
  }
}

export async function createContext(
  opts: CreateExpressContextOptions
): Promise<TrpcContext> {
  let user: User | null = null;

  const authHeader = opts.req.headers.authorization;
  if (typeof authHeader === "string" && authHeader.startsWith("Bearer ")) {
    const token = authHeader.slice(7);
    
    // Dev bypass
    if (token === "dev_bypass_token") {
      const email = "uripichipi@gmail.com";
      let dbUser = await db.getUserByEmail(email);
      if (!dbUser) {
        dbUser = await db.createUser({
          openId: "dev-uuid",
          name: "Uri",
          email,
          loginMethod: "local",
          lastSignedIn: new Date(),
        });
      }
      return { req: opts.req, res: opts.res, user: dbUser };
    }
    
    const claims = await verifyLocalToken(token);
    if (claims?.email) {
      let dbUser = await db.getUserByEmail(claims.email);
      if (dbUser) {
        user = dbUser;
      }
    }
  }

  return {
    req: opts.req,
    res: opts.res,
    user,
  };
}
