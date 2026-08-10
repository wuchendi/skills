# Conventions Reference

Rules and patterns that should hold across every package and app. Read this when you're unsure whether some choice matches the project style.

## Code style

Biome handles formatting. Hard rules at error level:

- Single quotes, no semicolons, 2-space indent.
- `import type { X }` (separated form). `import { type X }` fails lint.
- `import * as z from 'zod'`. `import { z }` is blocked.
- Every async call awaited or `void`-ed (`noFloatingPromises`, `noMisusedPromises`).
- `// @ts-expect-error <reason>`, never `// @ts-ignore`.
- `Date.now()`, never `new Date().getTime()`.
- No `delete obj.prop`.

Warnings worth fixing rather than silencing: `noUnusedImports`, `noImplicitAnyLet`.

## Lint domain overrides

New React/Next app → add path to the `next` + `react` domain override in `biome.json`. New Vue/Nuxt app → `vue` domain override **and** add its `**/*` to `files.includes` exclusions (Nuxt brings its own ESLint). Worker → no override needed.

## Files Biome should ignore

Build output (`dist`, `build`, `public`, `.next`, `.out`, `.wrangler`, `.turbo`, `.cache`) and generated artefacts (`apps/<worker>/src/database/**/*.{json,sql}`, `packages/ui/src/{components,reactbits}/**/*.tsx`) are excluded. `apps/repo-changelog/**` is excluded because Nuxt has its own ESLint. Extend `files.includes` for any new generated/vendored sources.

## Dependencies

- Catalogs in `pnpm-workspace.yaml` are the source of truth. `prod` for runtime, `dev` for tooling. Reference as `"react": "catalog:prod"`.
- Bump a shared dep by editing `pnpm-workspace.yaml`, not individual `package.json`s.
- New dep used by multiple apps → catalog. Used by exactly one → literal version in that app, promote later if a second app picks it up.
- Cross-package imports: `"@cdlab/utils": "workspace:*"`.
- `utils`, `cipher`, `uncrypto` are tsdown-built; rebuild after editing (`pnpm --filter @cdlab/<pkg> build`) or run `dev --watch`. `pnpm prepare` does this automatically post-install.

## Workspace package metadata

Every `package.json` (apps and packages) carries this header:

```json
{
  "name": "@cdlab/<kebab-name>",
  "type": "module",
  "version": "1.0.0",
  "private": true,
  "description": "<one-line>",
  "author": "wudi <wuchendi96@gmail.com>",
  "license": "MIT",
  "homepage": "https://github.com/WuChenDi",
  "repository": {
    "type": "git",
    "url": "https://github.com/WuChenDi/projects.git",
    "directory": "<apps|packages>/<name>"
  }
}
```

Apps additionally use `version: "0.1.0"` if they're pre-1.0.

## Scripts conventions

- Dev: `nsl run <tool> dev` — never bare `next dev` / `wrangler dev` / `nuxt dev`.
- Typecheck: `tsc --noEmit` (Next, Workers) or `nuxt typecheck` (Nuxt) or `tsc --project ./tsconfig.json --noEmit` (packages).
- Lint per-app: `lint` script on each app, delegated by `turbo lint` at the root.
- Build: `build` exists everywhere; the deploy step is **explicit** (`turbo deploy`) and **does not auto-deploy from CI**.

## i18n (next-intl)

- `messages/{en,zh}.json` — both define every user-visible key.
- Routes under `app/[locale]/…`; `middleware.ts` is the next-intl locale middleware.
- `messages/en.d.json.ts` is generated, gitignored, Biome-excluded.
- Add new app's `messages/` path to `.vscode/settings.json` `i18n-ally.localesPaths`.

## API response envelope (Workers)

For errors:

```ts
{ statusCode: number, message: string, stack?: string[] }
```

`stack` is included only when `globalThis.isDebug === true`. Same shape from `app.onError` and `app.notFound`. See `byplay-log/src/index.ts` and `dropply-api/src/index.ts` — both use this exact pattern; copy from there when adding a new Worker.

For success, use whatever shape fits the route — be consistent inside a single app.

## Soft delete

Tables share a `trackingFields` block — see `dropply-api/src/database/schema.ts` for the canonical definition. **Never hard-delete.** Every read filters `eq(table.isDeleted, false)`; the cleanup cron may purge old soft-deleted rows, but app code never calls `db.delete()` on user-facing tables.

`dropply-api/src/cron/cleanup.ts` and `flnk/src/lib/data/cleanup.ts` are the cleanup-cron pattern: scheduled via `wrangler.jsonc` `triggers.crons`, invoked from the Worker's `scheduled()` handler, and (in `flnk`'s case) also clears the matching KV cache entries.

## Cache invalidation (apps that use Cloudflare KV)

`flnk` is the reference. Key builders live in one place — `flnk/src/lib/data/cache-keys.ts` — rather than being inlined at call sites, because the produced strings address live KV entries and must stay byte-identical (`link:{domain}:{slug}`, `visits:{id}`, `pwfail:{ip}:{slug}`). Follow that shape: a central key-builder module per app, and invalidate every key for a record in the same operation — drift between them leaks stale data. Changing a key format needs a coordinated migration, not an edit.

## Commits

- Conventional Commits (`feat`, `fix`, `refactor`, `chore`, `docs`, `build`, `test`, `style`, `perf`, `ci`).
- Optional scope = the affected app or package: `feat(flnk): …`, `chore(deps): …`, `refactor(utils): …`.
- Subject in imperative mood, English, ≤ 72 chars. Body wraps at 100.
- No mention of AI assistants, model names, or co-authored-by trailers in any remote-visible Git metadata (commits, PR titles, PR bodies, comments).
