# 04 · Inventario de Funcionalidades

> Última actualización: 2026-07-04
> Estados posibles: **Completo**, **En desarrollo**, **Pendiente**, **Obsoleto**

---

### 1. Autenticación (Clerk)
- **Descripción**: Login/registro de usuarios, sesión persistente, sincronización de identidad con la base de datos propia.
- **Objetivo**: Dar acceso seguro y personalizado a cada usuario.
- **Pantallas**: `Home.tsx` (botones de entrada), guard en `App.tsx` (`ProtectedRoute`/`AuthenticatedRoute`) para el resto.
- **Backend**: `server/_core/context.ts` (decodificación de JWT de Clerk, upsert de usuario), `server/_core/mobileApi.ts` (endpoints `clerk/*` para Flutter).
- **Servicios**: Clerk (frontend SDK + API server-to-server).
- **Modelos**: `users` (Drizzle).
- **Criticidad**: **Alta** (bloquea todo el resto de la app).
- **Dependencias**: `@clerk/clerk-react`, variables `VITE_CLERK_PUBLISHABLE_KEY`/`CLERK_SECRET_KEY`.
- **Estado**: Completo, pero con deuda técnica relevante (JWT no verificado criptográficamente, doble path de auth Manus+Clerk) — ver [07_TECHNICAL_DEBT.md](07_TECHNICAL_DEBT.md).

---

### 2. Wizard de creación de plan personalizado
- **Descripción**: Formulario de 5 pasos que recolecta objetivo, nivel, datos físicos, días/equipo, lesiones y preferencias.
- **Objetivo**: Capturar el input necesario para que la IA genere un plan a medida.
- **Pantallas**: `TrainingPlanSelector.tsx` (modal), invocado desde `Dashboard.tsx` y `Entrenamiento.tsx`.
- **Backend**: `training.createPlan` (`routers.ts`).
- **Servicios**: ninguno externo directo (solo tRPC).
- **Modelos**: input validado con Zod, no persiste por sí mismo (delega a la generación de plan).
- **Criticidad**: **Alta**.
- **Dependencias**: Feature #3 (generación IA).
- **Estado**: Completo. Mejora reciente registrada en BITACORA.md: reemplazo de textareas libres por tags seleccionables para lesiones/preferencias.

---

### 3. Generación de planes de entrenamiento + nutrición por IA
- **Descripción**: Motor que arma un prompt con el perfil del usuario, invoca un LLM con salida JSON estructurada y estrictamente tipada, valida/ajusta el resultado por reglas de negocio determinísticas, y lo enriquece con GIFs y traducciones.
- **Objetivo**: Reemplazar a un entrenador/nutricionista humano en la personalización inicial del plan.
- **Pantallas**: resultado consumido por `GeneratedTrainingPlanView.tsx`, `Nutricion.tsx`, `Dashboard.tsx`.
- **Backend**: `generatePersonalizedPlanWithNutrition`, `validateGeneratedPlan`, `generateBasicPlan` (fallback), todos en `server/routers.ts`.
- **Servicios**: `invokeLLM` (`_core/llm.ts`, proxy "Forge"), catálogo RAG (`_core/catalog.ts`), traducción/GIFs (`_core/translations.ts`, `_core/musclewiki.ts`).
- **Modelos**: `training_plans.generatedContent` (JSON libre, sin tabla normalizada).
- **Criticidad**: **Alta** — es el corazón del producto.
- **Dependencias**: `BUILT_IN_FORGE_API_KEY`/`BUILT_IN_FORGE_API_URL` configurados; sin ellos cae siempre al fallback determinístico.
- **Estado**: Completo (con fallback robusto). Pendiente según roadmap propio: Chain-of-Thought multi-paso y regeneración granular de un solo ejercicio (ver [10_ROADMAP.md](10_ROADMAP.md)).

---

### 4. Catálogo RAG de ejercicios
- **Descripción**: Lista cerrada de ~100 nombres de ejercicios válidos (en inglés) por grupo muscular, inyectada en el prompt para evitar alucinaciones del LLM.
- **Objetivo**: Garantizar que todo ejercicio generado tenga un nombre "real" buscable en ExerciseDB.
- **Backend**: `server/_core/catalog.ts` (`EXERCISE_CATALOG`, `getCatalogPromptString`).
- **Criticidad**: **Alta** (mitigación directa de un problema conocido de calidad de producto).
- **Estado**: Completo.

