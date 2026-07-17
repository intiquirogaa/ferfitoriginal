# Bitácora de Desarrollo - FerFit 2

Este documento sirve como registro continuo (bitácora) de la estructura del proyecto, las discusiones de diseño, las funcionalidades que estamos implementando y las modificaciones que vamos realizando en el código.

---

## 1. Estructura del Proyecto

El proyecto está construido como un monorepo que contiene tanto el cliente (Web/Móvil) como el servidor (Backend), con tipado estricto de extremo a extremo (End-to-End Type Safety).

### Frontend (Cliente Web & Mobile)
- **Web (React):** Ubicado en la carpeta `client/`. Utiliza React 19, Vite, y TailwindCSS v4. Las páginas principales están en `client/src/pages/` y los componentes en `client/src/components/`. 
- **Mobile (Flutter):** Ubicado en `ferfit_flutter/`. Es la versión en app nativa. Utiliza widgets para emular la experiencia web, como el `plan_wizard.dart`.
- **Integración:** El cliente web consume el backend usando `tRPC` a través de React Query, lo que permite llamar a funciones del servidor como si fueran locales (`trpc.training.createPlan`).
- **Gestión de Estado (Generador):** Componentes clave como `TrainingPlanSelector.tsx` manejan el Wizard de 5 pasos para recolectar métricas del usuario y enviarlas al servidor.

### Backend (Servidor)
- **Framework:** Express + tRPC. Ubicado en la carpeta `server/`.
- **Enrutamiento (API):** La lógica de negocio está centralizada en `server/routers.ts`. Aquí viven los procedimientos principales.
- **Base de Datos:** Drizzle ORM sobre una base de datos compatible con MySQL (`db.ts` maneja las consultas a las tablas `trainingPlans`, `users`, etc.).
- **Motor de IA:** En `routers.ts`, la función `generatePersonalizedPlanWithNutrition` es el núcleo de la generación de rutinas. Se comunica con un LLM (OpenAI) construyendo un prompt masivo con las preferencias y lesiones del usuario.
- **Enriquecimiento de Datos:** Se integra con *MuscleWiki* y herramientas de traducción (`./_core/musclewiki.ts`) para asignar GIFs reales a los nombres de ejercicios generados por la IA en inglés, traduciéndolos luego al español.

---

## 2. Análisis del Flujo de Recomendación (Estado Actual)

Actualmente, el sistema recomienda ejercicios de la siguiente forma:

