# 05 · Arquitectura

> Última actualización: 2026-07-04

## 1. Vista general de componentes

```mermaid
flowchart TB
    subgraph Clients["Clientes"]
        Web["Cliente Web\nReact 19 + Vite"]
        Mobile["App Flutter\n(ferfit_flutter)"]
    end

    subgraph Server["Backend (server/)"]
        Express["Express 4"]
        TRPC["Router tRPC\n(routers.ts)"]
        MobileAPI["Router REST\n(_core/mobileApi.ts)"]
        Ctx["Auth Context\n(_core/context.ts)"]
        Core["_core/*\n(llm, catalog, musclewiki,\ntranslations, injuryFilter*)"]
        DBLayer["db.ts\n(acceso a datos)"]
    end

    subgraph External["Servicios externos"]
        Clerk["Clerk\n(Auth)"]
        LLMSvc["LLM\n(proxy Forge / invokeLLM)"]
        ExDB["ExerciseDB\n(RapidAPI)"]
        MySQL[("MySQL / TiDB")]
    end

    Web -- "tRPC batch\n/api/trpc" --> Express
    Mobile -- "REST JSON\n/api/mobile" --> Express
    Express --> TRPC
    Express --> MobileAPI
    MobileAPI -- "createCaller()" --> TRPC
    TRPC --> Ctx
    Ctx --> Clerk
    TRPC --> Core
    Core --> LLMSvc
    Core --> ExDB
    TRPC --> DBLayer
    DBLayer --> MySQL
```

`injuryFilter.ts` se marca con `*` porque existe en el código pero no está conectado a ningún flujo (ver [07_TECHNICAL_DEBT.md](07_TECHNICAL_DEBT.md)).

## 2. Flujo Front → Backend

```mermaid
sequenceDiagram
    participant UI as Componente React
    participant RQ as React Query + tRPC client
    participant Ex as Express
    participant Ctx as createContext()
    participant Proc as tRPC procedure

    UI->>RQ: trpc.training.X.useQuery()/mutate()
    RQ->>Ex: POST/GET /api/trpc/training.X (superjson)
    Ex->>Ctx: crea contexto por request
    Ctx->>Ctx: 1) intenta auth Manus SDK
    Ctx->>Ctx: 2) fallback: decodifica JWT Clerk (sin verificar firma) + upsert user
    Ctx-->>Ex: { user }
    Ex->>Proc: ejecuta procedure con ctx
    Proc-->>Ex: resultado (o TRPCError)
    Ex-->>RQ: JSON (superjson)
    RQ-->>UI: data / error (cacheado)
```

## 3. Flujo Backend → Base de datos

```mermaid
flowchart LR
    Proc["tRPC procedure\n(routers.ts)"] --> DBFn["Función en db.ts"]
    DBFn --> Pool["mysql2 Pool\n(getDb(), singleton lazy)"]
    Pool --> Drizzle["Drizzle ORM\n(query builder)"]
    Drizzle --> MySQL[("MySQL / TiDB")]
    Pool -. "primera llamada" .-> Seed["seedAchievements()\n(async, no bloqueante)"]
```

Puntos clave:
- El pool se crea de forma perezosa en el primer `getDb()`; si `DATABASE_URL` no está seteado, todas las funciones de `db.ts` devuelven `null`/`[]` en vez de lanzar (fallos silenciosos por diseño).
- No hay capa de migraciones ejecutada automáticamente al boot — se corre manualmente vía `pnpm db:push` (`drizzle-kit generate && drizzle-kit migrate`).
- El contenido del plan generado por IA se guarda como JSON en una columna `text` (`training_plans.generatedContent`), no normalizado — ver detalle en [03_BACKEND.md](03_BACKEND.md#7-base-de-datos-drizzle--mysql).

## 4. Flujo Backend → APIs externas (ExerciseDB / Clerk)

```mermaid
flowchart LR
    Proc["training.searchExercise\ntraining.searchExerciseWithMedia"] --> DataApi["_core/dataApi.ts\ncallDataApi()"]
    DataApi --> Forge["Proxy Forge\n(BUILT_IN_FORGE_API_URL)"]
    Forge --> ExDB1["ExerciseDB\n(vía catálogo de APIs del proxy)"]

    Enrich["generatePersonalizedPlanWithNutrition\ngetActivePlan (enrich on read)"] --> MW["_core/musclewiki.ts"]
    MW --> ExDB2["exercisedb.p.rapidapi.com"]
    MW --> ExDB3["exercise-db-fitness-workout-gym.p.rapidapi.com"]

    MobileAPI["_core/mobileApi.ts"] --> ClerkFAPI["Clerk Frontend API\n(free-quetzal-72.clerk.accounts.dev)"]
    MobileAPI --> ClerkAPI["Clerk Backend API\n(api.clerk.com)"]
```

Nota: existen **dos caminos distintos** hacia datos de ejercicios (`dataApi.ts` vía proxy Forge, y `musclewiki.ts` vía RapidAPI directo) que no comparten cache ni lógica — ver Technical Debt.

## 5. Flujo Backend → IA (generación de planes)

```mermaid
flowchart TD
    Input["Input del wizard\n(objetivo, nivel, físico, equipo,\nlesiones, preferencias)"] --> Calc["Cálculos determinísticos\nTDEE (Mifflin-St Jeor) + Macros"]
    Calc --> Prompt["Construcción de prompt\n+ reglas de negocio\n+ catálogo RAG (catalog.ts)"]
    Prompt --> LLMCall["invokeLLM()\ncon JSON Schema estricto"]
    LLMCall -->|OK| Parse["JSON.parse(content)"]
    LLMCall -->|"error / sin API key"| Fallback["generateBasicPlan()\n(plantilla 100% determinística)"]
    Parse --> Validate["validateGeneratedPlan()\nsustituye ejercicios por\nequipo/lesión"]
    Validate --> Enrich["Enriquecimiento\nGIF (musclewiki.ts) +\ntraducción (translations.ts)"]
    Fallback --> Persist
    Enrich --> Persist["db.createTrainingPlan()\n(desactiva plan previo)"]
    Persist --> Return["Devuelto al cliente"]
```

## 6. Flujo Backend → Scrapers

No existen scrapers en este proyecto. La obtención de datos de ejercicios (GIFs, instrucciones, músculos) es **100% vía API HTTP de terceros** (ExerciseDB en RapidAPI), no scraping de HTML. Se documenta esta ausencia explícitamente porque la plantilla de este documento la contemplaba.

## 7. Despliegue / Build

```mermaid
flowchart LR
    Dev["pnpm dev\n(tsx watch + Vite middleware)"] -.-> Local["localhost:3000"]
    Build["pnpm build"] --> ViteBuild["vite build\n→ dist/public (estáticos)"]
    Build --> EsbuildBundle["esbuild server/_core/index.ts\n→ dist/index.js (ESM bundle)"]
    ViteBuild --> Prod["pnpm start\n(NODE_ENV=production node dist/index.js)"]
    EsbuildBundle --> Prod
    Prod -.-> Vercel["Deploy target: Vercel\n(según historial de commits)"]
```
