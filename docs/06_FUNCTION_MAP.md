# 06 · Mapa de Funciones Críticas

> Última actualización: 2026-07-04
> Solo funciones con lógica de negocio relevante. No incluye getters/setters triviales ni componentes puramente presentacionales.

---

## Backend

### `generatePersonalizedPlanWithNutrition(input)`
- **Archivo**: [server/routers.ts:900](../server/routers.ts)
- **Responsabilidad**: Orquesta la generación completa de un plan (cálculo de TDEE/macros, prompt engineering, llamada al LLM con JSON Schema estricto, validación y enriquecimiento). Es la función más importante del sistema.
- **Quién la llama**: `training.createPlan`, `training.generateDemoRoutine`.
- **Devuelve**: `Promise<GeneratedTrainingAndNutritionPlan>` (o el resultado de `generateBasicPlan` si falla).
- **Importancia**: **Crítica**.
- **Dependencias**: `calculateTDEE`, `calculateMacros`, `getCatalogPromptString` (catalog.ts), `invokeLLM` (llm.ts), `validateGeneratedPlan`, `getExerciseMediaUrl` (musclewiki.ts), `translateExerciseToSpanish` (translations.ts), `generateBasicPlan`.
- **Observaciones**: Contiene lógica de prompt engineering embebida como template string gigante; cualquier cambio en el schema (`planSchema`) debe replicarse manualmente en `client/src/types.ts` (`GeneratedTrainingAndNutritionPlan`).

### `validateGeneratedPlan(plan, input)`
- **Archivo**: [server/routers.ts:772](../server/routers.ts)
- **Responsabilidad**: Post-procesa el plan devuelto por el LLM sustituyendo ejercicios incompatibles con el equipo disponible o con lesiones declaradas (heurística de substring matching en ES/EN).
- **Quién la llama**: `generatePersonalizedPlanWithNutrition`.
- **Devuelve**: el mismo `plan` mutado in-place (y retornado).
- **Importancia**: **Alta** (seguridad/adecuación del plan).
- **Dependencias**: tablas hardcodeadas `BODYWEIGHT_REPLACEMENTS`, `DUMBBELL_REPLACEMENTS`, `CORE_REPLACEMENTS`, `SHOULDER_REPLACEMENTS`.
- **Observaciones**: Lógica solapada con `_core/injuryFilter.ts`, que no se usa. Ver [07_TECHNICAL_DEBT.md](07_TECHNICAL_DEBT.md).

### `generateBasicPlan(input, tdee, macros)`
- **Archivo**: [server/routers.ts:1109](../server/routers.ts)
- **Responsabilidad**: Fallback 100% determinístico (sin IA) que arma una rutina Push/Pull/Legs o Upper/Lower/Full Body según `daysPerWeek`, adaptando sets/reps/descanso por nivel y objetivo, e inyectando ejercicios de core si el usuario lo pidió.
- **Quién la llama**: `generatePersonalizedPlanWithNutrition` (en el `catch`).
- **Devuelve**: objeto con la misma forma que el plan generado por IA.
- **Importancia**: **Alta** (garantiza que el producto funcione sin créditos de LLM).

