# grokbitacora.md — Bitácora de sesiones (FerFit 2)

> **Propósito:** memoria operativa entre sesiones de Grok.  
> Al empezar un chat nuevo, leer este archivo. Al cerrar trabajo útil, **agregar una entrada** al final (fecha + qué se hizo + APK/paths si aplica).

**Última actualización:** 2026-07-17 (push origin/main + checklist VPS)  
**Relacionados:** `BITACORA.md` (diseño/producto), `docs/` (arquitectura), `hy3bitacotra.md` (sesión gráficos/CORS).

**Al reabrir:** leer §2 (foco) + §7 (2026-07-17). Flutter API → `http://168.181.187.209:3000/api/mobile`.

---

## 1. Qué es FerFit 2

Plataforma de fitness con planes de **entrenamiento + nutrición** generados por IA, checklist diario, gamificación (XP, nivel, racha) y mascota **Feo**.

| Superficie | Path | Cómo habla con el backend |
|---|---|---|
| Web (React 19 + Vite + Tailwind) | `client/` | tRPC → `/api/trpc` |
| Backend (Express + tRPC + Drizzle/MySQL) | `server/` | — |
| App móvil Flutter | `ferfit_flutter/` | REST → `/api/mobile/*` (`server/_core/mobileApi.ts`) |
| Auth | Clerk (principal; queda rastro de Manus OAuth) | — |

---

## 2. Foco actual de trabajo (contexto Grok)

### 2.0 Estado al cerrar 2026-07-17 (handoff mañana)

| Tema | Estado |
|---|---|
| **Cambiar este ejercicio** | ✅ Implementado (backend + web + Flutter + tests 5/5). **No** está en la APK aún. |
| **Tour Feo (onboarding)** | ✅ En código Flutter; sí en APK del 16/07 ~22:17 |
| **APK más reciente** | `FerFit-release.apk` / `app-release.apk` (~317 MB, 16/07 22:17) — **sin** replaceExercise |
| **Git** | Muchos cambios sin commitear en `main` (working tree sucio; un solo commit histórico `d3c1ada`) |

**Siguiente sesión — opciones naturales:**
1. Recompilar APK release para probar “Cambiar este ejercicio” + tour en dispositivo
2. Probar en web (`npm run dev`) el botón en `GeneratedTrainingPlanView`
3. Completar demos Feo faltantes (ARMS/tríceps, CORE, CARDIO_MOBILITY) — ver plan inventarios en sesión Grok `plan.md` / `docs/FEO_EXERCISE_INVENTORY.md`
4. Otra feature roadmap: Chain of Thought multi-paso en generación de planes; cerrar economía tienda Feo; ligas

**Convenciones que no re-discutir:** mascota = **Feo**; notifs engagement automáticas (sin horarios user); Flutter solo REST mobile; textos UI en español.

### 2.1 Histórico reciente (contexto)

En sesiones recientes se trabajó sobre la **APK Flutter**, en particular:

1. **Animaciones de Feo** (mascota)
2. **Sistema de notificaciones / engagement** (estilo Duolingo, horarios del sistema)

### 2.1 Animaciones — mascota Feo

| Pieza | Archivo | Notas |
|---|---|---|
| Widget mascota + moods + anims | `ferfit_flutter/lib/widgets/ferfit_mascot.dart` | Moods: happy, missYou, streak, goal, idle. Anims: float, wave, sad, pulse, celebrate, none |
| Celebraciones al completar | `ferfit_flutter/lib/widgets/feo_celebration.dart` | series (toast), exercise/day (overlay scale+fade) |
| Banner de engagement | `ferfit_flutter/lib/widgets/engagement_banner.dart` | Alertas in-app con Feo |
| Assets | `ferfit_flutter/assets/mascot/` | `mascot_happy`, `miss_you`, `streak`, `goal`, `idle`, `ferfit_mascot` |

Nombre oficial de la mascota: **Feo** (`kMascotName`).

### 2.2 Notificaciones + engagement

| Pieza | Archivo | Notas |
|---|---|---|
| Notificaciones locales | `ferfit_flutter/lib/services/notification_service.dart` | `flutter_local_notifications` + `timezone`. Canal Android: `ferfit_engagement` (“FerFit Motivación”). Icono/bitmap de Feo. |
| Motor de avisos | `ferfit_flutter/lib/services/engagement_service.dart` | **El usuario no elige horarios.** Sistema fija ventanas (ej. 10:30, 18:00, 20:30). Cadena de inactividad + nudges de entrenamiento. Welcome-back si vuelve tras ≥1 día. |
| Backend engagement | `server/_core/engagement.ts` (+ tests) | Alertas que consume la app vía API móvil |
| Deps | `ferfit_flutter/pubspec.yaml` | `flutter_local_notifications`, `timezone` (y build con `flutter_timezone` en el tree) |

