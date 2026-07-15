import { createUser } from "./server/db";
import crypto from "crypto";

async function run() {
  try {
    const newUser = await createUser({
      openId: crypto.randomUUID(),
      name: "TestUser",
      email: "test3@gmail.com",
      password: "password123",
      loginMethod: "local"
    });
    console.log("Success:", newUser);
  } catch (err) {
    console.error("Error creating user:", err);
  }
  process.exit(0);
}
run();
