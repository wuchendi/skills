# New Feature Playbook

Use this when adding a feature to an existing app. The goal: the new feature feels like it was always there.

## Step 1 — Read the app's local conventions before writing anything

Each app has its own internal style. Spend 2-3 minutes with these before touching code:

- The app's `README.md` (if any)
- The relevant section of root `CLAUDE.md` (under `## Architecture`)
- 2-3 representative files near the area you're changing (one component, one route, one store)

Look for:

- **Module / layer organization** — Workers split routes into `src/routes/<group>.ts`. Next apps split UI into `src/components/<feature>/`. ByCut uses singleton-style "managers" (`src/core/managers/<thing>-manager.ts`). Match the local pattern.
- **State shape** — Zustand stores follow a per-feature convention (`<thing>-store.ts`). If you need persistent state, check whether the app uses `persist` middleware.
- **Dependencies already present** — if the app uses `@tanstack/react-query`, don't bring in a second data-fetcher. If it uses `@hono/zod-validator`, write your route validator with it, not bare zod.
- **Existing patterns for similar features** — there's almost always a precedent. Copy it.

If the app has none of this and is genuinely small, fall back to the style cheatsheet in `SKILL.md` and the shape rules in `references/stack.md`.

## Step 2 — Plan the change in one sentence each

Before editing, name out loud:

1. **What user-visible behavior changes** — one sentence.
2. **What files you'll touch** — list paths.
3. **What can break** — name the most likely regression area.

If the user gave you a 3-paragraph spec but the change is small, it's still worth narrowing it down to these three lines. If you can't, you don't understand the task yet.

## Step 3 — Write the smallest version that works

- No extra config options "in case we need them".
- No abstractions for code with one caller.
- No defensive error handling for situations that can't happen (Workers won't suddenly run in Node; client code won't suddenly run on the server).
- If you find yourself adding a flag named `enableX`, ask whether X always wants to be enabled — usually yes, kill the flag.

## Step 4 — Touch the right surfaces

### Workers (Hono)

Reference apps for the patterns below: `byplay-log` (minimal), `dropply-api` (full middleware + Drizzle + cron + email), `live-user` (Durable Object + WebSocket hibernation), `baccarat` (Durable Object + game state). For KV + Analytics Engine + cron on a Next-on-Cloudflare app, see `flnk`.

- **Route file** under `src/routes/<group>.ts`, composed via `src/routes/index.ts`. Pattern: `dropply-api/src/routes/`.
- **Validation** via `@hono/zod-validator`. Schemas next to the route, or `src/lib/validationSchemas.ts` if shared (see `dropply-api`).
- **DB**: Drizzle, filtered by `eq(table.isDeleted, 0)`. Never `db.delete()`.
- **New env var**: add to `wrangler.jsonc` `vars`, `.env.example`, and (if the app has a typed `createConfig(env)`) `src/types.ts`. `baccarat/src/types.ts` is the reference for the typed config pattern.
- **New error**: throw `HTTPException` with status; the global `onError` formats it.
- **Cron**: function under `src/cron/`, wired from `scheduled()` in `src/index.ts`. Schedule in `wrangler.jsonc` `triggers.crons`. See `dropply-api/src/cron/cleanup.ts` (and `flnk/src/lib/data/cleanup.ts` for the KV-purging variant).
- **Durable Object**: new class file under `src/durable-objects/<name>.ts`, registered in `wrangler.jsonc` `durable_objects.bindings` and `migrations`. SQLite-backed DOs use `new_sqlite_classes` migrations.
  - Game-state DO with embedded SQLite: see `baccarat/src/durable-objects/game-room.ts`.
  - WebSocket-hibernation DO: see `live-user/src/site-manager.ts` — uses `ctx.acceptWebSocket(server)` so the DO unloads when idle. **Watch out**: `webSocketClose` is called *after* the socket is already closed; never call `ws.close()` from there or it throws.
- **Per-request stateful clients** (Telegram bot, OAuth client): construct **per request**, not at module top-level. Reusing across requests breaks on Workers — see how `baccarat/src/handlers/commands.ts` constructs a fresh `Bot` in each webhook invocation.
- **KV cache keys**: keep the key builders in one module per app — `flnk/src/lib/data/cache-keys.ts` is the reference (`link:{domain}:{slug}`, `visits:{id}`, `pwfail:{ip}:{slug}`). The produced strings address live KV entries, so they must stay byte-identical; inlining a key at a call site is how stale data leaks. Invalidate every key for a record in the same operation, and treat a key-format change as a coordinated migration, not an edit.