Flujo típico al abrir la app:

1. `EngagementService.onAppOpened` → detecta “días ausente”
2. Cancela notifs viejas y reprograma cadena de inactividad
3. Pide alertas al backend y programa nudges de entrenamiento

### 2.3 Dónde están las APKs

| Ubicación | Tamaño aprox. | Fecha (FS) | Notas |
|---|---|---|---|
| `C:\Ferfit 2\app-release.apk` | ~51 MB | 2026-07-04 23:49 | Copia en raíz del monorepo (deuda: no versionar) |
| `dist/FerFit_release.apk` | ~52 MB | 2026-07-04 21:08 | Otra copia en dist |
| `ferfit_flutter/build/app/outputs/apk/release/app-release.apk` | ~52 MB | 2026-07-05 15:37 | **Build Flutter release reciente** |
| `ferfit_flutter/build/app/outputs/flutter-apk/app-release.apk` | ~52 MB | 2026-07-05 15:37 | Espejo flutter-apk |
| Builds viejos `app-FerFit.apk` / `app-Ferfit2.apk` | ~53 MB | 2026-07-01 | Históricos |

**Build release típico:**

```bash
cd ferfit_flutter
flutter build apk --release
```

Salida esperada: `ferfit_flutter/build/app/outputs/flutter-apk/app-release.apk`

---

## 3. Mapa rápido del monorepo

```
client/            Web React
server/            Express + tRPC + IA + mobile API
  _core/           env, LLM, catalog RAG, mobileApi, engagement, clerk path, etc.
shared/            tipos compartidos
drizzle/           schema + migraciones MySQL
ferfit_flutter/    app Android/iOS
docs/              arquitectura (01–10)
mockups/           assets de diseño
```

Features clave backend:

- Generación de plan: `generatePersonalizedPlanWithNutrition` en `server/routers.ts`
- Catálogo cerrado RAG: `server/_core/catalog.ts` (anti-alucinación de ejercicios)
- Structured Outputs (JSON Schema) para respuesta del LLM
- Checklist / XP / rachas en `markSeriesComplete` y progreso en `db.ts`
- **Inconsistencia conocida:** dos algoritmos de racha distintos (`db.ts` vs `routers.ts`) — ver `docs/07_TECHNICAL_DEBT.md`

---

## 4. Decisiones y convenciones (para no re-discutir)

- **Mascota = Feo** (no renombrar en UI sin acuerdo).
- Notificaciones de engagement: **automáticas**, no settings de horario del usuario.
- Flutter no usa tRPC; solo REST `/api/mobile/*`.
- Web es la superficie más completa; Flutter es cliente nativo espejo parcial.
- No commitear APKs (`*.apk` debería ir a `.gitignore` / releases).
- Auth objetivo: Clerk; path Manus es legado.

---

## 5. Pendientes / deuda relevante

- [ ] Unificar cálculo de rachas (doble implementación).
- [ ] Sacar APKs del working tree; artefactos en releases.
- [ ] Limpiar integraciones Manus sin uso (mapas, voice, image gen en server).
- [ ] JWT Clerk: verificar firma (hoy hay path que decodifica sin verificar — deuda de seguridad).
- [ ] Regenerar / publicar APK con animaciones + notifs validadas en dispositivo real.
- [ ] Cadena de pensamiento multi-paso en el LLM (roadmap, no hecho).
- [ ] “Cambiar este ejercicio” granular (roadmap, no hecho).

Detalle: `docs/07_TECHNICAL_DEBT.md`, `docs/10_ROADMAP.md`.

---

## 6. Cómo usar esta bitácora en Grok

**Al inicio de sesión:**

```
Lee grokbitacora.md y retoma el foco actual (Flutter: animaciones Feo + notificaciones).
```

**Al cerrar trabajo útil:**

```
Actualizá grokbitacora.md: agregá una entrada en §7 con fecha, cambios, archivos y path de APK si se generó.
```

**Memory Grok (opcional):** en TUI, con `[memory] enabled = true` en `~/.grok/config.toml`:

- `/flush` al terminar una sesión productiva  
- `/remember …` para hechos cortos (ej. “APK release en ferfit_flutter/build/...”)

