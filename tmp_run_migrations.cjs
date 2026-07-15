const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

async function main() {
  const url = process.env.DATABASE_URL;
  if (!url) {
    console.error('DATABASE_URL no está configurada');
    process.exit(1);
  }
  const conn = await mysql.createConnection(url);
  const files = [
    'drizzle/0006_meal_logs.sql',
    'drizzle/0007_nutrition_plans.sql',
  ];
  for (const f of files) {
    const sql = fs.readFileSync(path.join(__dirname, f), 'utf-8');
    console.log(`Ejecutando ${f}...`);
    try {
      await conn.query(sql);
      console.log(`OK ${f}`);
    } catch (err) {
      console.error(`Error en ${f}:`, err.message);
    }
  }
  await conn.end();
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
