# FerFit 2 - Revisión del Proyecto y Arquitectura

Este documento consolida la arquitectura, las funcionalidades, la bitácora de progreso y los detalles internos del proyecto **FerFit 2**.

## 1. Arquitectura del Proyecto

**FerFit 2** está estructurado como una aplicación monolítica moderna que separa responsabilidades en Cliente y Servidor, pero los integra fuertemente a través de TypeScript y tRPC para mantener tipado estricto end-to-end.

*   **Frontend (Cliente):** 
    *   **Framework:** React 19 + Vite.
    *   **Estilos:** TailwindCSS v4 + animaciones (`tailwindcss-animate`). UI basada en Radix UI.
    *   **Enrutamiento:** `wouter` para un enrutamiento ligero y eficiente.
    *   **Tematización:** Soporte de tema oscuro nativo y colores personalizados mediante variables CSS (OKLCH).
*   **Backend (Servidor):**
    *   **Servidor HTTP:** Express 4.
    *   **Capa API:** tRPC 11 (permite consumir los endpoints desde React con hooks como `useQuery` de `@tanstack/react-query`).
    *   **Base de Datos y ORM:** Drizzle ORM sobre MySQL/TiDB.
*   **Servicios Externos / Infraestructura:**
    *   **Autenticación:** Clerk.
    *   **Inteligencia Artificial:** Integración con LLM para la generación inteligente de planes de entrenamiento.
    *   **Catálogo de Ejercicios:** Consumo de *ExerciseDB API* para obtener datos, imágenes y GIFs de rutinas.

## 2. Bitácora de Progreso (Log)

A lo largo del desarrollo, se han completado los siguientes hitos principales:

*   **Diseño de Base de Datos:** Creación y migración de un esquema con tablas críticas: `users`, `trainingPlans`, `dailyChecklists`, `userProgress`, `exerciseHistory`, `achievements`, y `userAchievements`.
*   **Integración de Backend:** Configuración de Express y tRPC, creación de funciones helper de DB (`db.ts`).
*   **Inteligencia Artificial:** Implementación del generador de planes de entrenamiento hipertrofia/fuerza usando LLMs.
*   **Sistema de Gamificación:** Implementación de un motor de XP, niveles, rachas (streaks) y logros automatizados.
*   **Interfaz de Usuario (UI):** 
    *   Maquetado base con paleta oscura y toques *fitness*.
    *   Creación de páginas principales: *Home, Dashboard, Entrenamiento, Nutrición, Progreso*.
    *   Desarrollo de componentes interactivos: `ExerciseCard`, `GeneratedTrainingPlanView`, `CalendarMultiView`.
*   **Autenticación Segura:** Migración de sistema interno de auth a **Clerk**, implementando validación mediante hashes SHA-256 en el backend y `ClerkTokenProvider`.
*   **Mejoras UX/UI Recientes:** Integración de animaciones/GIFs de ejercicios reales (ExerciseDB), tracking detallado de series (`ExerciseChecklist`) y gráficos de evolución de progreso.

## 3. Lista de Funcionalidades

1.  **Autenticación y Perfil:** Login/Registro seguro vía Clerk. Perfil con nivel y experiencia (XP).
2.  **Generación de Planes por IA:** Creación de rutinas personalizadas adaptadas al usuario según objetivo (fuerza, hipertrofia) y disponibilidad semanal.
3.  **Catálogo de Ejercicios:** Visualización interactiva de ejercicios con instrucciones y GIFs (ExerciseDB).
4.  **Dashboard Personalizado:** Resumen diario de objetivos, estado del plan activo y estadísticas rápidas.
5.  **Ejecución de Entrenamiento:** Sistema para marcar series completadas (checklists) en tiempo real, registrando volumen y progreso.
6.  **Historial y Calendario:** Vista de calendario multi-modo (`CalendarMultiView`) para rastrear días entrenados.
7.  **Gamificación (Logros y XP):** Otorgamiento de experiencia por ejercicio y entrenamiento finalizado, desbloqueando medallas y niveles ("Primer Paso", "Guerrero de Hierro").
8.  **Nutrición:** Sección orientativa (aún en evolución) para acompañar la rutina física.
9.  **Gráficos de Progreso:** Visualización del incremento de peso y volumen levantado usando `recharts`.

## 4. Algoritmos y Lógica Interna

Internamente, el sistema se apoya en los siguientes motores lógicos, nombrados para claridad arquitectónica:

*   **`LLMTrainingGenerator` (Generador de Planes de Entrenamiento IA):**
    *   *Ubicación Lógica:* `routers.ts` (tRPC) / LLM prompts.
    *   *Propósito:* Toma los parámetros del usuario (días por semana, tipo de entrenamiento) y genera una estructura JSON robusta con días, grupos musculares, ejercicios y series recomendadas, que luego se persiste en `trainingPlans`.
*   **`GamificationEngine` (Motor de Progresión y Logros):**
    *   *Ubicación Lógica:* Funciones `updateUserProgress` y `checkAndUnlockAchievements` en `db.ts`.
    *   *Propósito:* Calcula el XP ganado según las series completadas (`xpToAdd`), recalcula niveles, mantiene el conteo de la racha (`streak`) comparando fechas, y automáticamente desbloquea logros comparando el estado actual con las condiciones (ej. `workouts_done >= 10`).
*   **`DailyTracker` (Gestor de Sesiones Diarias):**
    *   *Ubicación Lógica:* `updateChecklistProgress`, `createDailyChecklist`.
    *   *Propósito:* Mantiene el estado en tiempo real de la sesión de hoy. Si el usuario marca una serie en `SeriesChecklistItem.tsx`, este motor computa el progreso parcial.

## 5. Diseño: Wireframes y Mockups

Para acompañar esta documentación, he generado y adjuntado imágenes conceptuales:
*   Un **Wireframe** estructural para entender la disposición de los elementos sin distracciones visuales.
*   Un **Mockup** de alta fidelidad (High-fidelity UI) utilizando estéticas *dark mode*, acentos de colores vibrantes y *glassmorphism* que reflejan cómo se debería ver y sentir el proyecto en su versión óptima.

(Puedes ver estas imágenes en la conversación o en los adjuntos que acabo de generar).
