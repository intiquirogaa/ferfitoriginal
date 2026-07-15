# Inventario de ejercicios × demos de Feo

> **Fuente del catálogo (lo que usa la IA / API de planes):** `server/_core/catalog.ts` (`EXERCISE_CATALOG`)  
> **No** es el dump completo de ExerciseDB RapidAPI (miles de nombres). Es la lista **cerrada** de ejercicios permitidos en FerFit.  
> **Demos Feo:** `ferfit_flutter/assets/feo_demos/`  
> **Lookup en app:** `ferfit_flutter/lib/services/feo_exercise_catalog.dart`  
> **Última actualización:** 2026-07-08

---

## Resumen

| Métrica | Cantidad |
|--------|----------|
| **Total ejercicios en catálogo** | **99** |
| Con demo Feo **directa** (asset propio o dedicado) | **15** (pose JPG) |
| Con **video** MP4 además de pose | **4** |
| Cubiertos por **patrón compartido** (misma demo de familia) | ver por grupo |
| **Sin demo Feo** (faltan) | ver lista “FALTAN” |

### Assets de Feo existentes

| ID demo | Pose JPG | Video MP4 |
|---------|----------|-----------|
| `push_up` | ✅ | ✅ |
| `squat` | ✅ | ✅ |
| `plank` | ✅ | ✅ |
| `dumbbell_curl` | ✅ | ✅ |
| `pull_up` | ✅ | ❌ |
| `lunge` | ✅ | ❌ |
| `burpee` | ✅ | ❌ |
| `mountain_climber` | ✅ | ❌ |
| `bench_press` | ✅ | ❌ |
| `deadlift` | ✅ | ❌ |
| `overhead_press` | ✅ | ❌ |
| `lateral_raise` | ✅ | ❌ |
| `triceps_dip` | ✅ | ❌ |
| `crunch` | ✅ | ❌ |
| `jumping_jack` | ✅ | ❌ |

**Leyenda de estado en tablas**

| Estado | Significado |
|--------|-------------|
| ✅ **Propio** | Tiene asset/demo mapeada de forma principal |
| 🟡 **Familia** | Usa la demo de un ejercicio “padre” (mismo patrón de movimiento) |
| ❌ **Falta** | No hay demo Feo (ni propia ni por familia en el código actual) |

---

## CHEST (14) — ✅ COMPLETO (1 demo por ejercicio, 2026-07-08)

| # | Ejercicio (catálogo) | Demo Feo | Asset |
|---|----------------------|----------|-------|
| 1 | Bench Press | ✅ Propio | `bench_press.jpg` |
| 2 | Incline Bench Press | ✅ Propio | `incline_bench_press.jpg` |
| 3 | Decline Bench Press | ✅ Propio | `decline_bench_press.jpg` |
| 4 | Dumbbell Bench Press | ✅ Propio | `dumbbell_bench_press.jpg` |
| 5 | Incline Dumbbell Press | ✅ Propio | `incline_dumbbell_press.jpg` |
| 6 | Decline Dumbbell Press | ✅ Propio | `decline_dumbbell_press.jpg` |
| 7 | Dumbbell Flyes | ✅ Propio | `dumbbell_flyes.jpg` |
| 8 | Cable Crossover | ✅ Propio | `cable_crossover.jpg` |
| 9 | Pec Deck Fly | ✅ Propio | `pec_deck_fly.jpg` |
| 10 | Push-up | ✅ Propio + video | `push_up.jpg` / `.mp4` |
| 11 | Decline Push-up | ✅ Propio | `decline_push_up.jpg` |
| 12 | Incline Push-up | ✅ Propio | `incline_push_up.jpg` |
| 13 | Diamond Push-up | ✅ Propio | `diamond_push_up.jpg` |
| 14 | Machine Chest Press | ✅ Propio | `machine_chest_press.jpg` |

**Nota:** Poses + **videos MP4 14/14** (2026-07-08). En la card se reproduce en loop con `video_player`.

---

## BACK (15) — ✅ COMPLETO jpg+mp4 (2026-07-09)

| # | Ejercicio | Demo Feo | Asset |
|---|-----------|----------|-------|
| 1 | Pull-up | ✅ + video | `pull_up` |
| 2 | Chin-up | ✅ + video | `chin_up` |
| 3 | Lat Pulldown | ✅ + video | `lat_pulldown` |
| 4 | Straight Arm Pulldown | ✅ + video | `straight_arm_pulldown` |
| 5 | Barbell Row | ✅ + video | `barbell_row` |
| 6 | Dumbbell Row | ✅ + video | `dumbbell_row` |
| 7 | Pendlay Row | ✅ + video | `pendlay_row` |
| 8 | T-Bar Row | ✅ + video | `t_bar_row` |
| 9 | Seated Cable Row | ✅ + video | `seated_cable_row` |
| 10 | Chest Supported Row | ✅ + video | `chest_supported_row` |
| 11 | Deadlift | ✅ + video | `deadlift` |
| 12 | Rack Pull | ✅ + video | `rack_pull` |
| 13 | Good Morning | ✅ + video | `good_morning` |
| 14 | Superman | ✅ + video | `superman` |
| 15 | Inverted Row | ✅ + video | `inverted_row` |

