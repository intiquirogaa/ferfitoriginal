# 07 · Deuda Técnica

> Última actualización: 2026-07-04
> Estos hallazgos se registran para decisión del equipo. **No se aplican automáticamente** — ver regla de trabajo en la raíz de este proyecto de documentación.

Prioridad: 🔴 Alta · 🟡 Media · 🟢 Baja

---

## Seguridad

### 🔴 1. JWT de Clerk decodificado sin verificar firma
**Archivo**: [server/_core/context.ts:17-31](../server/_core/context.ts)
`decodeJwtPayload()` hace `split('.')` + `Buffer.from(base64)` manualmente, sin validar la firma del token contra las claves públicas de Clerk. Cualquier request con un JWT bien formado (aunque no esté firmado por Clerk) puede hacerse pasar por cualquier `sub`/`email`, y `createContext` hará upsert de ese usuario en la base de datos.
**Impacto**: suplantación de identidad / creación arbitraria de usuarios.
**Sugerencia**: usar `@clerk/backend` (`verifyToken`) o la librería `jose` (ya es dependencia del proyecto) contra el JWKS público de Clerk.

### 🔴 2. Tokens y headers de autorización logueados en texto plano
**Archivos**: [server/_core/context.ts:37,50,53](../server/_core/context.ts), [server/_core/mobileApi.ts:106,115,400,457](../server/_core/mobileApi.ts)
Se hace `console.log` del header `Authorization` completo, del payload decodificado del JWT, y de request bodies (incluyendo en `sign-in`, aunque ahí sí se enmascara la password). En producción estos logs pueden terminar en un servicio de logging centralizado, exponiendo tokens de sesión válidos.
**Impacto**: filtración de credenciales de sesión.
**Sugerencia**: eliminar o redactar (`***`) antes de loguear; usar un logger con niveles (debug apagado en producción).

### 🟡 3. CORS totalmente abierto
**Archivo**: [server/_core/index.ts:36-49](../server/_core/index.ts)
`cors({ origin: true, credentials: true })` refleja cualquier origen. Combinado con `credentials: true`, cualquier sitio puede hacer requests autenticadas si el usuario tiene cookies/tokens válidos.
**Sugerencia**: restringir `origin` a una allowlist (dominio de producción + localhost en dev).

---

## Duplicación de lógica

### 🔴 4. Dos algoritmos de racha (streak) distintos y potencialmente inconsistentes
**Archivos**: [server/db.ts:205-236](../server/db.ts) (`updateUserProgress`) vs [server/routers.ts:403-437](../server/routers.ts) (dentro de `markSeriesComplete`)
`updateUserProgress` calcula la racha con una regla simple (+1 si el último workout fue "ayer"). `markSeriesComplete` implementa una segunda regla, más elaborada, que tolera gaps según `daysPerWeek` del plan. Ambas funciones pueden ejecutarse en la misma request (`markSeriesComplete` llama a `updateUserProgress` y **luego** recalcula la racha por su cuenta), dejando el campo `streak` con un valor que depende del orden de ejecución, no de una única fuente de verdad.
**Impacto**: racha incorrecta/inconsistente, logros de racha (`streak_days`) desbloqueados en momentos erróneos.
**Sugerencia**: unificar en una sola función de cálculo de racha, llamada una única vez por evento de "día completado".

### 🟡 5. `server/_core/injuryFilter.ts` es código muerto, duplicado por lógica inline
El módulo completo (`INJURY_BLACKLIST`, `parseInjuries`, `filterPlanByInjuries`) no tiene ningún import en el resto del backend. La sustitución real por lesiones ocurre de forma inline y menos estructurada dentro de `validateGeneratedPlan()` en `routers.ts` (líneas 868-891), con su propia heurística de keywords.
**Sugerencia**: decidir una única implementación (probablemente migrar la lógica inline a usar `injuryFilter.ts`, que es más mantenible/extensible) y eliminar la otra.

### 🟡 6. Diccionario de traducción de ejercicios duplicado (cliente y servidor)
**Archivos**: `server/_core/translations.ts` (216 líneas) y `client/src/lib/exerciseTranslations.ts` (138 líneas)
Mismo propósito (EN→ES para nombres de ejercicios), mantenidos por separado. Agregar un ejercicio nuevo requiere editar dos archivos o quedan desincronizados.
**Sugerencia**: mover el diccionario a `shared/` para que ambos lo consuman desde una única fuente.

### 🟢 7. Tres caminos distintos hacia datos/medios de ejercicios
`server/_core/dataApi.ts` (`callDataApi`, proxy "Forge") y `server/_core/musclewiki.ts` (fetch directo a RapidAPI) resuelven el mismo tipo de dato (info de ExerciseDB) por rutas distintas, sin cache compartida. `training.searchExercise` usa el primero (roto hoy porque `BUILT_IN_FORGE_API_URL` está vacío); el resto del sistema usa el segundo. Desde 2026-07-04 existe un tercer camino, `server/_core/freeExerciseDb.ts` (dataset gratuito, ver D-010 en [08_DECISIONS.md](08_DECISIONS.md)), usado como fallback cuando RapidAPI falla — necesario porque la cuota de RapidAPI está agotada, pero suma una tercera fuente de datos de ejercicios a mantener.
**Sugerencia**: consolidar en un único cliente de ExerciseDB con fallback explícito documentado (ya no es solo una idea — el fallback ya existe, falta unificar el resto).

---

## Drift de esquema / tipos

