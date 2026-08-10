# New App Playbook

Use this when the user wants to add a new app to `apps/`.

## Step 0 — Pick the variant

Ask one short question if the user hasn't said:

> "Is this a Next.js app (frontend / static export), a Cloudflare Worker (API / backend), or a Nuxt app (content / dashboard)?"

Each variant has its own template under `assets/templates/`:

| Variant      | When to pick it                                                                              | Template               |
|--------------|----------------------------------------------------------------------------------------------|------------------------|
| `nextjs-app` | UI-heavy app, browser-first features, deploys to Cloudflare Pages                            | `assets/templates/nextjs-app` |
| `worker-app` | HTTP API, webhook, scheduled job, Durable Object, anything that runs on Cloudflare Workers   | `assets/templates/worker-app` |
| `nuxt-app`   | Content / dashboard with SSR/ISR, deploys to Vercel                                          | `assets/templates/nuxt-app`   |

If the user is uncertain, ask one clarifying question (e.g. "Does it need a server-side API?" or "Does it need SSR?"). Don't guess.

## Step 1 — Confirm naming

Decide the app name early; everything depends on it.

- **Directory**: `apps/<app-name>` (kebab-case).
- **Workspace name**: `@cdlab/<app-name>`.
- **Dev URL**: `http://<app-name>.localhost:3355` (set automatically by `nsl`).
- **Worker name** (CF Workers only): same as the directory; lives in `wrangler.jsonc` `name` field.

Confirm with the user in one line: "Use `<name>` for both the directory and the workspace package name, right?"

## Step 2 — Copy and rename

Copy the template directory and substitute placeholders.

```bash
cp -r <skill-path>/assets/templates/<variant>/. apps/<app-name>/
cd apps/<app-name>
# Replace placeholders (see template README inside each template dir for the list)
# Common ones:
#   __APP_NAME__          → <app-name>
#   __APP_DESCRIPTION__   → "<one-line description>"
```

Then read the template's own README (it lists exactly which placeholders exist and any optional bits to delete).

## Step 3 — Wire into the workspace

1. **Catalog deps**: any dep already in `pnpm-workspace.yaml` should reference `catalog:prod` / `catalog:dev`. Add new ones to the catalog if a second app might use them.
2. **Root `package.json` scripts**: add `dev:<short>` and (if it deploys via Turbo) `deploy:<short>` aliases. Follow the existing alias pattern (`turbo dev --filter=./apps/<app-name>`).
3. **`biome.json` overrides**:
   - Next.js / React app → add path to the next/react overrides block.
   - Vue / Nuxt app → add to the Vue overrides block; also add `apps/<app-name>/**` to `files.includes` exclusions if it has its own ESLint.
   - Worker → no override needed (recommended-off baseline is correct).
4. **`.vscode/settings.json`** (only if i18n) — append `"apps/<app-name>/messages"` to `i18n-ally.localesPaths`.
5. **Deploy script** — if the app deploys via `turbo deploy` (Workers, OpenNext-built Next apps), add `deploy:<short>` to root `package.json`. If it deploys via the Pages dashboard or Vercel auto-deploy, **don't** add a deploy script — keep CI hands-off.

## Step 4 — Install and verify

```bash
pnpm install
pnpm --filter @cdlab/<app-name> typecheck
pnpm --filter @cdlab/<app-name> build       # smoke build
pnpm --filter @cdlab/<app-name> dev         # boot dev server, hit the URL once
pnpm lint:biome                             # from the root — biome only exists there
```

For a Worker, additionally:

```bash
pnpm --filter @cdlab/<app-name> cf-typegen
```

Don't claim done before at least typecheck + dev-boot pass.

## Step 5 — Update CLAUDE.md (if it exists)

Add the new app to:

- The runtime-family table at the top of `CLAUDE.md`
- An `### <app-name>` subsection under `## Architecture` describing entry point, route structure, and any DO / DB / cache it uses

Use the same level of detail as neighboring sections — terse, architectural, not a tutorial. See `update-docs.md` for tone guidance.

## Variant-specific notes

### Next.js (`nextjs-app` template)

