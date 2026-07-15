import mysql from "mysql2/promise";
import "dotenv/config";

async function run() {
  const conn = await mysql.createConnection(process.env.DATABASE_URL!);
  const [rows] = await conn.execute("DESCRIBE user_progress");
  console.log(rows);
  await conn.end();
}
run();