---

## 7. Registro cronológico de sesiones

### 2026-07-04 — APK en raíz y docs de arquitectura

- Existe `app-release.apk` en la raíz del monorepo (~51 MB).
- Documentación formal en `docs/01`–`10` y bitácora de producto en `BITACORA.md`.
- Mejoras previas en wizard (tags lesiones/preferencias), catalog RAG y structured outputs (ver BITACORA).

### 2026-07-05 — Build Flutter release

- APK release más reciente del tree Flutter:  
  `ferfit_flutter/build/app/outputs/apk/release/app-release.apk` (~51.7 MB).

### 2026-07-08 — Sesión hy3 (web: gráficos + CORS)

- Bitácora detallada: `hy3bitacotra.md` / `hy3.md`.
- Gráficos de progreso conectados a `exercise_history` real.
- Fix CORS: `allowedOrigins` debía incluir `http://localhost:3000`.

### 2026-07-08 — Sesión actual (Grok memory + esta bitácora)

- Usuario preguntó por ubicación de APK y memoria entre sesiones.
- Memory experimental habilitada en `~/.grok/config.toml` (`[memory] enabled = true`).
- Contexto recuperado del usuario: trabajo en **animaciones Flutter** + **sistema de notificaciones** para la APK.
- Creación de este archivo (originalmente `grok.md`, renombrado a `grokbitacora.md`) como bitácora canónica de sesiones Grok.

### 2026-07-08 — APK release recompilada (animaciones + notifs)

- `flutter build apk --release` en `ferfit_flutter/` → **OK** (~55.3 MB).
- Salida Gradle/Flutter:  
  `ferfit_flutter/build/app/outputs/flutter-apk/app-release.apk`
- Copias fáciles de bajar en la raíz del monorepo:  
  - `C:\Ferfit 2\FerFit-release.apk`  
  - `C:\Ferfit 2\app-release.apk` (actualizada)

### 2026-07-08 — Fix GIFs + MVP demos Feo (5 ejercicios)

**Causa de GIFs rotos:**
1. `getExerciseMediaUrl` prefería `/exercises/*.png` locales que **no existen** (solo README en `client/public/exercises/`) → se guardaba `gifUrl` roto en el plan.
2. Mobile API `/exercise-media` devolvía `url: media` (objeto) en vez de `url: media.url` (string) → Flutter no podía cargar con `Image.network`.
3. Flutter no usaba `ex.gifUrl` del plan; solo pedía media al expandir.

**Fixes:** `musclewiki.ts` (solo URLs http/https), `mobileApi.ts`, `routers.ts` (re-enrich + limpia paths muertos), web `ExerciseCard`/`ExerciseChecklist`, Flutter `workout_tab`.

**MVP Feo (no 3D, animación 2D del asset de mascota) — 15 ejercicios:**
1–5: Push-up, Bodyweight Squat, Plank, Pull-up, Dumbbell Curl  
6–15: Lunges, Burpee, Mountain Climber, Bench Press, Deadlift, Overhead Press, Lateral Raise, Triceps Dip, Crunch, Jumping Jack  

Archivos: `feo_exercise_catalog.dart`, `feo_exercise_demo.dart`, `server/_core/feoExerciseDemos.ts`.
En la tarjeta expandida: demo animada de Feo + referencia remota (GIF/imagen real).

### 2026-07-08 — APK con 15 demos Feo

- `flutter build apk --release` → OK (~55.4 MB)
- Descargar: `C:\Ferfit 2\FerFit-release.apk` (también `app-release.apk`)

### 2026-07-08 — Demos IA de Feo (poses + videos)

Generadas con image_edit (ref mascot_happy) + image_to_video:

**15 poses JPG** en `ferfit_flutter/assets/feo_demos/`:
push_up, squat, plank, pull_up, dumbbell_curl, lunge, burpee, mountain_climber, bench_press, deadlift, overhead_press, lateral_raise, triceps_dip, crunch, jumping_jack

**Videos MP4** (rate limit impidió los 15): push_up, squat, plank, dumbbell_curl

UI: `FeoExerciseDemo` usa `video_player` si hay MP4; si no, muestra la pose JPG.
La card expandida prioriza demo Feo generada sobre la animación procedural.

### 2026-07-08 — CHEST completo (14/14 demos Feo)

Una pose JPG por cada ejercicio del catálogo CHEST en `assets/feo_demos/`.
Match 1:1 en `feo_exercise_catalog.dart` (más específico primero).
Inventario: `docs/FEO_EXERCISE_INVENTORY.md` actualizado.