### 🟡 8. `planSchema` (backend) y `GeneratedTrainingAndNutritionPlan` (frontend) se mantienen manualmente en sincronía
**Archivos**: [server/routers.ts:968-1054](../server/routers.ts) vs `client/src/types.ts`
El JSON Schema que valida la salida del LLM no se comparte con el tipo TypeScript que consume el frontend — son dos definiciones independientes de la misma forma de datos. Un cambio en uno sin el otro rompe la UI silenciosamente (TypeScript no lo detecta porque el dato llega como `any`/JSON parseado).
**Sugerencia**: derivar el JSON Schema desde un schema Zod compartido en `shared/`, y generar el tipo TS desde ese mismo Zod schema (`z.infer`).

### 🟢 9. `training_plans.generatedContent` como JSON en columna `text`, sin validación en DB
El estado de progreso por serie (`seriesCompleted`, `seriesWeights`, `seriesReps`) vive embebido en ese JSON y se reescribe completo en cada `markSeriesComplete`. No hay forma de hacer queries/reportes SQL sobre el detalle de series sin parsear el blob en aplicación.
**Sugerencia**: si el producto crece, normalizar el progreso de series en `exercise_history` (la tabla ya existe mayormente sin usar, ver hallazgo #12).

---

## Código y archivos sin uso

### 🟡 10. Integraciones de plataforma "Manus" no utilizadas por ninguna feature
`server/_core/map.ts`, `notification.ts`, `imageGeneration.ts`, `voiceTranscription.ts`, `heartbeat.ts` (1,531 líneas combinadas) no tienen ningún import desde el código de negocio de FerFit.
**Sugerencia**: si no hay plan de usarlos en el roadmap, eliminarlos para reducir superficie de mantenimiento; si se van a usar, documentarlos en [04_FEATURES.md](04_FEATURES.md) como "planeado".

### 🟢 11. Doble path de autenticación (Manus SDK + Clerk) en `createContext`
El primer intento de auth (`sdk.authenticateRequest`) depende de `OAUTH_SERVER_URL`, que no figura en `.env.example` — es decir, en un setup nuevo del proyecto ese intento **siempre falla** y cae al fallback Clerk. Mantiene complejidad y un log de error en cada request para un camino que probablemente ya no aplica.
**Sugerencia**: confirmar si Manus OAuth sigue en uso en algún ambiente; si no, eliminar el primer intento y simplificar `createContext` a solo Clerk.

### 🟢 12. `exercise_history` — tabla con más columnas de las que se usan
El schema (`plannedSets`, `plannedReps`, `completedSets`, `completedReps`, `weight`, `duration`, `notes`) sugiere un historial granular por serie, pero no se ve poblada desde `markSeriesComplete` (que solo actualiza el JSON de `training_plans` y `daily_checklists`). `ProgressGraphs.tsx` en el frontend espera datos históricos por ejercicio cuya fuente real no está confirmada.
**Sugerencia**: aclarar si esta tabla es para una feature futura (historial detallado) o si debe eliminarse/consolidarse con el JSON del plan.

### 🟢 13. Componentes frontend sin uso activo
`client/src/components/CalendarMultiView.tsx`, `CalendarMultiViewEnhanced.tsx`, `Map.tsx`, `ManusDialog.tsx` — reemplazados por `TrainingCalendar.tsx` y Clerk, respectivamente, pero no eliminados.
**Sugerencia**: eliminar si se confirma que no hay referencias activas (`ManusDialog` puede seguir usándose en migraciones parciales de auth; verificar antes de borrar).

### 🟢 14. `AIChatBox.tsx` construido pero no conectado a ninguna feature
Componente completo (streaming markdown, prompts sugeridos) sin una página que lo monte con un backend real hoy.
**Sugerencia**: o se conecta a una feature de chat con el entrenador IA (natural, dado el resto del producto), o se remueve hasta que haya una.

---

## Archivos sueltos en el repositorio (higiene de repo)

### 🟡 15. Binario de 55MB commiteado en la raíz
`app-release.apk` (build de Android) está en el working tree del repo, sin estar en `.gitignore`.
**Sugerencia**: mover builds a releases de GitHub o artifact storage, agregar `*.apk` a `.gitignore`.

### 🟢 16. Scripts de prueba manual sueltos en la raíz, fuera de la suite formal
`test_api.ts`, `test_exhaustive.ts`, `test_exhaustive_with_gif.ts`, `test_generation.ts`, `test_sign_up.cjs`, `tmp_clerk_server_test.cjs`, `tmp_clerk_session_token_test.cjs`, `tmp_clerk_test.mjs` — no están en `tests/` (que sí usa Vitest formalmente con `tests/generatePersonalizedPlanWithNutrition.test.ts`).
**Sugerencia**: migrar los que siguen siendo útiles a `tests/` como tests de Vitest, y eliminar el resto.

### 🟢 17. Dos lockfiles de package manager distintos
`package-lock.json` (untracked, npm) convive con `pnpm-lock.yaml` (commiteado) — el proyecto declara `packageManager: pnpm@...` en `package.json`. Instalar con `npm install` por error puede generar un lockfile npm inconsistente con el árbol de dependencias real de pnpm.
**Sugerencia**: agregar `package-lock.json` a `.gitignore` y estandarizar en `pnpm` (documentar en README/CLAUDE.md).

---

## Resumen por prioridad

| Prioridad | Cantidad | Ítems |
|---|---|---|
| 🔴 Alta | 4 | JWT sin verificar, logging de tokens, doble algoritmo de racha, (CORS abierto se listó como media pero es cercano a alta en apps con cookies) |
| 🟡 Media | 6 | CORS abierto, injuryFilter muerto, diccionario duplicado, drift de schema IA, integraciones Manus sin usar, apk en el repo |
| 🟢 Baja | 7 | dos caminos ExerciseDB, JSON sin normalizar, doble auth path, exercise_history subutilizada, componentes frontend sin uso, AIChatBox sin conectar, scripts sueltos + dos lockfiles |
