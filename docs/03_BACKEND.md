# 03 · Backend (`server/`)

> Última actualización: 2026-07-04

## 1. Arquitectura general

Express 4 + tRPC 11, con un router REST adicional para la app móvil. No hay separación formal en capas (controller/service/repository); el patrón real es:

- **`server/routers.ts`** — capa de "controladores" tRPC (definición de procedures) **y** el motor de generación de planes con IA (todo en un único archivo de ~1260 líneas).
- **`server/db.ts`** — capa de acceso a datos (funciones planas sobre Drizzle, sin clases repositorio).
- **`server/_core/*`** — infraestructura transversal: servidor HTTP, contexto/auth de tRPC, integraciones externas (LLM, ExerciseDB, Clerk), y remanentes de la plataforma de scaffolding "Manus".
- **`drizzle/schema.ts`** + **`shared/`** — modelos de datos y tipos/errores compartidos.

## 2. Arranque del servidor (`server/_core/index.ts`)

`startServer()`:
1. Crea la app Express y el `http.Server`.
2. CORS abierto (`origin: true, credentials: true`) + preflight `OPTIONS *`.
3. Body parser JSON/urlencoded con límite de 50MB (soporta uploads).
4. Monta, en orden: `registerStorageProxy(app)` → `registerOAuthRoutes(app)` (legado Manus) → `registerMobileApi(app)` (REST para Flutter) → middleware tRPC en `/api/trpc`.
5. En `development` usa Vite middleware (`setupVite`); en producción sirve estáticos (`serveStatic`) desde `dist/`.
6. Busca un puerto libre a partir de `PORT` (o 3000), probando hasta 20 puertos.

## 3. Contexto y autenticación tRPC

### `server/_core/context.ts` — `createContext()`
Doble estrategia de autenticación por request, en cascada:
1. **Intento 1 — Manus OAuth SDK** (`sdk.authenticateRequest(req)`, de `server/_core/sdk.ts`): valida cookie/JWT contra el servicio OAuth de la plataforma original del scaffold. Si `OAUTH_SERVER_URL` no está configurado, esto falla silenciosamente.
2. **Intento 2 — Fallback Clerk**: si falla el paso 1, lee el header `Authorization: Bearer <token>`, decodifica el **payload del JWT sin verificar la firma** (`decodeJwtPayload`, split manual + `Buffer.from(base64)`), extrae `sub` (openId), `name`/`given_name`, `email`/`primary_email_address`, y hace upsert del usuario en MySQL (`db.upsertUser` + `db.getUserByOpenId`).

Riesgos de este diseño están documentados en [07_TECHNICAL_DEBT.md](07_TECHNICAL_DEBT.md) (no hay verificación criptográfica del JWT de Clerk, y se loguean tokens/headers completos en consola).

### `server/_core/trpc.ts`
- `publicProcedure` — sin auth.
- `protectedProcedure` — requiere `ctx.user` (si no, `TRPCError UNAUTHORIZED`).
- `adminProcedure` — requiere `ctx.user.role === "admin"`.
- Transformer global: `superjson`.

## 4. Router tRPC (`server/routers.ts`)

`appRouter = router({ system, auth, training })`

### `auth`
| Procedure | Tipo | Descripción |
|---|---|---|
| `auth.me` | public query | Devuelve `ctx.user` (o `null`) |
| `auth.logout` | public mutation | Limpia la cookie de sesión (legado) |

