---
name: cdlab-projects
description: Personal maintenance skill for the cdlab projects-monorepo (https://github.com/WuChenDi/projects). Trigger when working in that repo — or a new repo that clones its style — and the user wants to scaffold a new app/package (Next.js / Cloudflare Workers + Hono / Nuxt 4), bump pnpm catalog or wrangler compatibility_date, sink shared logic into packages/, add a feature to an existing app, self-review before commit/PR, or sync CLAUDE.md / README. Skip for one-off scripts or unrelated codebases.
metadata:
  author: wudi
  version: "2026.08.10"
  source: https://github.com/WuChenDi/skills
---

# cdlab-projects

Maintenance skill for the cdlab projects-monorepo. Anchored to the real apps in the repo — `baccarat`, `byplay-log`, `dropply-api/web`, `flnk`, `flox`, `wepush`, etc. — so guidance points at concrete reference implementations instead of inventing abstract patterns.

**Reference impls named here can be renamed or retired upstream.** Before citing one, confirm it still exists (`ls $ROOT/apps`). If it's gone, find the closest current equivalent rather than describing the dead one.

This file is the **router and style cheatsheet**. Detailed steps live in `references/*.md`, templates in `assets/`. Read those *only when the relevant intent fires*.

## Step 1 — Identify intent and route

Match the user's request to one of the intents below. If two apply (e.g. "new app plus a dep bump"), handle the primary one first and offer the second as a follow-up. If none cleanly applies, fall back to general engineering help under the conventions in §Style cheatsheet.

| Intent                                         | Reference                          | Templates                              |
|------------------------------------------------|------------------------------------|----------------------------------------|
| Scaffold a new app                             | `references/new-app.md`            | `assets/templates/{nextjs-app,worker-app,nuxt-app}` |
| Scaffold a shared package (`packages/*`)       | `references/new-package.md`        | `assets/templates/package`             |
| Bump dependencies (catalog, wrangler compat)   | `references/deps-upgrade.md`       | —                                      |
| Refactor / share logic across apps             | `references/refactor.md`           | —                                      |
| Add a feature to an existing app               | `references/new-feature.md`        | —                                      |
| Pre-commit / pre-PR self-review                | `references/code-review.md`        | —                                      |
| Sync `CLAUDE.md` / README after a change       | `references/update-docs.md`        | —                                      |
| "What should I reach for / where does this config live" | `references/stack.md`     | —                                      |

Before reading a reference, confirm intent with the user in **one short sentence** (e.g. "Spinning up `foo-api` from the worker template, right?"). Don't ask if the request is unambiguous.

## Step 2 — Detect the workspace root

Most playbooks need to know the workspace root. Detect once at the start:

```bash
# from any depth, walk up for pnpm-workspace.yaml or root package.json
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
```

Then read these (only when relevant), without echoing them back:
- `pnpm-workspace.yaml` — catalogs (use `catalog:prod` / `catalog:dev` for any new dep already there)
- root `package.json` — scripts and packageManager pin
- `biome.json` — lint domain overrides; new apps usually need an entry under `overrides`
- `turbo.json` — task pipeline
- `CLAUDE.md` if present — defer to its specifics on top of this skill's defaults

**This skill ships no copies of those files, by design.** Versions, lint rules and TS options are read from the workspace at use time — never quoted from this skill or from memory. `references/stack.md` has the full "which file answers which question" table, including how to get a copy when you're not inside the monorepo.

## Step 3 — Style cheatsheet (always-on)

These rules apply to **every** edit unless the project's `CLAUDE.md` says otherwise. They mirror the cdlab projects baseline.

### Code

- **Biome**, not ESLint/Prettier. Single quotes. No semicolons. 2-space indent. `organizeImports: on`.
- `import type { X } from 'pkg'` — separated; never `import { type X }`.
- `import * as z from 'zod'` — `import { z }` will fail lint.
- Every async call must be awaited or explicitly handled (`noFloatingPromises`, `noMisusedPromises` are errors).
- Use `// @ts-expect-error` (with a reason), never `// @ts-ignore`.
- `Date.now()`, never `new Date().getTime()`.
- No `delete obj.prop` — assign `undefined` or restructure.
- `noUnusedImports` and `noImplicitAnyLet` are warnings — fix them rather than silencing them.

### Dependencies

- Versions live in **`pnpm-workspace.yaml` catalogs** (`prod` for runtime, `dev` for tooling). Reference as `"react": "catalog:prod"`.
- Only put a literal version in a package's `package.json` when the dep isn't in the catalog — and consider whether it should be added to the catalog instead.
- Cross-package imports use `"@cdlab/<name>": "workspace:*"`.
- **Never** install a dep with a different version than the catalog already has — bump the catalog instead.

### Naming & metadata

- Workspace package name pattern: `@cdlab/<kebab-name>`.
- Every `package.json` has `author: "wudi <wuchendi96@gmail.com>"`, `license: MIT`, `homepage: https://github.com/WuChenDi`, `repository.url: https://github.com/WuChenDi/projects.git`, and `repository.directory: <apps|packages>/<name>`.
- Apps and packages set `"type": "module"` and `"private": true`.

### Dev workflow

- Dev URL is **always** `http://<app-name>.localhost:3355` via `@dotns/nsl`. Don't add port discovery code.
- Each app's `dev` script is `nsl run <build-tool> dev` (e.g. `nsl run next dev`, `nsl run wrangler dev`, `nsl run nuxt dev`).

### i18n (when an app uses next-intl)

- `messages/{en,zh}.json` — keep both files in sync; every user-visible string has a key in both.
- The generated `messages/en.d.json.ts` is gitignored and excluded from Biome.
- App routes live under `app/[locale]/`; `middleware.ts` is the next-intl locale middleware.

### Workers (Hono)

Reference impl: `byplay-log/src/index.ts` (canonical minimal Worker). For more complex setups: `dropply-api` (full middleware + Drizzle + cron + email), `live-user`/`baccarat` (Durable Objects). Note `flnk` and `wepush` are Next-on-Cloudflare apps — their `src/worker/index.ts` is an OpenNext wrapper, not a Hono entry; don't copy Worker structure from them.

- Middleware order: `accesslog → prettyJSON → requestId → cors`. Copy from `byplay-log`.
- `src/global.ts` sets `globalThis.logger` and `globalThis.isDebug`; side-effect import in `src/index.ts` (`import './global'`).
- Error envelope: `{ statusCode, message, stack? }` (`stack` only when `isDebug`); 404 is the same minus `stack`. Reference impl: `dropply-api/src/index.ts`. The field is **not** uniform across the fleet — `byplay-log` uses `code`. Prefer `statusCode` for new Workers; only mirror `code` if a client depends on it.
- Routes: one `src/routes/<group>.ts` per group, composed via `src/routes/index.ts`.
- `wrangler.jsonc` `compatibility_date` bumped per quarter — see `deps-upgrade.md`.

### Drizzle (when a Worker uses a DB)

- Schema in `src/database/schema.ts`. Migrations live in `src/database/` (NOT `drizzle/`).
- `DB_TYPE` env (`libsql` default, or `d1`) selects dialect at config time. `LIBSQL_URL` defaults to `file:./src/database/data.db`.
- Every table has the shared `trackingFields` block: `createdAt`, `updatedAt` (auto via `$onUpdateFn`), `isDeleted` (default 0). **Never hard-delete** — filter with `eq(table.isDeleted, 0)`.
- IDs: UUID v4 (or `@cdlab/driftflake`); auto-increment only when ordering matters (e.g. `playerLogs`).

### Commits

- Conventional Commits: `feat`, `fix`, `refactor`, `chore`, `docs`, `build`, `test`. Optional scope: `feat(flnk): …`, `chore(deps): …`.
- Subject imperative, ≤ 72 chars; body wraps at 100. No `Co-authored-by` trailers.
- English only in commit messages, PR titles, PR bodies, and any other remote-visible Git metadata. No mention of AI assistants or model names.

## Step 4 — Verify before declaring done

Match the verification to the intent. Don't claim a task is finished without at least one of these passing:

- **New app/package**: `pnpm install` succeeds, then `pnpm --filter @cdlab/<name> typecheck` (and `lint` / `build` if defined). For a new Worker, also `pnpm --filter @cdlab/<name> cf-typegen`.
- **Dep upgrade**: `pnpm install` clean, then `pnpm lint:biome && pnpm build` at the root, plus `pnpm --filter @cdlab/<changed-pkg> test` if tests exist.
- **Refactor**: typecheck on every consumer + tests on the moved code (especially anything in `packages/utils` or `packages/cipher`).
- **New feature**: typecheck + lint on the touched app, plus a manual smoke test path (Workers: `nsl run wrangler dev` + curl the new route; Next: load the page).
- **Code review**: `pnpm lint:biome` (root), then `pnpm --filter <changed> typecheck`. Surface any catalog drift or ad-hoc versions.
- **Docs**: re-read the section you edited end-to-end and confirm it still parses as a coherent narrative — don't just dump bullet points.

If verification fails, fix the root cause; don't bypass the check.

## Step 5 — Update CLAUDE.md when meaningful

When a change is **architecturally meaningful** — new app, new shared package, new cross-cutting convention, retired feature — also update the project's `CLAUDE.md`. Use `references/update-docs.md` for the where/how. Cosmetic edits (rename a variable, fix a typo) don't need a doc bump.

## Notes

- **No CLAUDE.md in a fresh sub-repo?** Use this skill's cheatsheet and templates as the source of truth; offer to seed a starter `CLAUDE.md` after the first scaffold.
- **Templates are minimal on purpose.** They give wiring (package.json, tsconfig, configs) so the app boots — feature code is up to you. Copy, then trim or extend.
- **Don't over-engineer.** A tiny worker doesn't need Drizzle / global logger / soft-delete. Add scaffolding only when it earns its keep.
