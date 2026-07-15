# 08 · Registro de Decisiones Arquitectónicas (ADR)

> Última actualización: 2026-07-04
> Cada entrada nueva se agrega al final. No se borran decisiones anteriores, aunque queden obsoletas (se marcan como tal).

---

## D-001 — Migración de autenticación: Manus OAuth → Clerk
- **Fecha**: previa a 2026-07-01 (según `todo.md` y commits históricos)
- **Motivo**: la plataforma de scaffolding original ("Manus") proveía OAuth propio, pero el producto necesitaba un proveedor de auth estándar, con SDKs web y mobile maduros.
- **Problema**: `useAuth` legado y el flujo OAuth de Manus no cubrían bien el caso de app móvil nativa (Flutter) ni ofrecían UI de login lista.
- **Solución adoptada**: se integró Clerk como proveedor principal (`@clerk/clerk-react` en el cliente, verificación de token en `server/_core/context.ts`). El código de Manus OAuth (`sdk.ts`, `oauth.ts`) se dejó en el repo como **primer intento** dentro de `createContext`, cayendo a Clerk si falla.
- **Impacto**: doble camino de autenticación convive en el backend (ver [07_TECHNICAL_DEBT.md](07_TECHNICAL_DEBT.md) #11). El frontend también conserva `useAuth` legado y `ManusDialog.tsx` sin eliminar.
- **Archivos afectados**: `server/_core/context.ts`, `server/_core/sdk.ts`, `server/_core/oauth.ts`, `client/src/App.tsx`, `client/src/components/ClerkTokenProvider.tsx`, `client/src/_core/hooks/useAuth.ts`.
- **Estado**: Vigente (con deuda técnica pendiente de limpieza).

---

## D-002 — Adopción de Structured Outputs (JSON Schema estricto) para la generación de planes
- **Fecha**: 2026-07-04
- **Motivo**: el parseo previo de la respuesta del LLM se hacía recortando strings (buscando bloques ```json), un método frágil.
- **Problema**: el LLM podía devolver JSON mal formado o con estructura inconsistente, rompiendo el parseo en el cliente.
- **Solución adoptada**: se definió `planSchema` (JSON Schema con `additionalProperties: false` y todos los campos `required`) y se pasa a `invokeLLM` vía `outputSchema`/`response_format: json_schema, strict: true`, garantizando que la API del LLM rechace o corrija respuestas que no calcen con el esquema.
- **Impacto**: mayor confiabilidad del parseo; introduce acoplamiento manual entre `planSchema` (backend) y `GeneratedTrainingAndNutritionPlan` (frontend) — ver [07_TECHNICAL_DEBT.md](07_TECHNICAL_DEBT.md) #8.
- **Archivos afectados**: `server/routers.ts` (`generatePersonalizedPlanWithNutrition`, `planSchema`), `server/_core/llm.ts` (soporte de `outputSchema`).
- **Estado**: Vigente.

---

## D-003 — Catálogo RAG cerrado de ejercicios
- **Fecha**: 2026-07-04
- **Motivo**: el LLM podía "alucinar" nombres de ejercicios que no existen en ninguna base de datos de imágenes, dejando ejercicios sin GIF/instrucciones visuales.
- **Problema**: UX degradada cuando un ejercicio generado no se podía enriquecer con media.
- **Solución adoptada**: se creó `server/_core/catalog.ts` con una lista curada de ~100 nombres de ejercicios por grupo muscular, inyectada en el prompt con la instrucción explícita de elegir *exclusivamente* de esa lista.
- **Impacto**: reduce drásticamente la tasa de ejercicios sin GIF; limita la variedad de ejercicios que el LLM puede proponer (trade-off aceptado).
- **Archivos afectados**: `server/_core/catalog.ts` (nuevo), `server/routers.ts` (uso en el prompt).
- **Estado**: Vigente.

---

## D-004 — Reemplazo de inputs de texto libre por tags seleccionables (lesiones/preferencias)
- **Fecha**: 2026-07-04
- **Motivo**: texto libre para lesiones y preferencias generaba inputs ambiguos, difíciles de mapear de forma determinística a reglas de negocio (equipo, sustitución de ejercicios).
- **Problema**: la heurística de sustitución de ejercicios por lesión dependía de que el usuario escribiera ciertas palabras clave; con texto libre esto era poco confiable.
- **Solución adoptada**: en el paso 4/5 del wizard (`TrainingPlanSelector.tsx`) se reemplazaron los `Textarea` por listas de tags/chips seleccionables (`INJURY_OPTIONS`, `PREFERENCE_OPTIONS`), manteniendo un campo de texto pequeño como "Otros" para casos no cubiertos.
- **Impacto**: mejora la tasa de acierto de las heurísticas de `validateGeneratedPlan`, pero esas heurísticas siguen siendo basadas en substring matching, no en los valores exactos de los tags — posible mejora futura (ver [10_ROADMAP.md](10_ROADMAP.md)).
- **Archivos afectados**: `client/src/components/TrainingPlanSelector.tsx`.
- **Estado**: Vigente.

---

## D-005 — Reprogramación completa del fallback `generateBasicPlan`
- **Fecha**: 2026-07-04
- **Motivo**: el fallback anterior (usado cuando falla la llamada al LLM, p. ej. sin créditos/API key) era genérico y no reflejaba el perfil del usuario.
- **Problema**: usuarios sin acceso a LLM (o durante caídas del proveedor) recibían un plan poco personalizado.
- **Solución adoptada**: se reescribió `generateBasicPlan` para adaptar dinámicamente series/reps/descanso según nivel de experiencia y objetivo, e inyectar/reemplazar ejercicios según equipo y preferencia de "solo core", usando las mismas reglas de negocio que aplican al plan generado por IA.
- **Impacto**: el producto sigue siendo funcional y razonablemente personalizado incluso sin IA disponible.
- **Archivos afectados**: `server/routers.ts` (`generateBasicPlan`).
- **Estado**: Vigente.

---

## D-006 — Rediseño del calendario web como "anillos de progreso" (estilo Apple Fitness)
- **Fecha**: 2026-07-04
- **Motivo**: la grilla de tarjetas de texto anterior para el calendario de actividad era poco escaneable visualmente.
- **Problema**: difícil distinguir de un vistazo días de descanso, días programados sin progreso, y días completados parcial/totalmente.
- **Solución adoptada**: se reemplazó por una grilla ultra-compacta de anillos SVG que se llenan según % de series completadas, con colores de marca; días de descanso como puntos grises.
- **Impacto**: mejor legibilidad del historial; alineado visualmente con la sincronización de branding hecha en Flutter en la misma fecha (ver D-007).
- **Archivos afectados**: `client/src/components/TrainingCalendar.tsx`.
- **Estado**: Vigente. Documentado también en [WALKTHROUGH.md](../WALKTHROUGH.md).

---

## D-007 — Sincronización de branding (colores/glows) entre Web y Flutter
- **Fecha**: 2026-07-04
- **Motivo**: la app móvil Flutter no reflejaba la paleta de marca (verde + morado, glows) ya establecida en la web.
- **Problema**: inconsistencia visual entre plataformas del mismo producto.
- **Solución adoptada**: se actualizó el `darkTheme` de Flutter para incluir el morado (`0xFF8B5CF6`) como color secundario, y se agregaron gradientes radiales (glows) en `login_screen.dart` replicando el fondo de la web.
- **Impacto**: consistencia de marca entre web y móvil.
- **Archivos afectados**: `ferfit_flutter/lib/main.dart`, `ferfit_flutter/lib/screens/login_screen.dart`.
- **Estado**: Vigente. Documentado también en [WALKTHROUGH.md](../WALKTHROUGH.md).

---

## D-008 — Creación de documentación técnica formal en `/docs`
- **Fecha**: 2026-07-04
- **Motivo**: la documentación existente (`BITACORA.md`, `PROJECT_REVIEW.md`, `WALKTHROUGH.md`) es valiosa pero mezcla bitácora de producto con arquitectura, y no cubre exhaustivamente frontend/backend/deuda técnica de forma estructurada y navegable.
- **Problema**: onboarding de nuevos desarrolladores (humanos o agentes) requería releer código fuente completo para entender el sistema.
- **Solución adoptada**: se creó la carpeta `docs/` con 10 documentos temáticos (overview, frontend, backend, features, arquitectura con diagramas Mermaid, mapa de funciones, deuda técnica, decisiones, changelog, roadmap), basados en una exploración exhaustiva del código fuente real (no solo de la documentación previa).
- **Impacto**: nueva fuente de verdad técnica que debe mantenerse sincronizada con el código en cada cambio relevante (regla de trabajo establecida por el usuario).
- **Archivos afectados**: `docs/*.md` (nuevos).
- **Estado**: Vigente.

---

## D-009 — El fallback sin IA reutiliza `validateGeneratedPlan` en vez de duplicar reglas
- **Fecha**: 2026-07-04
- **Motivo**: bug reportado por el usuario — con lesión de muñeca declarada, el plan seguía recomendando flexiones de brazos.
- **Problema**: `generateBasicPlan` (el camino usado siempre que no hay `BUILT_IN_FORGE_API_KEY` configurada) no tenía ninguna noción de lesiones o equipo; esa lógica solo existía en `validateGeneratedPlan`, aplicada únicamente al camino con IA.
- **Solución adoptada**: en vez de escribir una segunda implementación de filtrado dentro de `generateBasicPlan` (que hubiera duplicado las reglas y sido una nueva fuente de drift), se hizo que `generateBasicPlan` construya su plan y lo pase por `validateGeneratedPlan(plan, input)` antes de devolverlo — mismo código, dos caminos de generación.
- **Impacto**: ambos caminos (con y sin IA) ahora respetan lesiones/equipo de forma consistente. De paso, se completó `LOWER_BODY_EXERCISES` para cubrir `Glute Bridge`, `Hip Thrust` y `Wall Sit`, que existían en el catálogo pero no eran reconocidos por el filtro.
- **Archivos afectados**: `server/routers.ts`.
- **Estado**: Vigente. Queda pendiente unificar esto con `server/_core/injuryFilter.ts` (todavía sin usar) — ver [07_TECHNICAL_DEBT.md](07_TECHNICAL_DEBT.md) #5.

---

## D-010 — Fallback gratuito (free-exercise-db) para medios de ejercicios cuando RapidAPI falla
- **Fecha**: 2026-07-04
- **Motivo**: bug reportado por el usuario — no se mostraban GIFs de ejercicios. Diagnóstico: la key de RapidAPI para ExerciseDB tiene la cuota mensual agotada (plan BASIC), confirmado con una llamada real a la API (HTTP 429).
- **Problema secundario detectado en el mismo diagnóstico**: el código llamaba innecesariamente a un segundo endpoint (`/image`, vía el proxy `/api/exercise-image`) por cada ejercicio, en vez de usar el `gifUrl` que la propia búsqueda por nombre ya devuelve — duplicando el consumo de cuota.
- **Solución adoptada**: (1) se reordenó `getExerciseMediaUrl` para preferir `exercise.gifUrl` directo antes de llamar a `/image`; (2) se agregó `server/_core/freeExerciseDb.ts`, un fallback que consulta el dataset público [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (sin API key, sin límite de cuota, cacheado en memoria) cuando RapidAPI falla por cualquier motivo.
- **Impacto**: se reduce a la mitad el consumo de cuota de RapidAPI por ejercicio, y aunque esa cuota esté agotada, la mayoría de los ejercicios (~90% en la muestra probada) siguen mostrando una imagen. Limitación conocida: el dataset gratuito usa fotos estáticas, no GIFs animados, y no cubre el 100% de los nombres del catálogo (ej. "Bulgarian Split Squat", "Wall Sit" no tienen equivalente).
- **Archivos afectados**: `server/_core/musclewiki.ts`, `server/_core/freeExerciseDb.ts` (nuevo).
- **Estado**: Vigente.

---

## D-011 — Evaluada y descartada la integración de HyperHuman Content API
- **Fecha**: 2026-07-04
- **Motivo**: el usuario pidió evaluar integrar `hyperhuman.cc` como fuente de contenido de ejercicios.
- **Investigación**: se ubicó la documentación real de la API (`https://content.api.hyperhuman.cc/openapi.json`, `/AGENTS.md`, `/llms-full.txt`, no listados en la página pública renderizada por JS). Es una plataforma B2B completa (publicar contenido, recomendar/generar/adaptar rutinas con IA, insights), no un simple proveedor de GIFs. Requiere cuenta de organización + API key, con planes de pago (`free`, `content` $79/mes, `platform` $239/mes, `ultra` $479/mes).
- **Problema**: el endpoint más parecido a nuestra necesidad actual (`GET /v1/orgs/{organizationId}/stock-exercises`, catálogo de clips de ejercicios individuales) está documentado explícitamente como **"Custom / Enterprise plans only"** — no disponible en ningún plan de autoservicio. El otro endpoint de video (`video-assets`) es "workspace-only" (solo contenido subido por el propio usuario, no un catálogo genérico). Su motor de generación de rutinas por IA solaparía con `generatePersonalizedPlanWithNutrition`, que ya funciona sin costo variable.
- **Solución adoptada**: no integrar HyperHuman por ahora. Se mantiene la solución vigente (ExerciseDB + fallback gratuito `freeExerciseDb.ts` de D-010).
- **Impacto**: ninguno en el código. Si en el futuro se negocia un plan Enterprise con HyperHuman, esta investigación (URLs de la API, requisitos de acceso) queda como punto de partida.
- **Archivos afectados**: ninguno.
- **Estado**: Descartada (por ahora) — revisar si cambian las condiciones de acceso o el presupuesto disponible.
