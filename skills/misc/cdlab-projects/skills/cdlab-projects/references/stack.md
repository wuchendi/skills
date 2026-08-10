# Stack Reference

The opinionated tech stack assumed by this skill. Read this when you need to know "what should I reach for" before writing code.

## Where the real config lives

**This skill does not carry copies of the workspace config.** Versions, lint rules and TS options change upstream every few weeks; a vendored copy is stale the day after it's written. Read the real file instead:

```bash
ROOT=$(git rev-parse --show-toplevel)
# Not inside the monorepo? Get a throwaway copy:
#   git clone --depth 1 https://github.com/WuChenDi/projects /tmp/cdlab-ref && ROOT=/tmp/cdlab-ref
```

| Need                              | Read                                       |
|-----------------------------------|--------------------------------------------|
| Dep versions (both catalogs)      | `$ROOT/pnpm-workspace.yaml`                |
| Lint / format rules, per-app overrides | `$ROOT/biome.json`                    |
| Shared TS options                 | `$ROOT/packages/tsconfig/*.json`           |
| Turbo task pipeline               | `$ROOT/turbo.json`                         |
| Current `compatibility_date`      | `$ROOT/apps/dropply-api/wrangler.jsonc`    |
| What apps/packages actually exist | `ls $ROOT/apps $ROOT/packages`             |

Never quote a version number from this file or from memory — read it from `pnpm-workspace.yaml`. The sections below describe *shape and intent*, which change slowly; they deliberately contain no version numbers.

## Workspace

- **Package manager**: pnpm (pin `packageManager` in root `package.json`).
- **Monorepo**: Turborepo (`turbo.json`, concurrency 50, `ui: tui`).
- **Layout**: `apps/*` for deployables, `packages/*` for shared libraries. Both globs in `pnpm-workspace.yaml`.
- **Catalogs**: two catalogs — `prod` (runtime) and `dev` (build/test/types). Reference as `catalog:prod` / `catalog:dev` from any package.json.

## Lint / format

- **Biome only** — do not introduce ESLint or Prettier. The single `biome.json` at the root governs everything except `apps/repo-changelog/**` (excluded; Nuxt has its own ESLint).
- Per-app lint domains (Next/React, Vue) are enabled via `biome.json` `overrides` rather than per-app config files.
- The `biome` binary lives only in the root `node_modules/.bin`, so per-app `lint` scripts can't invoke it. Lint runs from the root: `pnpm lint:biome`.
- **What `files.includes` excludes**: build output (`dist`, `build`, `public`, `.next`, `.out`, `.wrangler`, `.turbo`, `.cache`), generated artefacts (`apps/<worker>/src/database/**/*.{json,sql}`, `apps/**/cloudflare-env.d.ts`), vendored sources (`packages/ui/src/{components,reactbits}/**/*.tsx`), and `apps/repo-changelog/**`. Extend it for any new generated or vendored source.

## Scripts

Every app and package follows the same script vocabulary:

- **Dev**: `nsl run <tool> dev` — never bare `next dev` / `wrangler dev` / `nuxt dev`.
- **Typecheck**: `tsc --noEmit` (Next, Workers), `nuxt typecheck` (Nuxt), `tsc --project ./tsconfig.json --noEmit` (packages).
- **Build**: exists everywhere. Deploy is a **separate, explicit** step (`turbo deploy`) — nothing auto-deploys from CI.
- **Test**: `vitest --run` where tests exist.

## TypeScript

- Shared configs in `packages/tsconfig`:
  - `base.json` — strict, NodeNext resolution
  - `nextjs.json` — Next overlay (extends base)
  - `hono.json` — Workers overlay (extends base)
  - `react-library.json`, `utils.json` — for shared packages
- Each project just `extends` one of these and adds `paths` / `types`.
- Read `base.json` before assuming a specific flag is on — `strict` is stable, but the surrounding options (`target`, `lib`, `noUncheckedIndexedAccess`, `declaration`) get revised with TS major bumps.

## Frontend frameworks