1. **Recolección:** El usuario ingresa edad, peso, altura, días disponibles, objetivo, lesiones y preferencias de ejercicios (textos libres).
2. **Construcción del Prompt:** El backend toma estas variables y las inyecta en un prompt Zero-Shot (de una sola vez) instruyendo a la IA a comportarse como un Personal Trainer. Si el usuario escribe la palabra "core" o "abdominales", se inyectan reglas estrictas adicionales al prompt (Línea 919 de `routers.ts`).
3. **Generación:** La IA devuelve un JSON estructurado de 12 semanas con los ejercicios.
4. **Validación:** Se extrae el JSON usando un método de recorte de strings (split ````json`).

**Limitaciones detectadas:**
- La IA puede "alucinar" o inventar nombres de ejercicios que no coinciden con la base de datos de GIFs.
- La validación del JSON es frágil.
- El usuario no puede regenerar un solo ejercicio, debe rehacer todo el plan.

---

## 3. Hoja de Ruta de Mejoras Planificadas

Basado en nuestro análisis, estas son las funcionalidades estructurales que buscamos implementar para mejorar el sistema de recomendación:

- [x] **Migrar a Salidas Estructuradas (Structured Outputs / Function Calling):** Usar `zod` y el estándar de llamadas a funciones de OpenAI para asegurar que el JSON generado nunca falle y tenga el esquema perfecto.
- [x] **Catálogo RAG (Retrieval-Augmented Generation):** Obligar a la IA a elegir ejercicios únicamente de una lista provista de IDs de *MuscleWiki* o base de datos interna, para que ningún ejercicio quede sin imagen.
- [ ] **Múltiples Pasos de Inferencia (Chain of Thought):** Dividir la solicitud a la IA en pasos más pequeños (Estrategia -> Selección de Ejercicios -> Nutrición) para evitar sobrecarga de contexto.
- [x] **Generación Granular de Ejercicios:** Añadir la funcionalidad de "Cambiar este ejercicio" para reemplazar un ejercicio puntual sin cambiar toda la rutina. (2026-07-17: catálogo RAG, web + Flutter + mobile API)
- [x] **Mejora en recolección de preferencias:** Cambiar las cajas de texto de Lesiones y Preferencias por *Tags* o *Chips* seleccionables (Ej: `[Evitar saltos]`) en el Frontend.

---

## 4. Registro de Cambios (Changelog)

*En esta sección iremos anotando cronológicamente las modificaciones que hagamos en el código y las nuevas funcionalidades que vayamos implementando.*

**[17-07-2026]**
- **Feature “Cambiar este ejercicio”** (regeneración granular): backend catálogo RAG + tRPC + mobile API; UI web y Flutter.
- Detalle operativo y handoff de sesión en `grokbitacora.md` §7 (2026-07-17).
- Roadmap `docs/10_ROADMAP.md` actualizado (ítem marcado finalizado).
- APK del 16/07 **no** incluye este feature; rebuild pendiente mañana si se prueba en móvil.

**[04-07-2026]**
- Análisis profundo del flujo de generación de rutinas de entrenamiento.
- Identificación de los cuellos de botella en `TrainingPlanSelector.tsx` y `routers.ts` (`generatePersonalizedPlanWithNutrition`).
- Creación de esta Bitácora para el seguimiento ordenado de las modificaciones.
- **Frontend (React)**: Se reemplazaron los `Textarea` libres en `TrainingPlanSelector.tsx` (Paso 4 del Wizard) por listas de *Tags* seleccionables (`INJURY_OPTIONS` y `PREFERENCE_OPTIONS`), manteniendo inputs de texto pequeños como opción "Otros".
- **Backend (IA & Structured Outputs)**: Se implementó un JSON Schema (`planSchema`) usando *Structured Outputs* de OpenAI (`response_format: { type: "json_schema" }`) garantizando devoluciones perfectas. 
- **Regla de Negocio (Movilidad)**: Se actualizó el prompt pidiendo explícitamente a la IA que *"CADA día DEBE empezar siempre con warmup enfocado en MOVILIDAD, y contener entre 6 a 8 ejercicios con 3 series"*.
- **Backend (Catálogo RAG)**: Se creó `server/_core/catalog.ts` con listas precisas de ejercicios y se inyectó en el contexto del LLM. La IA ahora está bloqueada y debe escoger exclusivamente de este catálogo garantizando siempre obtener los videos.
- **Backend (Fallback Complejo)**: Se reprogramó totalmente `generateBasicPlan` (Fallback sin tokens) para abarcar toda la individualización del usuario. Ahora adapta dinámicamente series, repeticiones y ejercicios según el Nivel de Experiencia (ej. variantes seguras y 2 series para principiantes), el Objetivo (Fuerza, Hipertrofia, etc.), e inyecta o reemplaza las rutinas basándose estrictamente en las Preferencias del usuario (ej. rutinas exclusivas de abdomen si escogen "solo core").

---

## 5. Plan Maestro de Fases (Gamificación y Retención)

Para llevar la retención y motivación al máximo (estilo Duolingo), el desarrollo se dividió en las siguientes fases:

### Fase 1: Gamificación y Recompensas Visuales (COMPLETADO)
- Animaciones complejas de la mascota "Feo".
- Efectos de partículas (Confetti) al completar rutinas y barras de progreso fluidas.

### Fase 2: Retención y Notificaciones Externas (COMPLETADO)
- Notificaciones push / locales inteligentes (ej. "Racha en riesgo", "Feo te extraña").
- Widget Nativo para Android que muestra nivel y racha en la pantalla de inicio.
- Integración real de medallas/insignias con Drizzle ORM.

### Fase 3: Economía Virtual y Personalización (EN PROGRESO)
- **Monedas (FerCoins/Gemas):** Ganadas con esfuerzo y rachas.
- **Tienda de Feo:** Poder comprarle skins, accesorios y "Protectores de racha".

### Fase 4: Misiones Diarias y Cofres (PLANIFICADO)
- 3 desafíos diarios dinámicos para fomentar la apertura diaria de la app.
- Cofres de botín (loot boxes) al cumplir las misiones.

### Fase 5: Sistema de Ligas (Leaderboards) (PLANIFICADO)
- Divisiones (Bronce a Diamante) con 30 personas. Ascensos y descensos semanales basados en la XP.

### Fase 6: Social y Feed de Actividad (PLANIFICADO)
- Sistema de amigos, perfiles y "High Fives" (Choques de manos) en un feed comunitario.
