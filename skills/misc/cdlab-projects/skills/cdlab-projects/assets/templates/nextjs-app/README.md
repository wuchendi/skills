# nextjs-app template

Next.js (App Router) app skeleton in cdlab projects style. **Ships with i18n (en/zh) and a complete `src/components/layout/*` set by default**, so you can drop in and start writing business code without re-wiring locale, theme, header, footer, etc.

Modeled after `apps/dropply-web` (i18n) and `apps/flox` (layout assembly).

## What you get

- **i18n (next-intl)** — `[locale]` route segment, `messages/{en,zh}.json`, `LanguageSelector` in the header
- **Theming (next-themes)** — light/dark with `ThemeToggle`
- **Layout components** — `Header`, `Footer`, `ClientProviders`, `ThemeProvider`, `ThemeToggle`, `LanguageSelector`, all under `src/components/layout/`
- **Themed background** — gradient backdrop that switches with theme, lifted from the existing apps
- **Error / 404 pages** — both at root (passthrough) and `[locale]` (translated)
- **Static export to Cloudflare Pages** — `output: 'export'` plus `build:cf` script for `next-on-pages`
- **shadcn/ui wired in** — `components.json` already aliased to `@cdlab/ui/components`

## Placeholders to replace

| Placeholder              | Where                                                          | Example                          |
|--------------------------|----------------------------------------------------------------|----------------------------------|
| `__APP_NAME__`           | `package.json`, `wrangler` references, GitHub link in header  | `myapp`                          |
| `__APP_TITLE__`          | `messages/{en,zh}.json` (`header.title`), header logo letters | `MyApp`                          |
| `__APP_DESCRIPTION__`    | `package.json`, `messages/{en,zh}.json` (`seo.description`)   | `Awesome browser tool`           |

```bash
cd apps/<app-name>
find . -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.json' -o -name '*.mjs' \) -exec \
  sed -i \
    -e "s/__APP_NAME__/<app-name>/g" \
    -e "s/__APP_TITLE__/<App Title>/g" \
    -e "s/__APP_DESCRIPTION__/<one-line description>/g" \
    {} +
```

## After scaffolding

```bash
pnpm install
pnpm --filter @cdlab/<app-name> typecheck
pnpm --filter @cdlab/<app-name> dev
```

Open `http://<app-name>.localhost:3355` — `/` redirects to `/en`.

## Adding a new route (i18n on)

Create `src/app/[locale]/<route>/page.tsx`. Use `useTranslations()` for all user-facing strings; add the keys in **both** `messages/en.json` and `messages/zh.json`.

```tsx
'use client'
import { useTranslations } from 'next-intl'

export default function Page() {
  const t = useTranslations('myFeature')
  return <h1>{t('title')}</h1>
}
```

## Adding a new layout chunk

Drop the component under `src/components/layout/<name>.tsx` and re-export it from `src/components/layout/index.ts`. Existing layout pieces import each other with `@/components/layout/<name>`.

## Wire into the workspace

After scaffolding:

1. **Root `package.json`** — add a `dev:<short>` alias (and `deploy:<short>` if it deploys via Turbo).
2. **`biome.json` overrides** — add `"apps/<app-name>/**/*"` to the `next` + `react` domain block.
3. **`.vscode/settings.json`** — append `"apps/<app-name>/messages"` to `i18n-ally.localesPaths`.

---

## How to drop i18n (single-locale app)

If this app genuinely doesn't need i18n, delete these in one pass:

```bash
cd apps/<app-name>

# Routing + middleware + helpers
rm -rf src/i18n
rm src/middleware.ts
rm -rf src/app/\[locale\]

# Messages
rm -rf messages

# Replace next.config.ts (drop next-intl plugin wrapper)
# Edit by hand — see below
```

Then **edit these files**:

1. **`next.config.ts`** — remove the `createNextIntlPlugin` import and the `withNextIntl(nextConfig)` wrapper. Export `nextConfig` directly.

2. **`package.json`** — remove `next-intl` from `dependencies`.

3. **`src/app/layout.tsx`** — replace the passthrough root layout with the full `RootLayout` from what was `src/app/[locale]/layout.tsx`. Strip:
   - `params: Promise<{ locale: Locale }>`, `generateStaticParams`, `setRequestLocale`, `hasLocale`, `notFound`
   - `<NextIntlClientProvider messages={messages}>` wrapper (just keep its children)
   - The `if (locale === 'zh')` branch in `generateMetadata` (keep only the English block, with no params)

4. **`src/app/page.tsx`** — replace the `redirect('/en')` with the actual home page (move the body of `[locale]/page.tsx` here).

5. **`src/app/error.tsx`, `src/app/not-found.tsx`** — keep these (root-level versions are already i18n-free).

6. **`src/components/layout/header.tsx`** — remove the `useTranslations()` call, the `LanguageSelector` import + render, and replace `t('header.more')` → hardcoded `'more'` (or whatever copy you want). Use `next/link`'s `Link` directly instead of `@/i18n/navigation`.

7. **`src/components/layout/theme-toggle.tsx`** — remove `useTranslations()`; replace `t('theme.toggle')` → hardcoded `'Toggle theme'`.

8. **`src/components/layout/language-selector.tsx`** — delete the file.

9. **`src/components/layout/index.ts`** — remove the `language-selector` re-export.

The result mirrors the `apps/flox` shape — same layout components and themed background, just without locale routing.