---

### 5. Enriquecimiento de ejercicios (GIFs + traducción)
- **Descripción**: Para cada ejercicio del plan, busca un GIF demostrativo en ExerciseDB y traduce el nombre de inglés a español conservando el original.
- **Pantallas**: `ExerciseCard.tsx`, `GeneratedTrainingPlanView.tsx`, `ExerciseChecklist.tsx`.
- **Backend**: `_core/musclewiki.ts` (`getExerciseMediaUrl`, `searchExerciseWithMedia`), `_core/translations.ts`; se ejecuta tanto en la generación inicial como de forma perezosa en `training.getActivePlan` (re-enriquece planes viejos que aún no tenían GIF).
- **Servicios**: ExerciseDB vía RapidAPI (dos hosts distintos: `exercisedb.p.rapidapi.com` y `exercise-db-fitness-workout-gym.p.rapidapi.com`).
- **Criticidad**: **Media-Alta** (impacta UX pero el plan sigue siendo usable sin GIF).
- **Estado**: Completo, con manejo de errores silencioso (si la API falla, simplemente no hay GIF).

---

### 6. Filtro/adaptación por lesiones y equipo disponible
- **Descripción**: Sustituye ejercicios incompatibles con el equipo declarado (bodyweight/mancuernas) o con lesiones reportadas (pierna, hombro) por alternativas seguras, vía heurísticas de texto.
- **Backend**: `validateGeneratedPlan()` en `routers.ts` (activo), más un módulo paralelo `server/_core/injuryFilter.ts` (**no conectado a ningún flujo real** — código muerto).
- **Criticidad**: **Alta** (seguridad del usuario final).
- **Estado**: **En desarrollo / inconsistente** — la lógica activa vive duplicada e in-line en `routers.ts`; existe un segundo módulo más estructurado (`injuryFilter.ts`) que no se usa. Ver recomendación en Technical Debt.

---

### 7. Ejecución de entrenamiento / Checklist de series
- **Descripción**: El usuario marca cada serie de cada ejercicio como completada (con peso/reps opcionales), lo que dispara cálculo de XP, actualización de racha y verificación de logros.
- **Pantallas**: `ExerciseChecklist.tsx`, `GeneratedTrainingPlanView.tsx`.
- **Backend**: `training.markSeriesComplete` (el procedure más complejo del sistema).
- **Modelos**: `daily_checklists`, `user_progress`, mutación del JSON `training_plans.generatedContent`.
- **Criticidad**: **Alta**.
- **Estado**: Completo.

---

### 8. Gamificación (XP, niveles, rachas, logros)
- **Descripción**: Motor de progresión: XP por serie completada, niveles (cada 500 XP), racha de días consecutivos (tolerante a la frecuencia semanal del plan), y logros desbloqueables automáticamente.
- **Pantallas**: `Dashboard.tsx` (barra de XP), `Progreso.tsx` (grid de logros, stats).
- **Backend**: `db.updateUserProgress`, `db.checkAndUnlockAchievements`, lógica de racha embebida en `markSeriesComplete`.
- **Modelos**: `user_progress`, `achievements`, `user_achievements`.
- **Criticidad**: **Media** (retención/engagement, no crítico funcionalmente).
- **Estado**: Completo, con la duplicación de lógica de racha mencionada en el punto 6/Technical Debt.

---

### 9. Dashboard y tips de IA
- **Descripción**: Resumen diario (gráfico semanal, checklist de hoy, stats de salud simuladas) + 3 consejos generados por LLM según el contexto real del usuario (XP, racha, objetivo).
- **Pantallas**: `Dashboard.tsx`.
- **Backend**: `training.getDashboardData`, `training.getAITips`.
- **Criticidad**: **Media**.
- **Estado**: Completo. Nota: las métricas de "pasos/calorías" y "HR/sueño/recuperación" del Dashboard son **datos mock** (no hay integración con wearables ni tracking real de esas métricas).

---

