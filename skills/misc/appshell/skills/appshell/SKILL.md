---
name: appshell
description: Installs, upgrades, and builds pages on appshell, the dashboard shell shipped as the @cdlab shadcn registry (github.com/wuchendi/appshell) for TanStack Router or Next.js App Router hosts — icon rail, resizable per-space panels, one-row page headers, fill pages whose table scrolls on its own, CollectionTable with sorting / selection / sub-rows / client or server paging, Filter and Display list menus, a Cmd/Ctrl+K search dialog, first-run intros. Triggers when the project's components.json declares an "@cdlab" registry or the app has shell/** (or src/shell/**) with AppShell, and for requests like "add the dashboard shell", "move this app onto appshell", "use appshell in this Next.js app", "upgrade / sync the shell to the latest release", "make this list page fill the screen", "add paging to this table", "add a space panel", or "add @cdlab/shell-<name>". Not for editing the appshell repository itself (that repo has its own AGENTS.md).
metadata:
  author: wudi
  version: "2026.11.23"
  source: https://github.com/WuChenDi/skills
---

# appshell

A dashboard app shell distributed as a **shadcn registry** under the `@cdlab` namespace — copied source, not an npm package. Hosts install it with the shadcn CLI and own the files under `shell/**` from then on (`src/shell/**` when the app has `src/`).

- Registry: `https://wuchendi.github.io/appshell/r/{name}.json` (latest release); `/v{X.Y.Z}/r/` pins a release; `/next/r/` tracks `main`.
- Source, changelog, releases: `https://github.com/wuchendi/appshell` (`docs/changelog.md` lists breaking changes per release).
- Demo: `https://wuchendi.github.io/appshell/demo/`

> Run CLI commands with the project's package runner (`bunx --bun shadcn@latest`, `pnpm dlx shadcn@latest`, `npx shadcn@latest`). Examples use `bunx`.

## Fit check (do this first)

The shell assumes this stack; check it before installing, and stop and say so if it does not hold:

- React 19 and either **TanStack Router** or **Next.js App Router** (server rendering supported). Other routers are not supported.
- `react-resizable-panels` v4, `lucide-react`, `cn` (the npm package; never rewritten to the host's `utils`).
- shadcn **`base-nova`** on **`@base-ui/react`** (Base UI `render` prop, never Radix `asChild`), Tailwind v4.
- `@/*` points at the folder the shell lands in: `./src/*` when the app has `src/`, else `./*`. Shell files import each other as `@/shell/...`; the CLI rewrites `@/components/ui/*` to the project's `ui` alias (a monorepo workspace package such as `@acme/ui/components` works) but leaves `@/shell/*` as is.

## Items

| Item | Contents | Depends on |
| --- | --- | --- |
| `shell-router-tanstack` / `shell-router-next` | `@/shell/router` (`shell/router.tsx`): `ShellLink`, `useShellPathname`, `useShellNavigate`, `useShellNavigating`. **Install exactly one.** | — |
| `shell-core` | `ShellLabels` (en/zh, plain data) + `labels-context`, `ShellSpace` path matching, panel state context, prefs cookie (`readShellPrefs`), bare-key guard, J/K row navigation, mobile hook, fill-page context | — |
| `shell-layout` | `AppShell`, `Rail`, `PageHeader`, `PageBody`, `IconButton`, `PanelFrame` / `PanelSection` / `PanelRow` / `PanelAllRow`, `NavigationProgress` | core, a router item |
| `shell-menus` | `FilterMenu`, `DisplayMenu`, `MenuSection`, `MenuRow`, `MenuSwitch`, `Chips`, `ResetButton`, `HeaderSearch` | core |
| `shell-collection` | `CollectionTable`, `CollectionPager`, `useCollectionPage`, `BatchBar`, `ColumnsSection`, `ShellColumn` | core, menus |
| `shell-search` | `SearchDialog` (host search function + "Go to" spaces) | core, a router item |
| `shell-intro` | `FeatureIntro`, `IntroArtCard`, `IntroArtArrow` | — |

`shell-collection` and `shell-menus` work without `shell-layout` or a router item, so an app with its own layout can adopt just the table or menus. `shell-layout` and `shell-search` fail to compile until a router item is installed.

## Install (first time)

1. Add the registry to `components.json` (merge into `registries`, keep the others):
   ```json
   { "registries": { "@cdlab": "https://wuchendi.github.io/appshell/r/{name}.json" } }
   ```
2. Add a router item and the items. When the CLI asks to overwrite an existing `components/ui/*` file, answer **no** — the host's components are its own. It asks even with `-y`, and without a terminal it stops at the first question and writes nothing:
   ```bash
   yes n | bunx --bun shadcn@latest add @cdlab/shell-router-next @cdlab/shell-layout @cdlab/shell-collection @cdlab/shell-search
   ```
3. Exclude the shell folder from the host's lint and format (Biome `files.includes: ["!src/shell/**"]` or `"!shell/**"`, ESLint `ignores`). The files follow appshell's own style; reformatting them makes every upgrade a noisy diff.
4. Canvas color (optional): the area behind the rail paints `var(--shell-canvas, var(--color-muted))`. Set `--shell-canvas` for light and dark in the host theme, using whatever dark-mode selector the host uses.
5. Wire it up — see "Using it" and [references/api.md](./references/api.md).

## Upgrade

Do **not** use `shadcn add` to upgrade: it prompts per differing file, so "no" also skips the shell files and `--overwrite` replaces the host's `components/ui`. Use the bundled script instead — it writes only the registry's own files (and their `@cdlab` dependencies) to the same place shadcn would, rewriting `@/components/ui/*` to the host's `ui` alias:

```bash
node <skill-dir>/scripts/sync-shell.mjs --dir apps/web --dry-run          # preview, items = what is installed
node <skill-dir>/scripts/sync-shell.mjs --dir apps/web --ref v0.4.1       # pin a release (default: latest)
node <skill-dir>/scripts/sync-shell.mjs --dir apps/web shell-router-next  # add or refresh specific items
```

It prints the shadcn components and npm packages the items import; install any the host lacks. Upgrading from v0.3.x it warns that no router adapter is installed — add one by name. Then:

1. Read the release notes / `docs/changelog.md` between the old and new version. Breaking changes so far:
   - v0.2.0, v0.3.0, v0.4.1: new `ShellLabels` keys (v0.4.1: `selectRow`, `searchFailed`).
   - v0.3.0: `--canvas` → `--shell-canvas`; `CollectionTable headerClassName` no longer sets the sticky offset.
   - v0.3.1: no API change, but overlong cells clip with an ellipsis and wide tables scroll sideways.
   - v0.4.0: a router item is required; files move from `~/src/shell` to `shell/` (still `src/shell` in apps with `src/`); `PanelRow` / `PanelAllRow` `to` → `href` (`params` / `search` removed — build the full href); `useShellPanelStore` → `useShellPanel()`; `layoutId` removed and the panel state moves from localStorage to the `appshell` cookie (old values ignored); `useShellLabels` moves to `@/shell/core/labels-context`.
   - v0.4.1: a rail entry folds only its own space's panel on that space's `href`; from a detail page it navigates back.
2. `git diff` the shell folder to review, then fix the host side (labels object, theme variable, call sites). Delete shell files the release removed (v0.4.0: `core/panel-store.ts`).
3. Typecheck, unit tests, and run the app (or its e2e) — the shell has no host-side tests of its own.

Never patch the shell folder in the host. A fix there is lost on the next sync; it belongs upstream (open an issue or PR on `wuchendi/appshell`, or write the requirement down for whoever maintains it).

## Using it

- **TanStack Router**: the root route renders `<AppShell spaces panels homeHref logo logoLabel account labels newAction onSearch>` around `<Outlet />`.
- **Next.js App Router**: `AppShell` takes components and functions, so render it from a `"use client"` wrapper; the server layout reads the prefs cookie and passes it so the first render matches the client:
  ```tsx
  // app/layout.tsx (Server Component)
  const prefs = readShellPrefs((await cookies()).toString()); // @/shell/core/prefs
  return <html><body><Shell prefs={prefs} labels={shellLabelsZh}>{children}</Shell></body></html>;
  ```
  Reading cookies makes those routes dynamic. `@/shell/core/labels`, `prefs`, `spaces` and the collection helpers are plain modules a Server Component can import; everything else is a client component.
- **Spaces and panels**: `spaces` are the rail entries (`footer: true` ones sit at the bottom); `panels` maps a space key to its panel component. Panel open state and width live in the `appshell` cookie; `useShellPanel()` reads and sets the open state.
- **Labels**: every visible string comes from `labels`. Use `shellLabelsEn` / `shellLabelsZh`, or build the object from the host's i18n. Keep the shell's placeholders intact — with i18next pass them through, e.g. `t("list.selected", { count: "{count}" })`.
- **Every page** starts with `<PageHeader title menu tools actions />` (filters and header search in `tools`, the display menu and icon buttons in `actions`).
- **List pages that must keep the column header and pager on screen**: put `<PageBody fill>` as a **direct child of the page's root element**, after the header, with the table (and pager) inside. Detail pages in the same space skip it and scroll as a whole.
- **Tables**: `ShellColumn<T>[]` + `<CollectionTable getRowLabel>`; client paging via `useCollectionPage(sortedRows)` + `<CollectionPager {...pager} />`; server paging by feeding `<CollectionPager page pageSize total onPageChange>` yourself.
- **Links in host code** that should drive the progress bar on Next.js: `ShellLink` / `useShellNavigate` from `@/shell/router`.
- **Search**: render `<SearchDialog>` yourself, open it from `onSearch`, pass `search(query, signal)`.

Details, prop lists and gotchas: [references/api.md](./references/api.md). When in doubt, read the installed source in the shell folder — it is the API.

## Workflow

1. **Fit check** — stack, router, alias (above). Note the package runner, the app root (`apps/web` in a monorepo) and whether it has `src/`.
2. **Install or sync** — first install via `shadcn add` (router item included); upgrades via `scripts/sync-shell.mjs`.
3. **Wire** — labels, spaces and panels (on Next.js: client wrapper + `prefs` from the server layout), then per page: header, `PageBody fill` for lists, table and pager.
4. **Exclude** the shell folder from host lint/format.
5. **Verify** — typecheck, tests, and load the app: fold the panel (Cmd/Ctrl+B) and reload (it stays folded; on Next.js no hydration warning), Cmd/Ctrl+K, J/K on a list, a fill list scrolled to the bottom (header and pager still visible), dark mode canvas.