### 2026-07-08 — CHEST videos 14/14

Animados todos los ejercicios de pecho (image_to_video 6s loop).
Antes solo había `push_up.mp4` de pecho; ahora cada uno tiene `.jpg` + `.mp4`.

### 2026-07-09 — Fix dashboard + nutrición + APK

**Dashboard:** carga resiliente (Future.wait + catch), parse seguro de XP/series (evita crash con tipos String de MySQL), timeouts HTTP.
**Nutrición:** Flutter usaba wizard de *entrenamiento* y buscaba `nutrition` solo en training plan. Ahora:
- API mobile `GET /nutrition/active` + `POST /nutrition/create`
- `NutritionWizardDialog` dedicado
- fallback a nutrition del plan de entrenamiento
**APK:** recompilada con videos CHEST + fixes.

### 2026-07-09 — BACK completo 15/15 (jpg + mp4)

Todos los ejercicios BACK del catálogo con pose + video Feo en `assets/feo_demos/`.
Match 1:1 en `feo_exercise_catalog.dart`. Inventario actualizado.

### 2026-07-09 — LEGS 20/20 + SHOULDERS 14/14 (Feo)

- Completado `standing_calf_raise.mp4` (faltaba).
- LEGS: 20 jpg+mp4 con ref `mascot_happy`.
- SHOULDERS: 14 jpg+mp4 (press, laterales, front, reverse pec, face pull, rear delt, upright, shrugs).
- Catálogo Flutter e inventario actualizados.
- Pendientes: ARMS, CORE, CARDIO_MOBILITY.

### 2026-07-16 — Tour Feo (onboarding) + APK release

**Onboarding primera sesión (estilo Duolingo, textos ES):**
- `ferfit_flutter/lib/onboarding/coach_tour_keys.dart` — GlobalKeys de UI
- `ferfit_flutter/lib/onboarding/coach_tour_steps.dart` — pasos del tour
- `ferfit_flutter/lib/widgets/feo_coach_tour.dart` — overlay Feo señalando
- `ferfit_flutter/lib/services/onboarding_service.dart` — flag `feo_coach_tour_v1_done` en SharedPreferences
- Integrado en `dashboard_screen.dart` (se muestra si no completó el tour)

**APK release (incluye tour + demos Feo + misiones/form-check del tree actual):**
- Build OK: `ferfit_flutter/build/app/outputs/flutter-apk/app-release.apk` (~316.8 MB)
- Copias: `C:\Ferfit 2\FerFit-release.apk`, `C:\Ferfit 2\app-release.apk`
- Warning no bloqueante: plugins ML Kit / home_widget usan KGP legacy

**Foco próximo (de sesión previa + inventario):**
- Completar demos Feo faltantes: ARMS (tríceps), CORE, CARDIO_MOBILITY
- Probar tour en dispositivo real (reset: borrar app o `OnboardingService.resetTour`)

### 2026-07-17 — Feature: Cambiar este ejercicio + push + VPS

**Sesión:** resume → APK tour Feo → feature “Cambiar este ejercicio” → commit/push a `origin/main`.

| Pieza | Path |
|---|---|
| Helpers catálogo | `server/_core/catalog.ts` |
| Lógica | `server/_core/replaceExercise.ts` |
| tRPC | `training.replaceExercise`, `training.listExerciseReplacements` |
| Mobile | `GET/POST .../training/replace-options` y `replace-exercise` |
| Web | `GeneratedTrainingPlanView.tsx` |
| Flutter | `workout_tab.dart` + `api_service.dart` |
| Tests | `replaceExercise.test.ts` (5/5) |

**Comportamiento:** mismo grupo catálogo RAG; conserva sets/reps; resetea series del ejercicio; GIF best-effort; persiste `generatedContent`.

**APK:** `FerFit-release.apk` del 16/07 tiene tour Feo; **no** incluye replaceExercise hasta rebuild.

**VPS conocido en app:** `168.181.187.209:3000` (ver `api_service.dart` baseUrl). Deploy checklist: pull → npm i → .env prod → migrate → build → pm2 + nginx.

---

## 8. Comandos útiles

```bash
# Backend / web (desde raíz monorepo)
npm run dev          # o el script que use el package.json
npm run check        # typecheck

# Flutter
cd ferfit_flutter
flutter pub get
flutter run
flutter build apk --release
```

---

*Fin de la bitácora. Las nuevas entradas van en la sección 7, más recientes abajo.*
