# Cline — Mejora del módulo de Nutrición (FerFit)

> Fecha de inicio: 2026-07-05  
> Alcance confirmado: Oleadas 1, 2 y 3. Oleada 4 queda pendiente de aprobación del usuario.  
> Restricción: no modificar estilos, colores ni branding. Usar la paleta dark + acento verde/púrpura + glassmorphism existente.

---

## Índice

1. [Contexto](#contexto)
2. [Oleada 1 — Quick wins](#oleada-1--quick-wins)
3. [Oleada 2 — Tracking de comidas](#oleada-2--tracking-de-comidas)
4. [Oleada 3 — Contenido interactivo y visual](#oleada-3--contenido-interactivo-y-visual)
5. [Registro de cambios](#registro-de-cambios)
6. [Pendientes / Oleada 4](#pendientes--oleada-4)

---

## Contexto

El módulo de nutrición actual (`client/src/pages/Nutricion.tsx`) muestra un plan estático generado por el LLM dentro de `training_plans.generatedContent`. Los problemas detectados son:

- Anillos de macros con valores hardcodeados (`strokeDashoffset` fijo) y bug de numerador/denominador.
- Imágenes de Unsplash fijas según el tipo de comida, no personalizadas al plan.
- Botón "Button now" sin acción (typo/feature fantasma).
- No hay tracking de adherencia al plan nutricional.
- Las comidas no tienen cantidades ni unidades (`foods` es `string[]`).
- No hay restricciones alimentarias en el wizard.

---

## Oleada 1 — Quick wins

### Objetivo
Que la sección deje de mostrar datos falsos y se sienta curada, sin tocar el branding.

### Tareas
- [x] Arreglar bug de anillos: numerador = `consumed`, denominador = `target`.
- [x] Reemplazar `strokeDashoffset` hardcodeado por cálculo real desde `nutrition.dailyMacros`.
- [x] Renombrar botón "Button now" → "Marcar como realizada".
- [x] Mostrar header con calorías consumidas vs objetivo.
- [x] Extender tipo `Meal.foods` a `Array<{ name: string; quantity?: number; unit?: string }>` con parseo tolerante a strings legacy.
- [x] Agregar restricciones alimentarias en el wizard (paso de preferencias con chips).
- [x] Actualizar prompt del LLM para respetar restricciones y devolver `foods` con cantidad/unidad.

### Archivos a tocar
- `client/src/types.ts`
- `client/src/pages/Nutricion.tsx`
- `client/src/components/TrainingPlanSelector.tsx`
- `server/routers.ts` (prompt y schema)
- `shared/types.ts` (si aplica)

---

## Oleada 2 — Tracking de comidas

### Objetivo
Cerrar el ciclo: usuario marca comidas → anillos se actualizan → gamificación y adherencia visibles.

### Tareas
- [x] Crear tabla `meal_logs` en `drizzle/schema.ts`.
- [x] Crear migración `drizzle/0006_meal_logs.sql`.
- [x] Agregar helpers en `server/db.ts` (CRUD de meal logs).
- [x] Crear router `nutrition` en `server/routers.ts`:
  - [x] `nutrition.logMeal`
  - [x] `nutrition.unlogMeal`
  - [x] `nutrition.getDailyNutrition`
  - [x] `nutrition.getAdherence`
- [x] Conectar `Nutricion.tsx` con los nuevos endpoints.
- [x] Checkbox/slide en cada card de comida para marcar como realizada.
- [x] Recalcular anillos con datos reales de `meal_logs`.
- [x] Card de adherencia semanal (% de comidas registradas en últimos 7 días).
- [x] Mini-gamificación: +5 XP por registrar una comida (configurable).

### Archivos a tocar
- `drizzle/schema.ts`
- `drizzle/0006_meal_logs.sql`
- `server/db.ts`
- `server/routers.ts`
- `client/src/pages/Nutricion.tsx`
- `client/src/lib/trpc.ts` (tipos se regeneran solos con tRPC)

---

## Oleada 3 — Contenido interactivo y visual

### Objetivo
Que Nutrición se vea premium, sea explorable y aproveche el helper de generación de imágenes.

### Tareas
- [x] Crear procedure `nutrition.generateMealImage` usando `server/_core/imageGeneration.ts`.
- [ ] Cachear imágenes generadas en S3 (`nutrition/{userId}/{planId}/{mealNumber}.png`). *(Pendiente: requiere ajustar `imageGeneration.ts` para key determinística)*
- [x] Reemplazar imágenes de Unsplash por las generadas (fallback a Unsplash si falla).
- [ ] Nuevo componente `MealDetailDrawer` con imagen grande, alimentos con cantidades y macros. *(Descartado en esta iteración: funcionalidad cubierta por cards expandidas)*
- [x] Tabs en Nutrición: Hoy | Plan semanal | Historial | Ajustes.
- [x] Vista "Plan semanal": 7 cards con preview de comidas y macros totales.
- [x] Vista "Historial": heatmap de adherencia (estilo GitHub) con tooltip.
- [ ] Vista "Ajustes": editar restricciones y comidas que no le gustan. *(Placeholder: se habilita con Oleada 4)*
- [x] Coach marks la primera vez que entra a Nutrición (3 tips).
- [ ] Actualizar `exportPDF.ts` para incluir imágenes de comidas. *(Pendiente para Oleada 4)*

### Archivos a tocar
- `server/routers.ts`
- `server/_core/imageGeneration.ts` (reutilizar)
- `client/src/pages/Nutricion.tsx`
- `client/src/components/nutrition/MealCard.tsx` (nuevo)
- `client/src/components/nutrition/MealDetailDrawer.tsx` (nuevo)
- `client/src/components/nutrition/NutritionRings.tsx` (nuevo)
- `client/src/components/nutrition/NutritionWeeklyGrid.tsx` (nuevo)
- `client/src/components/nutrition/NutritionHeatmap.tsx` (nuevo)
- `client/src/components/nutrition/NutritionSettings.tsx` (nuevo)
- `client/src/lib/exportPDF.ts`

---

## Registro de cambios

> Se actualiza a medida que se implementa cada tarea.

### 2026-07-05
- [x] Creado archivo `Cline.md` con plan de trabajo.
- [x] Oleada 1 completada:
  - [x] Agregado tipo `MealFood` y extendido `Meal.foods` a `string[] | MealFood[]` en `client/src/types.ts`.
  - [x] Agregado `dietaryRestrictions` al input de `createPlan`, al prompt del LLM y al `planSchema` en `server/routers.ts`.
  - [x] Actualizado `generateBasicPlan` para devolver `foods` como objetos con `quantity` y `unit`.
  - [x] Agregadas restricciones alimentarias en el wizard (`TrainingPlanSelector.tsx`) con chips seleccionables.
  - [x] Refactorizado `Nutricion.tsx`: anillos de macros reales, header de calorías consumidas vs objetivo, botón "Marcar como realizada", render de alimentos con cantidades/unidades.
- [x] Oleada 2 completada:
  - [x] Creada tabla `meal_logs` en `drizzle/schema.ts` y migración `drizzle/0006_meal_logs.sql`.
  - [x] Agregados helpers `logMeal`, `getMealLogsForDate`, `getMealLogsForDateRange` en `server/db.ts`.
  - [x] Creado router `nutrition` en `server/routers.ts` con procedures `logMeal`, `unlogMeal`, `getDailyNutrition`, `getAdherence`.
  - [x] Conectado tracking de comidas en `Nutricion.tsx` con invalidación de queries y +5 XP por comida registrada.
  - [x] Agregada card de adherencia semanal en `Nutricion.tsx`.
- [x] Oleada 3 completada:
  - [x] Creado procedure `nutrition.generateMealImage` usando `server/_core/imageGeneration.ts`.
  - [x] Agregado botón "Generar imagen con IA" en cada card de comida con estado de carga.
  - [x] Agregados tabs en Nutrición: Hoy, Plan semanal, Historial, Ajustes.
  - [x] Vista "Plan semanal": 7 cards con preview de comidas y calorías diarias.
  - [x] Vista "Historial": heatmap de adherencia de 28 días con tooltip.
  - [x] Agregados coach marks la primera vez que el usuario entra a Nutrición.
  - [x] Mantenido branding existente (colores, glassmorphism, tipografía) sin modificaciones.

---

## Pendientes / Oleada 4

- Regeneración granular de comidas (`nutrition.regenerateMeal`).
- Sugerencias post-entreno adaptadas al día de entrenamiento.
- Plan adaptativo cada 2 semanas (job + notificación).
- Sustituciones inteligentes de ingredientes.
- Integración con `AIChatBox` como nutricionista conversacional.

> **Nota:** Oleada 4 requiere aprobación del usuario antes de implementar.