### Next.js

Reference apps: `dropply-web` (i18n, layout pattern, Web-Worker crypto), `flox` (single-locale, complex search), `bycut` (manager-based architecture), `clearify` (multi-mode toolbox with `--webpack` build).

- **Page route**: `app/[locale]/<route>/page.tsx` (with i18n) or `app/<route>/page.tsx` (without). Optional `loading.tsx` / `error.tsx` siblings.
- **Server route handler**: `app/api/<name>/route.ts`. For SSE-style fan-out, see `flox/src/app/api/search-parallel/route.ts` — it streams JSON SSE chunks with `type: 'start' | 'result' | 'error' | 'done'`.
- **Client UI**: `src/components/<feature>/<Name>.tsx`. Group by feature. `'use client'` only on components that actually need it.
- **State**: Zustand store in `src/stores/<feature>-store.ts`, with `persist` middleware when state should survive reloads. `flox/src/lib/store/` has many examples (`favorites-store`, `history-store`, `search-history-store`, `settings-store`).
- **Data fetch**: TanStack Query if the app already uses it (`text2img`, `dropply-web`); otherwise Server Components / `fetch` in route handlers.
- **Strings (i18n apps)**: every user-visible string keyed in **both** `messages/en.json` and `messages/zh.json`. `useTranslations()` in client components, `getTranslations()` in server.
- **Heavy compute / wasm / models**: in a Web Worker, not the main thread. See `bycut/src/services/transcription/worker.ts` (Hugging Face Transformers), `dropply-web/src/workers/cryptoWorker.ts` (cipher streaming).
- **Manager-based subsystems** (only if the app is editor-shaped like `bycut`): `src/core/managers/<thing>-manager.ts`, plus a `commands.ts` undo/redo bus. Don't reach for this pattern in a regular CRUD app.

### Nuxt

- Page: `app/pages/<route>.vue`. Route is automatic.
- Component: `app/components/<Name>.vue`.
- Composable: `app/composables/use<Thing>.ts`.
- Server data: `shared/types/` for shared types; `runtimeConfig` for env wiring.

## Step 5 — Verify

```bash
pnpm --filter @cdlab/<app> typecheck
pnpm --filter @cdlab/<app> lint
pnpm --filter @cdlab/<app> dev      # boot once, exercise the new path
```

For Workers, also `pnpm --filter @cdlab/<app> build` to catch issues that `wrangler dev` doesn't surface (e.g. unused exports the bundler complains about).

If the app has tests for the area you touched, run them. If it doesn't and the feature has non-trivial logic, **add a test** — even a single one — at the boundary you most worry about. (Test infrastructure: vitest + happy-dom for browser-side, vitest in Node for Workers logic.)

## Step 6 — Smoke test the actual feature

Don't claim done after typecheck. Manually exercise the golden path:

- Workers: `curl` the new endpoint with realistic payloads. Hit one error path too.
- Next: load the page in the browser, click through the new control, watch the DevTools console for warnings.
- Nuxt: same as Next.

If the feature has a regression risk on adjacent UI (e.g. you added a route that the navbar links to), check that the navbar still works.

## Step 7 — Commit

Conventional Commits. The scope is the affected app or sub-area.

```
feat(<app>): <short imperative>
```

Body (if needed) explains *why* and any trade-off the reviewer should know. Don't restate the diff.

If the feature touches multiple unrelated areas of the app, split into multiple commits.

## Common pitfalls

- Hardcoding strings in an i18n app — keys must exist in **both** `en.json` and `zh.json`.
- Adding a database column without `pnpm --filter <worker> db:gen` — the generated migration file is the source of truth, not the schema TS edit.
- Sending a key, passphrase or plaintext to the server in `dropply-*` — everything is encrypted client-side with `@cdlab/cipher` and the API only ever holds ciphertext (even the share password is Argon2id-hashed in the browser first, see `dropply-web/src/lib/api.ts`). Re-read `dropply-web/src/workers/cryptoWorker.ts` and `packages/cipher/src/password.ts` before touching crypto.
- Reusing a stateful client (Telegram bot, WebSocket) across requests on a Worker — construct per-request. See `baccarat/src/handlers/commands.ts`.
