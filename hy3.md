# hy3.md — Hallazgos de la sesión (FerFit 2)

Documentación de lo revisado y corregido respecto a los **gráficos**, el **bug que rompía el frontend** y la **lógica de gamificación** (puntos, rutina y seguimiento).

---

## 1. Flujo de gráficos (backend + frontend)

### Estado inicial (problemas)
- `client/src/components/ProgressGraphs.tsx` está bien estructurado, pero en `client/src/pages/Progreso.tsx` (líneas ~132-145) recibía **datos mock** (`exerciseProgressData` con "Press de Banca" / "Dominadas" inventados).
- El backend ya tenía la tabla `exercise_history` (`drizzle/schema.ts:67`) y la función `getExerciseProgressStats` (`server/db.ts:266`), pero **ningún endpoint tRPC la exponía** y **nunca se insertaba nada** (`createExerciseHistory` no se invoca en `routers.ts`).
- En `client/src/pages/Dashboard.tsx`:
  - El área chart "Weekly Progress" usaba `weeklyProgressData` mock con `steps`/`calories` que la app ni registra.
  - `dashData.weeklyChart` (real, `routers.ts`) se consultaba pero **nunca se usaba**.
  - `WeeklyBarChart` (`Dashboard.tsx:362`) era **código muerto**.

### Cambios realizados
1. **`server/routers.ts` — `markSeriesComplete` (~línea 455):** se agregó un **upsert en `exercise_history`** por cada ejercicio/día al completar (o desmarcar) series. Usa `db.getExerciseHistoryByDay` + `createExerciseHistory`/`updateExerciseHistory`.
2. **`server/routers.ts` — nuevo query `getExerciseProgress` (~línea 493):** lee el historial real desde `exercise_history`, mapea filas a `{ date, weight, reps, sets, duration }` (parsea `completedReps` varchar promediando series) y devuelve `[{ exerciseName, data }]`.
3. **`client/src/pages/Progreso.tsx`:** reemplazó el mock por `trpc.training.getExerciseProgress.useQuery()`; agregó estado vacío elegante.
4. **`client/src/pages/Dashboard.tsx`:**
   - El área chart ahora consume `dashData.weeklyChart` con `dataKey="count"`.
   - Se corrigió la leyenda engañosa ("Pasos"/"Calorías" → "Entrenamientos").
   - Fallback vacío si no hay datos esa semana.
   - Se eliminaron el mock `weeklyProgressData` y el `WeeklyBarChart` muerto.
5. **`server/_core/index.ts`:** se agregó el import faltante `registerOAuthRoutes` (error previo que dejaba el typecheck roto).

### Verificación
- `npm run check` (tsc) pasa limpio.
- El server arranca y sirve `/`, `/@vite/client`, `/src/main.tsx` y `/@react-refresh` con 200.

---

## 2. Bug que rompía el frontend (CORS)

### Síntoma
Pantalla en blanco + `GET http://localhost:3000/@vite/client 500`, `/src/main.tsx 500`, `/@react-refresh 500`.

### Causa raíz
`server/_core/env.ts` definía `allowedOrigins` por defecto como
`http://localhost:5173,http://127.0.0.1:5173`, pero el server corre en el **puerto 3000**.

El navegador envía `Origin: http://localhost:3000` en cada request (vite client, main.tsx, etc.) y el middleware CORS (`server/_core/index.ts:44`) lo rechazaba → **500 en todo**. Las pruebas con `curl`/PowerShell no mandaban header `Origin`, por eso parecían funcionar (200).

### Fix
En `server/_core/env.ts:18` se agregó el puerto 3000 a los orígenes permitidos:
`http://localhost:3000,http://127.0.0.1:3000,http://localhost:5173,http://127.0.0.1:5173`.

### Nota
Las advertencias `MaxListenersExceededWarning` / `contentscript.js` / `ObjectMultiplex` en la consola provienen de una **extensión del navegador** (wallet/crypto), no de la app — son ruido.

---

## 3. Arquitectura de gamificación

Toda la lógica vive en el router `training` (`server/routers.ts`) apoyado por `server/db.ts` y las tablas `userProgress`, `dailyChecklists`, `exerciseHistory`.

