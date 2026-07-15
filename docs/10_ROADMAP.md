# 10 · Roadmap

> Última actualización: 2026-07-04. Documento vivo — actualizar en cada sesión de trabajo relevante.

---

## En progreso
*(nada activo identificado al momento de esta auditoría — el working tree tiene cambios grandes sin commitear que corresponden a la entrada de changelog del 2026-07-04)*

---

## Pendiente (declarado en BITACORA.md, aún no implementado)

- **Chain of Thought / múltiples pasos de inferencia**: dividir la generación de planes en pasos más pequeños (Estrategia → Selección de ejercicios → Nutrición) en vez de un único prompt masivo, para evitar sobrecarga de contexto y mejorar precisión.
- **Regeneración granular de ejercicios**: permitir "Cambiar este ejercicio" para reemplazar un ejercicio puntual sin tener que regenerar todo el plan de 12 semanas.

## Pendiente (identificado durante esta auditoría técnica)

- Unificar `validateGeneratedPlan` (filtrado por lesiones/equipo) con `server/_core/injuryFilter.ts`, que sigue sin usarse — hoy la lógica activa vive inline en `routers.ts` (ver D-009 en [08_DECISIONS.md](08_DECISIONS.md)).
- Evaluar upgradear el plan de RapidAPI para ExerciseDB (cuota BASIC agotada) o cachear sus respuestas entre usuarios — mitigado parcialmente con el fallback gratuito `freeExerciseDb.ts`, pero ese dataset no cubre el 100% de los nombres del catálogo (ej. "Bulgarian Split Squat", "Wall Sit").
- Unificar el cálculo de racha (streak) en un solo lugar (hoy duplicado entre `db.updateUserProgress` y `markSeriesComplete` — ver [07_TECHNICAL_DEBT.md](07_TECHNICAL_DEBT.md) #4).
- Verificar criptográficamente el JWT de Clerk en `createContext` en vez de decodificarlo sin validar firma (Technical Debt #1).
- Decidir el futuro de las integraciones de plataforma "Manus" sin usar (mapas, notificaciones, voz, generación de imágenes, heartbeat): eliminarlas o planificar su uso.
- Consolidar el diccionario de traducción de ejercicios (cliente/servidor) en `shared/`.
- Definir una única fuente de verdad (Zod compartido) para el schema del plan de IA, evitando el drift manual entre `planSchema` (backend) y `types.ts` (frontend).

---

## Finalizado

- Autenticación completa con Clerk (web + móvil), con hash SHA-256 de tokens como fallback en backend.
- Migración a Structured Outputs (JSON Schema estricto) para la generación de planes.
- Catálogo RAG de ejercicios para evitar alucinaciones del LLM.
- Fallback determinístico (`generateBasicPlan`) totalmente personalizado por nivel/objetivo/equipo/preferencias.
- Wizard de 5 pasos con tags seleccionables para lesiones y preferencias.
- Sistema de gamificación: XP, niveles, rachas, logros automáticos.
- Historial de entrenamiento + calendario con anillos de progreso SVG.
- Exportación de plan a PDF.
- Gráficos de progreso por ejercicio (Recharts).
- App móvil Flutter funcional (login, dashboard, entrenamiento, nutrición, progreso) con branding sincronizado a la web.
- Documentación técnica formal en `docs/` (esta serie de 10 documentos).

---

## Ideas futuras (no comprometidas, sin fecha)

- Reevaluar HyperHuman Content API si en algún momento hay presupuesto para un plan Enterprise (hoy el catálogo de clips de ejercicios que necesitaríamos está gateado a ese tier) — ver D-011 en [08_DECISIONS.md](08_DECISIONS.md).

- Conectar `AIChatBox.tsx` (ya construido) a una feature real de chat con un "entrenador IA" conversacional.
- Integración real con wearables/health APIs para reemplazar los datos mock de pasos/calorías/HR/sueño del Dashboard.
- Tracking de adherencia al plan nutricional (hoy es solo informativo, sin checklist de comidas).
- Panel de administración (existe el rol `admin` en el schema de `users`, pero no hay UI ni endpoints `adminProcedure` en uso todavía).

---

## Mejoras / Refactors sugeridos

- Migrar los scripts de prueba manual sueltos en la raíz (`test_*.ts`, `tmp_clerk_*`) a la suite formal de Vitest en `tests/`.
- Sacar `app-release.apk` del control de versiones (usar releases/artifact storage).
- Estandarizar en un único package manager (pnpm) y dejar de commitear/generar `package-lock.json`.
- Restringir la configuración de CORS (`origin: true`) a una allowlist explícita.

## Optimización

- `training.getActivePlan` hace enriquecimiento (fetch a ExerciseDB + traducción) de forma perezosa dentro de una query de lectura — evaluar mover ese enriquecimiento a un job asíncrono o a la escritura inicial únicamente, para no penalizar la latencia de carga del dashboard en planes viejos con muchos ejercicios sin enriquecer.
- Evaluar cache para las llamadas a ExerciseDB (hoy cada búsqueda de GIF es una llamada HTTP nueva, incluso para ejercicios ya buscados antes por otros usuarios).