- **Ships with i18n (en/zh) and a complete `src/components/layout/*` set by default** — `Header`, `Footer`, `ClientProviders`, `ThemeProvider`, `ThemeToggle`, `LanguageSelector`. Modeled after `apps/dropply-web` (i18n) and `apps/flox` (layout assembly).
- Default is **static export** (`output: 'export'`) deploying to Cloudflare Pages. Drop `output: 'export'` if you need SSR or route handlers.
- Tailwind v4 comes via `@cdlab/ui/globals.css` (imported once in `app/[locale]/layout.tsx`). PostCSS config is `export { default } from '@cdlab/ui/postcss.config'`.
- shadcn/ui components live in `@cdlab/ui/components/<name>` — never copy a component into the app; add it to the shared package.
- **i18n on by default**: routes live under `app/[locale]/`, `middleware.ts` is the next-intl middleware, `messages/{en,zh}.json` are seeded with `theme/language/header/footer/home/error/notFound/seo` keys. Add `apps/<name>/messages` to `i18n-ally.localesPaths` in `.vscode/settings.json` after scaffolding.
- **Need a single-locale app?** The template README has a precise deletion checklist (drop `src/i18n`, `src/middleware.ts`, `src/app/[locale]`, `messages/`, the `next-intl` import in `next.config.ts` and dep, the `useTranslations` calls in `Header` / `ThemeToggle`, and the `LanguageSelector` component). The result mirrors `apps/flox` — same layout, no locale routing.
- If you hit Turbopack issues with wasm + workers, switch the build script to `next build --webpack` (see `clearify`/`flox`).

### Cloudflare Worker (`worker-app` template)

- Entry: `src/index.ts`. Hono app with the standard middleware order: `accesslog → prettyJSON → requestId → cors`.
- `src/global.ts` sets `globalThis.logger` and `globalThis.isDebug`. Import for side effects with `import './global'` at the top of `src/index.ts`.
- The error envelope `{ statusCode, message, stack? }` (`stack` only when `isDebug`) and the matching 404 handler are pre-wired.
- Routes split into `src/routes/<group>.ts` and composed via `src/routes/index.ts`.
- `wrangler.jsonc` has `compatibility_date` set to a recent quarter and `compatibility_flags: ['nodejs_compat']`. Bump the date when you upgrade (see `deps-upgrade.md`).
- `observability` is on (`enabled: true, head_sampling_rate: 1`).
- **If the Worker doesn't need a DB**, delete `drizzle.config.ts`, the `src/database/` folder, the `db:*` scripts, and the `d1_databases` block in `wrangler.jsonc`. Don't ship dead code.
- **If it needs a DB**, the template ships the Drizzle two-dialect setup. Add tables to `schema.ts` with the `trackingFields` block (see the Drizzle section of `SKILL.md`), then `pnpm db:gen` to generate the migration, then `pnpm cf:localdb` to apply locally.
- One Hono `Bot`/client constructed per request — never share stateful clients across requests on Workers (cf. the Telegram bot pattern in `baccarat`).

### Nuxt (`nuxt-app` template)

- `nuxt.config.ts` enables `@nuxt/ui` and `@vueuse/nuxt` by default. Add `@nuxtjs/mdc` if the app renders markdown (that's what `repo-changelog` does); trim anything you don't need.
- Routes via `app/pages/`; page components in `app/components/`; composables in `app/composables/`.
- Server data lives in `shared/types/` (typed for both client and server bundles).
- Set `routeRules: { '/': { isr: 60 } }` for ISR pages; add `compatibilityDate` to the current quarter.
- Add `apps/<app-name>/**` to `biome.json` `files.includes` exclusions — Nuxt apps run their own ESLint.
- `dev` script is `nsl run nuxt dev`; deploy is via Vercel auto-import.

## Common pitfalls

- Bare `next dev` / `wrangler dev` instead of `nsl run …` — the app starts on a random port instead of `http://<name>.localhost:3355`.
- `output: 'export'` + server route handlers in the same Next app — incompatible.
- New React app without a `biome.json` `next/react` override — domain rules silently don't apply.
- Pinning a literal version for a dep that's already in the catalog — drift.