### 3.1 Designación de rutina
- **`training.createPlan`** (`routers.ts:37`): recibe `objective`, `experienceLevel`, `age`, `weight`, `height`, `daysPerWeek`, `equipment`, `injuries`, `preferences`. Llama a `generatePersonalizedPlanWithNutrition` (LLM) y normaliza el tipo a `"strength"` | `"hypertrophy"`.
- **`db.createTrainingPlan`** (`db.ts:86`): **desactiva todos los planes previos** (`isActive=0`) e inserta el nuevo con `isActive=1` → un solo plan activo (singleton).
- **`training.getActivePlan`** (`routers.ts:97`): devuelve el plan activo y lo **enriquece al vuelo** (GIFs musclewiki + traducción a español), persistiendo cambios.
- **`generateDemoRoutine`** (`routers.ts:246`): plan demo hardcodeado (hipertrofia, 4 días).
- El contenido es JSON: `{ days: [ { focus, exercises: [ { name, sets, reps, gifUrl, nameEn, seriesCompleted:{}, seriesWeights:{}, seriesReps:{} } ] } ] }`. El tracking por serie se guarda como **mapas dentro del JSON**, no normalizado.

### 3.2 Otorgamiento de puntos (XP)
Núcleo en **`training.markSeriesComplete`** (`routers.ts:295`):
- Reglas: `+10` por serie completada, `-10` al desmarcar; bonus `+25` cuando **todas** las series del ejercicio quedan completas.
- `db.updateUserProgress(userId, xpGained, deltaSeries)` (`db.ts:204`):
  - `newXP = totalXP + xpToAdd`; **nivel = `floor(newXP/500)+1`** (umbral 500 XP).
  - `seriesCompletedHistorically += deltaSeries`.
  - Racha: si `diffDays===1` → `+1`; si `>1` → reset a `1`.
- Al completar el día entero se recalcula la racha con **lógica por frecuencia** (margen `ceil(7/daysPerWeek)+1`) y sobreescribe `streak`.
- `db.checkAndUnlockAchievements` (`db.ts:359`): evalúa logros por `conditionType` (`total_xp`, `streak_days`, `series_completed`, `workouts_done`) vs `conditionValue`.

### 3.3 Seguimiento (tracking)
- `getTodayChecklist` (`routers.ts:149`): devuelve el checklist **más reciente** (`orderBy createdAt limit 1`) — no filtra estrictamente por fecha de hoy.
- `getChecklists` / `getUserChecklists`: todos los checklists.
- `getCompletedDates` (`routers.ts:607`): fechas con `isCompleted=1`.
- `getDayDetails(date)` (`routers.ts:617`): junta checklist + día del plan por índice de weekday.
- `getDashboardData` (`routers.ts:635`): `weeklyChart` (conteo por día de la semana actual), `recentWorkouts` (últimos 3), `activityFeed` (hitos).
- `getStats` (`routers.ts:192`): agrega series programadas/completadas, entrenamientos y XP.
- `getExerciseProgress` (nuevo): historial por ejercicio desde `exercise_history`.

**Nota de diseño:** el progreso por ejercicio existe en dos lugares — los mapas del JSON del plan (fuente de verdad) y la tabla `exercise_history` (log para gráficos).

---

## 4. Inconsistencias / bugs menores detectados (pendientes)
1. **Racha calculada dos veces**: simple en `updateUserProgress` y la de frecuencia en `markSeriesComplete`; gana la segunda.
2. **`totalXP` sin clamp** en `updateUserProgress` (`db.ts:213`): al desmarcar series puede bajar de 0 (en `markSeriesComplete` hay `Math.max(0,...)` solo para el return, pero el DB se escribe negativo).
3. **`updateProgress`** (`routers.ts:160`) es un mutation redundante no usado por `markSeriesComplete`.
4. **`getTodayChecklist`** no filtra por fecha real de hoy, solo por `createdAt`.

---

## 5. Estado
- `npm run check`: OK.
- Frontend carga tras corregir CORS y limpiar procesos viejos en el puerto 3000.
- Gráficos conectados a datos reales (se pueblan al completar series).