### 10. Historial y calendario de progreso
- **Descripción**: Calendario visual (anillos de progreso estilo Apple Fitness) de los últimos/próximos ~120 días, con detalle de series/foco/XP por día seleccionado.
- **Pantallas**: `Progreso.tsx`, `TrainingCalendar.tsx`, `DayDetailsDrawer.tsx`.
- **Backend**: `training.getCompletedDates`, `training.getChecklists`, `training.getDayDetails`.
- **Criticidad**: **Media**.
- **Estado**: Completo (rediseño de anillos SVG documentado en [WALKTHROUGH.md](../WALKTHROUGH.md), 2026-07-04).

---

### 11. Gráficos de progreso por ejercicio
- **Descripción**: Evolución de peso, reps, duración y XP por ejercicio específico (Recharts).
- **Pantallas**: `ProgressGraphs.tsx` en `Progreso.tsx`.
- **Backend**: depende de `exercise_history` / datos embebidos en el plan — la tabla `exercise_history` existe en el schema pero no se ve poblada activamente desde `routers.ts` hoy.
- **Criticidad**: **Baja-Media**.
- **Estado**: **En desarrollo** (UI lista, fuente de datos histórica incompleta/no confirmada).

---

### 12. Exportación de plan a PDF
- **Descripción**: Genera un PDF multi-página (portada, resumen, un día por página, plan nutricional) descargable.
- **Pantallas**: `Entrenamiento.tsx` (botón descarga).
- **Backend/lib**: `client/src/lib/exportPDF.ts` (100% client-side, usa `jsPDF`).
- **Criticidad**: **Baja**.
- **Estado**: Completo.

---

### 13. Plan de nutrición
- **Descripción**: Muestra calorías diarias, macros (proteína/carbos/grasas) como anillos concéntricos, comidas del día con macros individuales, hidratación y suplementación.
- **Pantallas**: `Nutricion.tsx`.
- **Backend**: generado junto al plan de entrenamiento (`generatePersonalizedPlanWithNutrition` → campo `nutrition`), servido vía `training.getActivePlan`.
- **Criticidad**: **Media** (mencionada como "aún en evolución" en PROJECT_REVIEW.md).
- **Estado**: **En desarrollo** — funcional pero sin edición manual de comidas ni tracking de adherencia.

---

### 14. App móvil Flutter
- **Descripción**: Cliente nativo (Android/iOS/Web) que replica login, dashboard, entrenamiento, nutrición y progreso, consumiendo la API REST espejo del backend.
- **Pantallas**: `ferfit_flutter/lib/screens/*` (login, dashboard, workout, nutrition, progress tabs), `widgets/plan_wizard.dart`.
- **Backend**: `server/_core/mobileApi.ts` completo.
- **Servicios**: `ApiService` (Dart) + `ClerkService` para tokens.
- **Criticidad**: **Media** (superficie secundaria, pero mencionada activamente en el walkthrough más reciente).
- **Estado**: **En desarrollo** — branding y calentamiento visual sincronizados recientemente con la web (2026-07-04), pero es una superficie más nueva que la web.

---

### 15. Chat con IA (`AIChatBox`)
- **Descripción**: Componente de chat genérico, listo para conectar a cualquier endpoint conversacional (markdown streaming, prompts sugeridos).
- **Pantallas**: `AIChatBox.tsx` (componente existe, no se confirmó una página que lo monte en producción hoy).
- **Backend**: ninguno conectado explícitamente — es presentacional, requiere que el consumidor le pase `onSendMessage`.
- **Criticidad**: **Baja**.
- **Estado**: **Pendiente de integración** (componente completo, sin feature de negocio que lo use activamente todavía).

---

### 16. Integraciones de plataforma sin usar (mapas, notificaciones push, generación de imágenes, transcripción de voz, heartbeat)
- **Descripción**: Helpers preconfigurados heredados del scaffold "Manus" (`server/_core/map.ts`, `notification.ts`, `imageGeneration.ts`, `voiceTranscription.ts`, `heartbeat.ts`).
- **Criticidad**: **N/A** (no forman parte de ninguna feature de FerFit hoy).
- **Estado**: **Obsoleto / sin usar** — candidatos a eliminación si no hay planes de usarlos (ver [07_TECHNICAL_DEBT.md](07_TECHNICAL_DEBT.md)).