---

## LEGS (20)

| # | Ejercicio | Demo Feo | Asset / nota |
|---|-----------|----------|--------------|
| 1 | Barbell Squat | 🟡 Familia | → `squat` |
| 2 | Front Squat | 🟡 Familia | → `squat` |
| 3 | Goblet Squat | 🟡 Familia | → `squat` |
| 4 | Bodyweight Squat | ✅ Propio / familia | → `squat` + video |
| 5 | Leg Press | ❌ Falta | |
| 6 | Hack Squat | ❌ Falta | (excluido a propósito del match squat genérico) |
| 7 | Bulgarian Split Squat | ❌ Falta | |
| 8 | Lunges | ✅ Propio | `lunge` |
| 9 | Walking Lunges | 🟡 Familia | → `lunge` |
| 10 | Romanian Deadlift | 🟡 Familia | → `deadlift` |
| 11 | Stiff-Legged Deadlift | 🟡 Familia | → `deadlift` |
| 12 | Leg Extension | ❌ Falta | |
| 13 | Leg Curl | ❌ Falta | |
| 14 | Seated Leg Curl | ❌ Falta | |
| 15 | Lying Leg Curl | ❌ Falta | |
| 16 | Hip Thrust | ❌ Falta | |
| 17 | Glute Bridge | ❌ Falta | |
| 18 | Calf Raise | ❌ Falta | |
| 19 | Seated Calf Raise | ❌ Falta | |
| 20 | Standing Calf Raise | ❌ Falta | |

---

## SHOULDERS (14)

| # | Ejercicio | Demo Feo | Asset / nota |
|---|-----------|----------|--------------|
| 1 | Overhead Press | ✅ Propio | `overhead_press` |
| 2 | Dumbbell Shoulder Press | 🟡 Familia | → `overhead_press` |
| 3 | Arnold Press | 🟡 Familia | → `overhead_press` |
| 4 | Lateral Raise | ✅ Propio | `lateral_raise` |
| 5 | Cable Lateral Raise | 🟡 Familia | → `lateral_raise` |
| 6 | Machine Lateral Raise | 🟡 Familia | → `lateral_raise` |
| 7 | Front Raise | ❌ Falta | |
| 8 | Dumbbell Front Raise | ❌ Falta | |
| 9 | Reverse Pec Deck | ❌ Falta | |
| 10 | Face Pull | ❌ Falta | |
| 11 | Dumbbell Rear Delt Row | ❌ Falta | |
| 12 | Upright Row | ❌ Falta | |
| 13 | Barbell Shrug | ❌ Falta | |
| 14 | Dumbbell Shrug | ❌ Falta | |

---

## ARMS (13)

| # | Ejercicio | Demo Feo | Asset / nota |
|---|-----------|----------|--------------|
| 1 | Barbell Curl | 🟡 Familia | → `dumbbell_curl` |
| 2 | Dumbbell Curl | ✅ Propio | `dumbbell_curl` + video |
| 3 | Hammer Curl | 🟡 Familia | → `dumbbell_curl` |
| 4 | Preacher Curl | 🟡 Familia | → `dumbbell_curl` |
| 5 | Cable Curl | 🟡 Familia | → `dumbbell_curl` |
| 6 | Concentration Curl | 🟡 Familia | → `dumbbell_curl` |
| 7 | Triceps Pushdown | 🟡 Familia | → `triceps_dip` (mismo patrón extensión) |
| 8 | Overhead Triceps Extension | 🟡 Familia | → `triceps_dip` |
| 9 | Skullcrusher | 🟡 Familia | → `triceps_dip` |
| 10 | Close Grip Bench Press | ❌ Falta | |
| 11 | Triceps Dip | ✅ Propio | `triceps_dip` |
| 12 | Bench Dip | 🟡 Familia | → `triceps_dip` |
| 13 | Triceps Kickback | 🟡 Familia | → `triceps_dip` |

---

## CORE (13)

| # | Ejercicio | Demo Feo | Asset / nota |
|---|-----------|----------|--------------|
| 1 | Crunch | ✅ Propio | `crunch` |
| 2 | Reverse Crunch | 🟡 Familia | → `crunch` |
| 3 | Bicycle Crunch | 🟡 Familia | → `crunch` |
| 4 | Russian Twist | ❌ Falta | |
| 5 | Plank | ✅ Propio | `plank` + video |
| 6 | Side Plank | ❌ Falta | (excluido del match plank genérico) |
| 7 | Ab Wheel Rollout | ❌ Falta | |
| 8 | Hanging Leg Raise | ❌ Falta | |
| 9 | Cable Crunch | 🟡 Familia | → `crunch` |
| 10 | Decline Crunch | 🟡 Familia | → `crunch` |
| 11 | Mountain Climber | ✅ Propio | `mountain_climber` |
| 12 | Dead Bug | ❌ Falta | |
| 13 | Bird Dog | ❌ Falta | |

