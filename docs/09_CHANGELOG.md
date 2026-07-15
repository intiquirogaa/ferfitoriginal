# 09 · Changelog Técnico

> Formato cronológico ascendente. Nunca se borra una entrada anterior — solo se agregan nuevas al final.
> Esta bitácora documenta cambios de código/arquitectura. Para la bitácora de producto/diseño previa, ver [BITACORA.md](../BITACORA.md) y [WALKTHROUGH.md](../WALKTHROUGH.md) en la raíz del repo.

---

## [2026-07-04] — Mejoras de IA, wizard y calendario (migradas desde BITACORA.md)

**Objetivo**: mejorar la confiabilidad de la generación de rutinas por IA y la UX de recolección de datos del usuario.

**Cambios realizados**:
- **Frontend**: reemplazo de `Textarea` libres en `TrainingPlanSelector.tsx` (paso 4 del wizard) por tags seleccionables (`INJURY_OPTIONS`, `PREFERENCE_OPTIONS`), con campo de texto "Otros" como fallback.
- **Backend (IA)**: implementación de Structured Outputs (`response_format: json_schema`, `strict: true`) vía `planSchema` en `generatePersonalizedPlanWithNutrition`.
- **Regla de negocio**: cada día del plan debe iniciar con warmup de movilidad y contener 6-8 ejercicios de 3 series.
- **Backend (Catálogo RAG)**: creación de `server/_core/catalog.ts`, inyectado en el prompt para evitar ejercicios inventados.
- **Backend (Fallback)**: reprogramación completa de `generateBasicPlan` para individualizar por nivel, objetivo, equipo y preferencias (incluyendo rutinas exclusivas de core).
- **Frontend (Calendario)**: rediseño de `TrainingCalendar.tsx` como anillos de progreso SVG estilo Apple Fitness.
- **Mobile (Flutter)**: sincronización de paleta de colores (`main.dart`) y glows de marca en `login_screen.dart`.

**Archivos modificados**: `client/src/components/TrainingPlanSelector.tsx`, `client/src/components/TrainingCalendar.tsx`, `server/routers.ts`, `server/_core/catalog.ts` (nuevo), `ferfit_flutter/lib/main.dart`, `ferfit_flutter/lib/screens/login_screen.dart`.

**Funciones modificadas**: `generatePersonalizedPlanWithNutrition`, `generateBasicPlan` (server/routers.ts).

**Nuevas funcionalidades**: catálogo RAG de ejercicios, tags seleccionables de lesiones/preferencias, anillos de progreso en calendario.

**Errores encontrados**: ejercicios alucinados por el LLM sin GIF correspondiente; JSON de respuesta del LLM frágil ante parseo por recorte de string.

**Errores corregidos**: ambos, vía D-002 y D-003 en [08_DECISIONS.md](08_DECISIONS.md).

**Verificación**: `pnpm check` (TypeScript) sin errores; `flutter analyze` sin errores de sintaxis (solo warnings menores de lint).

**Pendientes**: Chain-of-Thought multi-paso para la generación (dividir estrategia → selección de ejercicios → nutrición); regeneración granular de un solo ejercicio ("Cambiar este ejercicio").

---

## [2026-07-04] — Creación de documentación técnica formal (`docs/`)

**Objetivo**: establecer una base de documentación arquitectónica exhaustiva y mantenible antes de continuar con desarrollo, a pedido explícito del usuario (rol de Arquitecto de Software / Documentador Técnico).

**Cambios realizados**: exploración completa del código fuente (frontend `client/`, backend `server/`, `shared/`, `drizzle/`, app `ferfit_flutter/`) y creación de 10 documentos en `docs/`:
- `01_PROJECT_OVERVIEW.md`, `02_FRONTEND.md`, `03_BACKEND.md`, `04_FEATURES.md`, `05_ARCHITECTURE.md` (con diagramas Mermaid), `06_FUNCTION_MAP.md`, `07_TECHNICAL_DEBT.md`, `08_DECISIONS.md`, `09_CHANGELOG.md` (este archivo), `10_ROADMAP.md`.

**Archivos modificados**: ninguno de código — solo documentación nueva en `docs/*.md`.

**Hallazgos relevantes registrados en Technical Debt**: JWT de Clerk decodificado sin verificar firma (`context.ts`), tokens logueados en texto plano, dos algoritmos de racha distintos e inconsistentes (`db.ts` vs `routers.ts`), módulo `injuryFilter.ts` sin usar (código muerto), diccionario de traducción de ejercicios duplicado entre cliente y servidor, drift manual entre el JSON Schema del LLM y los tipos TypeScript del frontend, integraciones de plataforma "Manus" sin usar (mapas, notificaciones, generación de imágenes, transcripción de voz), archivos sueltos en la raíz del repo (`app-release.apk` de 55MB, scripts `test_*`/`tmp_clerk_*` fuera de la suite formal de Vitest), dos lockfiles de package manager conviviendo (`package-lock.json` + `pnpm-lock.yaml`).

**Pendientes**: decidir con el usuario qué ítems de deuda técnica se resuelven y cuándo (ninguno se tocó en esta sesión, por regla explícita de no modificar código sin pedido concreto).

---

