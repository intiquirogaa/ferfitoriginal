# hy3bitacotra.md — Bitácora de trabajo (FerFit 2)

Registro cronológico de la sesión. Fecha: 2026-07-08.

---

## [1] Revisión inicial de la función de gráficos
- El usuario pidió revisar la función que genera los charts.
- Exploración: encontré varios puntos de gráficos:
  - `client/src/components/ProgressGraphs.tsx` (componente recharts bien estructurado).
  - `server/routers.ts` → `getDashboardData` genera `weeklyChart` (count por día).
  - `client/src/pages/Dashboard.tsx` → área chart "Weekly Progress" con datos mock (`steps`/`calories`).
  - `client/src/pages/Progreso.tsx` → `ProgressGraphs` con `exerciseProgressData` mock.
- Pregunté alcance: el usuario eligió **mejorar el flujo completo (backend + frontend)**.

## [2] Hallazgo crítico: datos falsos / tabla vacía
- Detecté que `exercise_history` (`drizzle/schema.ts:67`) y `getExerciseProgressStats` (`db.ts:266`) existían pero **nunca se insertaba nada** (`createExerciseHistory` no se invocaba).
- Conclusión: conectar los gráficos a "datos reales" mostraría pantalla vacía a menos que también se poblara la tabla.
- El usuario decidió: **también poblar la tabla** en el flujo de completar series.

## [3] Plan presentado y aprobado
- Plan: (a) upsert en `exercise_history` dentro de `markSeriesComplete`; (b) nuevo query `getExerciseProgress`; (c) `Progreso.tsx` con datos reales; (d) `Dashboard.tsx` área chart con `weeklyChart` real + limpieza de mock/código muerto.
- Usuario aprobó.

## [4] Implementación
- `server/routers.ts` `markSeriesComplete`: agregado upsert en `exercise_history` (usa `getExerciseHistoryByDay`, `createExerciseHistory`, `updateExerciseHistory`).
- `server/routers.ts`: nuevo query `getExerciseProgress` (mapea filas a `{date, weight, reps, sets, duration}`).
- `client/src/pages/Progreso.tsx`: reemplazado mock por `trpc.training.getExerciseProgress`; estado vacío agregado.
- `client/src/pages/Dashboard.tsx`: área chart usa `dashData.weeklyChart` (`count`); leyenda corregida; fallback vacío; eliminados `weeklyProgressData` y `WeeklyBarChart`.
- `server/_core/index.ts`: agregado import faltante `registerOAuthRoutes`.

## [5] Verificación typecheck
- `npm run check` fallaba por: (1) `registerOAuthRoutes` no definido (previo, corregido con import); (2) dos parámetros implícitos `any` en mi código (corregidos con anotación `any`).
- Resultado final: `tsc --noEmit` pasa limpio.

## [6] Reporte: app no carga (500)
- El usuario abrió la app y vio pantalla en blanco + 500 en `/@vite/client`, `/src/main.tsx`, `/@react-refresh`.
- Investigación: arranqué el server y probé con `curl`/PowerShell → **200 en todos los endpoints**. Deduje proceso viejo colgado en puerto 3000.
- Indiqué al usuario matar procesos node y reiniciar. El usuario seguía viendo 500.

## [7] Causa raíz del 500: bug CORS
- Al revisar el log real del server encontré: `Error: Origen no permitido por CORS: http://localhost:3000`.
- `server/_core/env.ts` tenía `allowedOrigins` por defecto en **puerto 5173**, pero el server corre en **3000**. El navegador manda `Origin: http://localhost:3000` → CORS rechaza → 500. `curl` no manda `Origin`, por eso daba 200.
- **Fix:** `env.ts:18` ampliado a incluir `http://localhost:3000` y `http://127.0.0.1:3000`.
- Verificación con header `Origin: http://localhost:3000`: todas las rutas devuelven **200**.

## [8] Explicación de arquitectura de gamificación
- Documenté para el usuario la lógica de:
  - **Designación de rutina**: `createPlan` → `generatePersonalizedPlanWithNutrition` (LLM) → `createTrainingPlan` (desactiva planes previos, singleton activo). `getActivePlan` enriquece al vuelo.
  - **Otorgamiento de puntos**: `markSeriesComplete` otorga +10/serie, -10 al desmarcar, +25 bonus por ejercicio completo; nivel = `floor(XP/500)+1`; racha simple + racha por frecuencia.
  - **Seguimiento**: `userProgress`, `dailyChecklists`, `exerciseHistory`; queries `getTodayChecklist`, `getChecklists`, `getCompletedDates`, `getDayDetails`, `getDashboardData`, `getStats`, `getExerciseProgress`.
- Señalé inconsistencias: doble cálculo de racha, `totalXP` sin clamp, `updateProgress` redundante, `getTodayChecklist` sin filtro por fecha.

## [9] Documento de hallazgos `hy3.md`
- Creé `C:\Ferfit 2\hy3.md` con: flujo de gráficos (antes/después), bug CORS, arquitectura de gamificación y bugs pendientes.

## [10] Bitácora `hy3bitacotra.md`
- Creación de este documento.

---

## Estado final
- `npm run check`: OK.
- Frontend carga tras fix CORS + limpieza de proceso viejo en puerto 3000.
- Gráficos conectados a datos reales (se llenan al completar series).
- Pendiente (opcional): corregir bugs menores de la §4 de `hy3.md`.