### `training` (todas protegidas salvo donde se indique)
| Procedure | Tipo | Descripción |
|---|---|---|
| `createPlan` | mutation | Genera un plan nuevo vía IA (`generatePersonalizedPlanWithNutrition`) y lo persiste como plan activo |
| `getActivePlan` | query | Trae el plan activo; si detecta ejercicios sin `gifUrl` o sin traducir, los enriquece **on-the-fly** y persiste el resultado |
| `getTodayChecklist` | query | Checklist del día (o placeholder vacío) |
| `updateProgress` | mutation | Actualiza checklist + progreso de usuario (XP, series) |
| `getUserProgress` | query | Trae/crea progreso del usuario (XP, nivel, racha) |
| `getAchievements` | **public** query | Catálogo global de logros |
| `getUserAchievements` | query | Logros desbloqueados por el usuario |
| `getStats` | query | Recalcula series programadas/completadas iterando todos los planes del usuario |
| `createDailyChecklist` | mutation | Crea el checklist de un día si no existe |
| `generateDemoRoutine` | mutation | Genera un plan de ejemplo con datos hardcodeados (hipertrofia, 4 días) |
| `searchExercise` | query | Busca 1 ejercicio en ExerciseDB (`callDataApi`, proxy "Forge") |
| `markSeriesComplete` | mutation | **El procedure más complejo**: marca una serie de un ejercicio como completada/no completada, calcula XP (+10 por serie, +25 bonus si se completa el ejercicio, −10 al desmarcar), actualiza el checklist del día, calcula si el día se completó, actualiza la **racha** (streak) comparando fechas contra la frecuencia semanal del plan, y llama a `checkAndUnlockAchievements` |
| `searchExerciseWithMedia` | **public** query | Busca GIF de un ejercicio vía MuscleWiki/ExerciseDB |
| `getDailyProgress` | query | Progreso de series de un día puntual |
| `getChecklists` | query | Todos los checklists del usuario |
| `getCompletedDates` | query | Fechas completadas (para el calendario) |
| `getDayDetails` | query | Detalle de ejercicios de un día por fecha |
| `getDashboardData` | query | Agrega gráfico semanal, últimos entrenamientos y feed de actividad para el Dashboard |
| `getAITips` | query | Genera 3 tips personalizados vía LLM (con fallback estático si falla el parseo JSON) |

### Motor de generación de IA — `generatePersonalizedPlanWithNutrition()`
Ubicado al final de `routers.ts` (línea ~900). Flujo:
1. Calcula IMC, **TDEE** (Mifflin-St Jeor: `calculateTDEE`) y **macros** (`calculateMacros`) determinísticamente en TypeScript (no depende del LLM para esto).
2. Arma un prompt extenso en español con: perfil completo del cliente, 11 reglas de negocio numeradas (equipo compatible, nivel, lesiones, estructura de warmup+6-8 ejercicios+3 series por día, nombres en inglés para búsqueda en API, instrucciones/tips obligatorios), reglas dinámicas extra si detecta preferencia de "solo core", y el **catálogo RAG completo** (`getCatalogPromptString()` de `catalog.ts`) con la instrucción explícita de no inventar ejercicios fuera del catálogo.
3. Define `planSchema`: JSON Schema estricto (`additionalProperties: false`, todos los campos `required`) que cubre `summary`, `objective`, `days[].{focus, warmup, exercises[], cooldown, notes}` y `nutrition.{dailyCalories, dailyMacros, meals[], tips, hydration, ...}`.
4. Llama a `invokeLLM({ messages, outputSchema: { name, schema: planSchema, strict: true } })`.
5. Parsea la respuesta y aplica `validateGeneratedPlan(plan, input)` — post-procesamiento determinístico que:
   - Sustituye ejercicios por variantes de peso corporal/mancuernas si el equipo declarado no coincide (tablas `BODYWEIGHT_REPLACEMENTS` / `DUMBBELL_REPLACEMENTS`).
   - Sustituye ejercicios de tren inferior/empuje por alternativas de core si detecta lesión de pierna/hombro (heurística por substring matching sobre palabras clave en español e inglés).
6. Enriquece cada ejercicio: busca GIF (`getExerciseMediaUrl`, `musclewiki.ts`) y traduce el nombre a español (`translateExerciseToSpanish`, `translations.ts`), preservando el nombre en inglés en `nameEn`.
7. **Fallback total**: si `invokeLLM` falla (por ejemplo sin `OPENAI_API_KEY`/créditos) o no hay contenido, cae a `generateBasicPlan()` — una plantilla 100% determinística en TypeScript que arma rutinas Push/Pull/Legs (3 días) o Upper/Lower/Full Body (4+ días) a partir de listas fijas de ejercicios, adaptando sets/reps/descanso según nivel y objetivo, e inyectando ejercicios de core si el usuario los pidió.

## 5. Acceso a datos (`server/db.ts`)

Sin ORM de alto nivel tipo repositorio: funciones planas que usan Drizzle directamente sobre un pool `mysql2`.