### `training.markSeriesComplete` (mutation)
- **Archivo**: [server/routers.ts:293](../server/routers.ts)
- **Responsabilidad**: Marca/desmarca una serie de un ejercicio, calcula XP ganado (+10 por serie, +25 bonus por ejercicio completo, −10 al desmarcar), persiste peso/reps, actualiza el checklist del día, determina si el día se completó, recalcula la **racha** (streak) tolerando gaps según la frecuencia semanal del plan, y dispara verificación de logros.
- **Quién la llama**: cliente web (`GeneratedTrainingPlanView`/`ExerciseChecklist`) y móvil (`/api/mobile/series/complete`).
- **Devuelve**: `{ success, xpGained, newXp, unlockedAchievements }`.
- **Importancia**: **Crítica** (único punto de escritura de progreso de entrenamiento).
- **Dependencias**: `db.getActiveTrainingPlan`, `db.getUserProgress`, `db.updateUserProgress`, `db.getTodayChecklist`, `db.createDailyChecklist`, `db.checkAndUnlockAchievements`, `updateTrainingPlanContent` (helper local).
- **Observaciones**: Contiene su propia lógica de cálculo de racha, **distinta** de la de `db.updateUserProgress` — dos algoritmos de racha coexisten en el código (ver Technical Debt #1).

### `training.getActivePlan` (query)
- **Archivo**: [server/routers.ts:95](../server/routers.ts)
- **Responsabilidad**: Trae el plan activo y lo **re-enriquece perezosamente**: si algún ejercicio no tiene `gifUrl` o no está traducido, lo completa y persiste el resultado antes de devolverlo.
- **Quién la llama**: casi todas las páginas del cliente.
- **Devuelve**: `plan` + `hasPlan: boolean`.
- **Importancia**: **Alta**.
- **Observaciones**: Hace I/O externo (ExerciseDB) dentro de una query de lectura — puede volver lenta la carga del dashboard si hay muchos ejercicios sin enriquecer.

### `db.updateUserProgress(userId, xpToAdd, seriesCompleted)`
- **Archivo**: [server/db.ts:205](../server/db.ts)
- **Responsabilidad**: Recalcula XP total, nivel (`floor(xp/500)+1`), series históricas y racha (algoritmo simple: +1 si el último entrenamiento fue ayer, reset si pasó más de un día).
- **Quién la llama**: `training.updateProgress`, `training.markSeriesComplete`.
- **Devuelve**: `void` (efecto secundario en DB).
- **Importancia**: **Alta**.
- **Observaciones**: Duplica parcialmente la lógica de racha de `markSeriesComplete` (ver Technical Debt).

### `db.checkAndUnlockAchievements(userId)`
- **Archivo**: [server/db.ts:361](../server/db.ts)
- **Responsabilidad**: Compara estadísticas actuales del usuario (`total_xp`, `streak_days`, `series_completed`, `workouts_done`) contra la condición de cada logro no desbloqueado; inserta los que corresponda.
- **Quién la llama**: `training.markSeriesComplete`.
- **Devuelve**: `Achievement[]` recién desbloqueados.
- **Importancia**: **Media**.

### `db.createTrainingPlan(userId, type, daysPerWeek, generatedContent)`
- **Archivo**: [server/db.ts:87](../server/db.ts)
- **Responsabilidad**: Desactiva cualquier plan previo del usuario (`isActive=0`) e inserta el nuevo como activo — garantiza invariante "1 plan activo por usuario".
- **Quién la llama**: `training.createPlan`, `training.generateDemoRoutine`.
- **Importancia**: **Alta** (invariante de negocio).

### `createContext(opts)`
- **Archivo**: [server/_core/context.ts:33](../server/_core/context.ts)
- **Responsabilidad**: Resuelve el usuario autenticado por request probando primero el SDK OAuth legado ("Manus") y luego decodificando el JWT de Clerk manualmente (sin verificar firma) para hacer upsert del usuario.
- **Quién la llama**: middleware tRPC (`createExpressMiddleware`), `mobileApi.ts` (`getTrpcContext`).
- **Devuelve**: `TrpcContext` (`{ req, res, user }`).
- **Importancia**: **Crítica** (gatekeeper de toda request autenticada).
- **Observaciones**: Riesgo de seguridad — ver [07_TECHNICAL_DEBT.md](07_TECHNICAL_DEBT.md) #2.

### `invokeLLM(params)`
- **Archivo**: [server/_core/llm.ts:342](../server/_core/llm.ts)
- **Responsabilidad**: Normaliza mensajes/tools/response_format al formato del proxy "Forge" (compatible OpenAI), hace fetch con reintentos (backoff exponencial + jitter, hasta 4 reintentos) y devuelve la respuesta tipada.
- **Quién la llama**: `generatePersonalizedPlanWithNutrition`, `training.getAITips`.
- **Importancia**: **Crítica** (único punto de acceso al LLM).

### `getExerciseMediaUrl(exerciseName)`
- **Archivo**: [server/_core/musclewiki.ts:14](../server/_core/musclewiki.ts)
- **Responsabilidad**: Traduce el nombre a inglés y busca 1 GIF en ExerciseDB (RapidAPI).
- **Quién la llama**: `training.searchExerciseWithMedia`, `generatePersonalizedPlanWithNutrition`, `training.getActivePlan`.
- **Importancia**: **Media-Alta**.

### `getCatalogPromptString()`
- **Archivo**: [server/_core/catalog.ts:52](../server/_core/catalog.ts)
- **Responsabilidad**: Serializa `EXERCISE_CATALOG` a texto plano para inyectarlo en el prompt del LLM.
- **Quién la llama**: `generatePersonalizedPlanWithNutrition`.
- **Importancia**: **Alta** (control de calidad del output de IA).

### `calculateTDEE(age, weight, height, daysPerWeek)` / `calculateMacros(objective, weight, tdee)`
- **Archivo**: [server/routers.ts:735-750](../server/routers.ts)
- **Responsabilidad**: Fórmulas nutricionales estándar (Mifflin-St Jeor + factor de actividad; reparto de macros por objetivo).
- **Quién la llama**: `generatePersonalizedPlanWithNutrition`, `generateBasicPlan`.
- **Importancia**: **Alta** (determinístico, sin IA — base de todo el plan nutricional).

---

## Frontend

### `getLevelProgress(xp)`
- **Archivo**: `client/src/lib/levels.ts`
- **Responsabilidad**: Calcula nivel actual y % de progreso hacia el siguiente a partir de una tabla de umbrales de XP.
- **Quién la llama**: `Dashboard.tsx`, `Progreso.tsx`.
- **Importancia**: **Media**.

### `exportTrainingAndNutritionPlanToPDF(plan)`
- **Archivo**: `client/src/lib/exportPDF.ts`
- **Responsabilidad**: Genera un PDF multi-página (portada, resumen, días, nutrición) con `jsPDF` y dispara la descarga.
- **Quién la llama**: `Entrenamiento.tsx`.
- **Importancia**: **Media**.
- **Observaciones**: Import dinámico de `jspdf` (`await import(...)`) para code-splitting.

### `translateExerciseToSpanish` / `translateExerciseToEnglish`
- **Archivo**: `server/_core/translations.ts` (backend) — existe un diccionario equivalente en `client/src/lib/exerciseTranslations.ts` (frontend).
- **Responsabilidad**: Traducción bidireccional de nombres de ejercicios vía diccionario estático + lookup case-insensitive (`Proxy` en el cliente).
- **Quién la llama**: motor de generación (backend), `ExerciseCard`/`ProgressGraphs` (frontend, para mostrar nombres).
- **Importancia**: **Media**.
- **Observaciones**: **Diccionario duplicado** entre frontend y backend — mismo propósito, dos fuentes de verdad (ver Technical Debt).

### `ProtectedRoute` / `AuthenticatedRoute`
- **Archivo**: `client/src/App.tsx`
- **Responsabilidad**: Guardas de ruta que verifican configuración de Clerk y estado de sesión antes de renderizar páginas protegidas.
- **Quién la llama**: definición de rutas en `App.tsx`.
- **Importancia**: **Alta** (seguridad de navegación en el cliente).

### `useIsMobile()`
- **Archivo**: `client/src/hooks/useMobile.tsx`
- **Responsabilidad**: Media query reactiva (768px) para decidir layouts responsive.
- **Quién la llama**: `DashboardLayout.tsx` y varias páginas.
- **Importancia**: **Media** (UX, no lógica de negocio de dominio).

---

## Notas generales sobre el mapa

- No se listan los ~50 componentes de `components/ui/` (shadcn-like) por ser primitivos de presentación sin lógica de negocio.
- No se listan los procedures tRPC triviales de solo lectura (`getAchievements`, `getChecklists`, etc.) — están documentados como tabla en [03_BACKEND.md](03_BACKEND.md).
- `server/_core/injuryFilter.ts` (`parseInjuries`, `filterPlanByInjuries`) se omite de este mapa como función "activa" porque no tiene ningún llamador — está documentado como hallazgo en [07_TECHNICAL_DEBT.md](07_TECHNICAL_DEBT.md).