## [2026-07-04] — Fix: el fallback sin IA ignoraba lesiones declaradas por el usuario

**Objetivo**: el usuario reportó que, declarando lesión de muñeca en el wizard, el plan generado igual incluía flexiones de brazos (push-ups).

**Diagnóstico**: `BUILT_IN_FORGE_API_KEY` está vacío en `.env`, por lo que `invokeLLM()` siempre falla y `generatePersonalizedPlanWithNutrition` cae siempre a `generateBasicPlan()` — el cual **no tenía ninguna lógica de filtrado por lesiones/equipo** (a diferencia del camino con IA, que sí pasa por `validateGeneratedPlan()`).

**Cambios realizados**:
- `generateBasicPlan()` ahora pasa su plan por `validateGeneratedPlan(basicPlan, input)` antes de devolverlo, reutilizando la misma lógica de sustitución por equipo/lesiones que ya usaba el camino con IA (DRY, sin duplicar reglas).
- Se completó `LOWER_BODY_EXERCISES` (dentro de `validateGeneratedPlan`) agregando `"glute bridge"`, `"hip thrust"`, `"wall sit"` — nombres que existían en el catálogo/fallback pero no eran reconocidos como ejercicios de tren inferior, por lo que se colaban sin sustituir ante una lesión de pierna/rodilla.
- Se exportaron (`export`) `validateGeneratedPlan`, `generatePersonalizedPlanWithNutrition` y `generateBasicPlan` en `server/routers.ts` para permitir probarlas directamente (antes eran privadas del módulo).

**Archivos modificados**: `server/routers.ts`.

**Verificación**: `tsc --noEmit` sin errores; suite de Vitest sigue pasando; se ejecutó `generatePersonalizedPlanWithNutrition` directamente con `injuries: "Muñecas"` y con `injuries: "Rodillas"` (y también con texto libre "me duele mucho la pierna izquierda") — confirmado que los ejercicios de empuje (wrist) y de tren inferior (leg/knee) se reemplazan correctamente por alternativas de core, incluyendo los casos previamente no cubiertos (Glute Bridge, Wall Sit).

**Pendientes**: unificar esta lógica con `server/_core/injuryFilter.ts` (que sigue sin usarse) en una futura limpieza — ver [07_TECHNICAL_DEBT.md](07_TECHNICAL_DEBT.md).

---

## [2026-07-04] — Fix: GIFs de ejercicios no se mostraban (cuota de RapidAPI agotada) + fallback gratuito

**Objetivo**: el usuario reportó que los ejercicios no traían GIF/imagen.

**Diagnóstico**: se probó en vivo la API real (`exercisedb.p.rapidapi.com`, la que usa `getExerciseMediaUrl` en `server/_core/musclewiki.ts`) con la key configurada en `.env` y devolvió `429 - MONTHLY quota exceeded (plan BASIC)` en ambos endpoints usados (`/exercises/name/{name}` y `/image?exerciseId=...`, este último detrás del proxy `/api/exercise-image` en `server/_core/storageProxy.ts`). Además, el código priorizaba innecesariamente el endpoint `/image` (un segundo request, y por lo tanto un segundo consumo de cuota) en vez de usar el `gifUrl` que la propia búsqueda ya devuelve cuando está disponible — duplicando el gasto de cuota por cada ejercicio mostrado.

**Cambios realizados**:
- `getExerciseMediaUrl()` (`server/_core/musclewiki.ts`) ahora prioriza `exercise.gifUrl` (si la búsqueda ya lo trae) antes de llamar al endpoint `/image` — reduce a la mitad el consumo de cuota de RapidAPI por ejercicio.
- Se agregó `server/_core/freeExerciseDb.ts`: fallback gratuito sin API key ni límite de cuota, usando el dataset público [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (873 ejercicios, servido vía CDN de jsDelivr, cacheado en memoria tras la primera carga). Usa matching por solapamiento de palabras (todas las palabras del nombre buscado deben estar en el candidato) y elige el nombre más corto/genérico entre los candidatos válidos, para evitar falsos positivos.
- `getExerciseMediaUrl()` ahora intenta primero RapidAPI y, si falla (cuota agotada, timeout, sin match), cae automáticamente a `getFreeExerciseMedia()`.

**Archivos modificados**: `server/_core/musclewiki.ts`, `server/_core/freeExerciseDb.ts` (nuevo).

**Verificación**: probado en vivo contra el servidor de desarrollo real (`tsx watch`, ya corriendo) vía `training.searchExerciseWithMedia` — con la cuota de RapidAPI agotada, devuelve igual una imagen válida (HTTP 200) desde el fallback gratuito para "Bench Press", "Push-up", "Barbell Squat", "Pull-up". Cobertura del dataset gratuito contra nombres típicos del catálogo: ~90% (27/30 en la muestra probada); casos sin cobertura confirmados: "Bulgarian Split Squat" y "Wall Sit" (no existen en ese dataset con ningún nombre equivalente).

**Pendientes**: decidir si conviene además cambiar de proveedor/plan de pago para RapidAPI (el usuario evaluará esto por su cuenta); considerar cachear también las respuestas de RapidAPI (hoy cada búsqueda es una llamada nueva, sin cache compartida entre usuarios).