| Framework      | Apps using it                                 | Build tool                   | Deploy                                                                |
|----------------|-----------------------------------------------|------------------------------|-----------------------------------------------------------------------|
| Next.js (App Router) | most front-ends                         | `next build` (or `--webpack` when wasm/workers misbehave with Turbopack) | Cloudflare Pages via `@cloudflare/next-on-pages`, occasionally `@opennextjs/cloudflare` |
| Cloudflare Workers + Hono | API / serverless apps               | `wrangler deploy --minify`   | Workers + Durable Objects + D1                                        |
| Nuxt 4 (Vue 3) | content / dashboard apps                      | `nuxt build` / `generate`    | Vercel                                                                |

## Shared UI / utilities

- **`@cdlab/ui`** — React + Tailwind v4 component library. **No build step**; consumers import raw source via subpath exports (`@cdlab/ui/components/<name>`, `@cdlab/ui/hooks/<name>`, etc.). Adding a component just means dropping a `.tsx` into `src/components/`.
- **`@cdlab/utils`** — generic helpers (`clipboard`, `download`, `format`, `idb-store`, `logger`, `np`, `password`). Built with `tsdown`. Consumers import from `dist/index.mjs` and need a rebuild after edits (`pnpm --filter @cdlab/utils build` or `dev --watch`).
- **`@cdlab/cipher`** — XChaCha20-Poly1305 + Argon2id stream crypto. Used by encryption-heavy front-ends.
- **`@cdlab/uncrypto`** — runtime shim selecting Node `webcrypto` vs browser `crypto`. Two-file build (`crypto.node.ts`, `crypto.web.ts`) via tsdown.
- **`@cdlab/db`** — shared Drizzle DB factory (D1 / LibSQL) plus query helpers. Prefer this over hand-rolling a per-app `src/lib/db.ts` when adding a new DB-backed app.
- **`@cdlab/tsconfig`** — see above.

`utils`, `cipher` and `uncrypto` are tsdown-built: consumers read `dist/`, so an edit isn't visible until you rebuild (`pnpm --filter @cdlab/<pkg> build`, or `dev --watch` while iterating). Root `pnpm prepare` rebuilds every `packages/*` in topological order after install.

## Storage / DB

- **Drizzle** for any persistent store inside a Worker.
- **Two-dialect setup**: a single `drizzle.config.ts` factory that reads `DB_TYPE` (`libsql` for local Turso file or remote LibSQL, `d1` for Cloudflare D1). `@cdlab/db` packages this — check it before copying the factory into a new app.
- Schema in `src/database/schema.ts`; migrations land in `src/database/` (not `drizzle/`) so `wrangler d1 migrations apply` finds them.

## Auth / crypto / IDs

- **IDs**: `@cdlab/driftflake` (catalog dep) for general-purpose sortable IDs. UUID v4 for sessions.
- **Auth on Workers**: `jose` for ES256 JWT verification, mounted as middleware on `/api/*` only.
- **End-to-end encryption**: `@cdlab/cipher` — XChaCha20-Poly1305 stream cipher with an Argon2id KDF, in both password and public-key modes. `dropply-web` is the reference consumer: encryption runs in a Web Worker and the server only ever stores ciphertext.

## Dev proxy

- `@dotns/nsl` — every app is reachable at `http://<app-name>.localhost:3355` once dev is running. Don't add port-juggling logic.
- Each app's dev script is `nsl run <tool> dev` (`next dev`, `wrangler dev src/index.ts`, `nuxt dev`).

## Logging

- **Workers**: `globalThis.logger` is set in `src/global.ts`. On Cloudflare it's a thin wrapper around `console.*`; in Node test runs it's winston with daily rotation. Both expose the same `debug/info/warn/error` shape.
- **Front-end**: `@cdlab/utils/logger` for browser-side logging; otherwise `console.*` is fine.

## Observability

- Workers: `wrangler.jsonc` → `observability: { enabled: true, head_sampling_rate: 1 }`. Always on by default.
- Custom analytics: `flnk` uses Cloudflare Analytics Engine (`src/lib/analytics/`) with bot filtering.