- **Conexión**: `getDb()` — singleton lazy, crea el pool (`connectionLimit: 10`, keep-alive) la primera vez que se usa, y dispara `seedAchievements()` de forma asíncrona (inserta 4 logros por defecto si la tabla está vacía).
- **Usuarios**: `upsertUser`, `getUserByOpenId` — upsert usa `onDuplicateKeyUpdate` sobre `openId` (unique). Asigna rol `admin` automáticamente si `openId === ENV.ownerOpenId`.
- **Planes**: `createTrainingPlan` (desactiva planes previos del usuario antes de insertar uno nuevo — solo 1 plan activo a la vez), `updateTrainingPlanContent`, `getActiveTrainingPlan`.
- **Checklists diarios**: `createDailyChecklist` (idempotente por `userId+trainingPlanId`), `getTodayChecklist`, `updateChecklistProgress`, `getUserChecklists`.
- **Progreso / Gamificación** (`updateUserProgress`): recalcula XP total, nivel (`floor(xp/500)+1`), series históricas y **racha** — la racha se incrementa si el último entrenamiento fue exactamente ayer, se resetea a 1 si pasó más de un día. *(Nota: existe una segunda lógica de racha, más elaborada y tolerante a la frecuencia semanal del plan, duplicada dentro de `markSeriesComplete` en `routers.ts` — ver hallazgo en* [07_TECHNICAL_DEBT.md](07_TECHNICAL_DEBT.md)*)*.
- **Historial de ejercicios**: `createExerciseHistory`, `getExerciseHistoryByDay`, `updateExerciseHistory`, `getExerciseProgressStats` — tabla `exercise_history`, aunque no se ve invocada activamente desde `routers.ts` (posible feature incompleta).
- **Calendario**: `getCompletedDates`, `getDayDetails`.
- **Logros**: `getAchievements`, `getUserAchievements`, `unlockAchievement`, `checkAndUnlockAchievements(userId)` — compara `{ total_xp, streak_days, series_completed, workouts_done }` del usuario contra `conditionType`/`conditionValue` de cada logro no desbloqueado.

## 6. Módulos de dominio en `server/_core/`

| Archivo | Responsabilidad |
|---|---|
| `catalog.ts` | Catálogo RAG de ~100 ejercicios agrupados por músculo (`EXERCISE_CATALOG`), usado para restringir las elecciones del LLM |
| `injuryFilter.ts` | Mapeo lesión→ejercicios prohibidos + alternativas, y `filterPlanByInjuries()`. **Código muerto**: no está importado desde ningún otro archivo del backend (ver Technical Debt) |
| `musclewiki.ts` | Integración con **ExerciseDB vía RapidAPI** (a pesar del nombre del archivo, no usa la API de MuscleWiki): `getExerciseMediaUrl()` busca 1 GIF por nombre, `searchExerciseWithMedia()` busca varios |
| `translations.ts` | Diccionario ES↔EN de nombres de ejercicios (216 líneas), usado tanto para mostrar nombres en español como para traducir de vuelta a inglés antes de consultar ExerciseDB |
| `mobileApi.ts` | Router Express independiente de tRPC, expone `/api/mobile/*` para la app Flutter (ver sección 8) |
| `llm.ts` | Wrapper `invokeLLM()` / `listLLMModels()` sobre un proxy tipo OpenAI ("Forge", `BUILT_IN_FORGE_API_URL`), con reintentos con backoff exponencial + jitter y soporte de `response_format: json_schema` |
| `dataApi.ts` | `callDataApi()` — proxy genérico hacia APIs de terceros catalogadas por el proxy "Forge" (usado para `ExerciseDB/exercises/name/{name}`) |
| `sdk.ts` | Cliente OAuth de la plataforma "Manus" original (`OAuthService`, JWT propio con `jose`) — capa de auth legada, primer intento en `createContext` |
| `oauth.ts` | Registra rutas Express para el flujo OAuth de Manus (`registerOAuthRoutes`) |
| `cookies.ts` | Helpers de cookies de sesión (`getSessionCookieOptions`) |
| `storageProxy.ts` | Proxy de almacenamiento de archivos (plataforma Manus) |
| `systemRouter.ts` | Sub-router tRPC de sistema (montado como `system` en `appRouter`) |
| `env.ts` | Único punto de lectura de variables de entorno (`ENV`) |
| `vite.ts` | Integración de Vite en modo dev / servido de estáticos en producción |
| `heartbeat.ts`, `imageGeneration.ts`, `map.ts`, `notification.ts`, `voiceTranscription.ts` | Integraciones de la plataforma "Manus" (mapas, notificaciones push, generación de imágenes, transcripción de voz, heartbeat). **No están importadas por ninguna feature de FerFit** — scaffolding sin usar |

## 7. Base de datos (Drizzle / MySQL)

Ver [`drizzle/schema.ts`](../drizzle/schema.ts). Tablas:

| Tabla | Propósito | Claves relevantes |
|---|---|---|
| `users` | Usuario de la app | `openId` único (id externo de Clerk o Manus), `role` enum `user|admin` |
| `training_plans` | Un plan de entrenamiento+nutrición generado | `userId`, `isActive` (int 0/1 — solo 1 activo por diseño de `createTrainingPlan`), `generatedContent` (JSON serializado como `text`, sin validación de schema en DB) |
| `daily_checklists` | Progreso de un día de entrenamiento | `userId`, `trainingPlanId`, `totalSeries`/`completedSeries`, `xpEarned` |
| `user_progress` | Estado de gamificación agregado por usuario | `userId` único, `totalXP`, `level`, `streak`, `lastWorkoutDate` |
| `exercise_history` | Historial granular por serie de ejercicio | `dailyChecklistId`, `plannedSets/Reps`, `completedSets/Reps`, `weight`, `duration` (tabla con más detalle del que hoy se usa activamente) |
| `achievements` | Catálogo de logros | `conditionType` (`total_xp`\|`streak_days`\|`workouts_done`\|`series_completed`), `conditionValue` |
| `user_achievements` | Logros desbloqueados por usuario | `userId`, `achievementId`, `unlockedAt` |

**Migraciones**: 6 archivos SQL en `drizzle/migrations/` (`0000`…`0005`), generadas con `drizzle-kit`. `drizzle/relations.ts` está vacío (sin relaciones declaradas explícitamente — los joins se hacen manualmente con `eq`/`and` en `db.ts`).

**Nota de diseño importante**: el contenido del plan (`generatedContent`) vive como JSON en una columna `text`, no normalizado en tablas. Esto simplifica la persistencia del output del LLM pero implica que todo el estado de progreso por serie (`seriesCompleted`, `seriesWeights`, `seriesReps`) se lee/escribe mutando ese blob JSON completo en cada `markSeriesComplete` — no hay updates atómicos a nivel de fila para eso.

## 8. API móvil (`server/_core/mobileApi.ts`)

Router Express **REST**, separado de tRPC, montado en `/api/mobile`. Consumido por la app Flutter (`ferfit_flutter/lib/services/api_service.dart`). Internamente reutiliza los mismos procedures de tRPC vía `createCallerFactory(appRouter)` (un "caller" server-side que invoca el router sin pasar por HTTP), evitando duplicar lógica de negocio.

| Endpoint | Método | Reutiliza (tRPC) |
|---|---|---|
| `/api/mobile/clerk/sign-in`, `/sign-up` | POST | Llama directo a la API de Clerk (server-to-server) para emular el flujo de login/registro sin el SDK web de Clerk |
| `/api/mobile/clerk/sign_ins`, `/sign_ins/:id/attempt_first_factor`, `/sign_ups`, `/client` | POST/GET | Proxys directos a la Frontend API de Clerk (evade el bloqueo de "development browser" y CORS) |
| `/api/mobile/auth` | POST | Valida el token entrante vía `createContext` |
| `/api/mobile/dashboard` | GET (auth) | `training.getDashboardData` + `training.getUserProgress` |
| `/api/mobile/tips` | GET (auth) | `training.getAITips` |
| `/api/mobile/plan/active` | GET (auth) | `training.getActivePlan` |
| `/api/mobile/plan/create` | POST (auth) | `training.createPlan` |
| `/api/mobile/checklist/today` | GET (auth) | `training.getTodayChecklist` |
| `/api/mobile/series/complete` | POST (auth) | `training.markSeriesComplete` |

El middleware `requireAuth` construye el contexto tRPC (`createContext`) a partir del request Express y lo cuelga en `req.trpcCtx` para los handlers siguientes.

## 9. Variables de entorno (`.env.example`)

| Variable | Uso |
|---|---|
| `VITE_CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY` / `VITE_CLERK_SECRET_KEY` | Autenticación Clerk (cliente + servidor) |
| `DATABASE_URL` | Conexión MySQL/TiDB (`mysql2` pool) |
| `JWT_SECRET` | Firma de cookies de sesión legadas (Manus) |
| `OPENAI_API_KEY`, `GROQ_API_KEY` | Declaradas pero no leídas directamente por `env.ts` — la key real usada por `invokeLLM` es `BUILT_IN_FORGE_API_KEY` |
| `BUILT_IN_FORGE_API_URL`, `BUILT_IN_FORGE_API_KEY` | Proxy "Forge" (LLM + `callDataApi`) |
| `MUSCLE_WIKI_API_KEY` | RapidAPI key para ExerciseDB (a pesar del nombre) |
| `OAUTH_SERVER_URL`, `OWNER_OPEN_ID` | Leídas por `ENV` (`env.ts`) pero no listadas en `.env.example` — usadas por la capa OAuth legada de Manus |