---

## CARDIO_MOBILITY (10)

| # | Ejercicio | Demo Feo | Asset / nota |
|---|-----------|----------|--------------|
| 1 | Burpee | ✅ Propio | `burpee` |
| 2 | Jumping Jack | ✅ Propio | `jumping_jack` |
| 3 | High Knees | ❌ Falta | |
| 4 | Jump Rope | ❌ Falta | |
| 5 | Box Jump | ❌ Falta | |
| 6 | Kettlebell Swing | ❌ Falta | |
| 7 | Shoulder Dislocates | ❌ Falta | |
| 8 | Cat-Cow | ❌ Falta | |
| 9 | Hip Rotations | ❌ Falta | |
| 10 | Torso Twist | ❌ Falta | |

---

## Totales por cobertura (aprox. según match actual del código)

Conteo manual del estado en las tablas:

| Estado | Cantidad aprox. |
|--------|-----------------|
| ✅ Propio (demo “estrella” del grupo) | ~15 IDs de asset |
| 🟡 Familia (cubre variantes) | ~35–40 ejercicios del catálogo |
| ❌ Falta | **~45–50** ejercicios sin ninguna demo |

**Cobertura aproximada del catálogo con alguna demo (propio + familia): ~50%**  
**Sin demo: ~50%**

---

## Lista corta: solo lo que FALTA (prioridad para generar)

### Alta prioridad (frecuentes en planes / patrón distinto)

1. Dumbbell Flyes  
2. Cable Crossover / Pec Deck Fly  
3. Lat Pulldown  
4. Barbell Row / Dumbbell Row (patrón “remo”)  
5. Seated Cable Row  
6. Leg Press  
7. Bulgarian Split Squat  
8. Hip Thrust / Glute Bridge  
9. Leg Curl / Leg Extension  
10. Calf Raise  
11. Front Raise  
12. Face Pull  
13. Reverse Pec Deck / rear delt  
14. Shrugs  
15. Russian Twist  
16. Side Plank  
17. Hanging Leg Raise  
18. Dead Bug / Bird Dog  
19. High Knees  
20. Box Jump  
21. Kettlebell Swing  
22. Cat-Cow / movilidad (Shoulder Dislocates, Hip Rotations, Torso Twist)  
23. Jump Rope  
24. Close Grip Bench Press  
25. Good Morning / Superman / Rack Pull  
26. Inverted Row  
27. Ab Wheel Rollout  
28. Hack Squat  
29. Upright Row  

### Videos pendientes (ya hay pose JPG)

- pull_up, lunge, burpee, mountain_climber, bench_press, deadlift  
- overhead_press, lateral_raise, triceps_dip, crunch, jumping_jack  

(Ya tienen video: push_up, squat, plank, dumbbell_curl)

---

## Cómo usar esta lista

1. **Generar animación** = pose (JPG/PNG) + idealmente video (MP4) por **patrón** o por ejercicio.  
2. Convención de archivos: `assets/feo_demos/{snake_case}.jpg` y opcional `.mp4`.  
3. Registrar en `feo_exercise_catalog.dart` (match de nombres EN/ES).  
4. Actualizar esta tabla: ❌ → ✅ o 🟡.  
5. Recompilar APK.

---

## Nota sobre “la API”

| Origen | Qué es | Cantidad |
|--------|--------|----------|
| `EXERCISE_CATALOG` (catalog.ts) | Lista **oficial** que el LLM puede elegir | **99** |
| ExerciseDB RapidAPI | Lookup de GIF por nombre al enriquecer | Variable / externa |
| free-exercise-db (CDN) | Fallback de imágenes | Cientos (dataset abierto) |

Para FerFit, **la lista que importa para “una animación por ejercicio del producto” es el catálogo de 99**, no todo ExerciseDB.

---

## Próximo paso sugerido

Batches de generación IA (mismo estilo 3D verde):

1. **Remo** (1 demo) → cubre Barbell/Dumbbell/Pendlay/T-Bar/Cable Row  
2. **Lat Pulldown**  
3. **Hip hinge glúteos** → Hip Thrust + Glute Bridge  
4. **Leg press**  
5. **Fly / crossover**  
6. **Side plank + Russian twist + leg raise**  
7. **Cardio:** High Knees, Box Jump, KB Swing, Jump Rope  
8. **Movilidad:** Cat-Cow, etc.  
9. Completar **videos** de las 11 poses que ya existen  

Cuando generemos un batch, marcar en este archivo.
