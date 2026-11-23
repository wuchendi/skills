---
name: appshell
description: Installs, upgrades, and builds pages on appshell, the dashboard shell shipped as the @cdlab shadcn registry (github.com/wuchendi/appshell) — icon rail, resizable per-space panels, one-row page headers, fill pages whose table scrolls on its own, CollectionTable with sorting / selection / sub-rows / client or server paging, Filter and Display list menus, a Cmd/Ctrl+K search dialog, first-run intros. Triggers when the project's components.json declares an "@cdlab" registry or the app has src/shell/** with AppShell, and for requests like "add the dashboard shell", "move this app onto appshell", "upgrade / sync the shell to the latest release", "make this list page fill the screen", "add paging to this table", "add a space panel", or "add @cdlab/shell-<name>". Not for editing the appshell repository itself (that repo has its own AGENTS.md).
metadata:
  author: wudi
  version: "2026.11.23"
  source: https://github.com/WuChenDi/skills
---

# appshell

A dashboard app shell distributed as a **shadcn registry** under the `@cdlab` namespace — copied source, not an npm package. Hosts install it with the shadcn CLI and own the files under `src/shell/**` from then on.

- Registry: `https://wuchendi.github.io/appshell/r/{name}.json` (latest release); `/v{X.Y.Z}/r/` pins a release; `/next/r/` tracks `main`.
- Source, changelog, releases: `https://github.com/wuchendi/appshell` (`docs/changelog.md` lists breaking changes per release).
- Demo: `https://wuchendi.github.io/appshell/demo/`

> Run CLI commands with the project's package runner (`bunx --bun shadcn@latest`, `pnpm dlx shadcn@latest`, `npx shadcn@latest`). Examples use `bunx`.

## Fit check (do this first)

The shell assumes this stack; check it before installing, and stop and say so if it does not hold:

- React 19, **TanStack Router** (it imports `Link`, `useNavigate`, `useRouterState`), zustand, `react-resizable-panels` v4, `lucide-react`, `cn`.
- shadcn **`base-nova`** on **`@base-ui/react`** (Base UI `render` prop, never Radix `asChild`), Tailwind v4.
- An `@/*` → `src/*` path alias. Shell files import each other as `@/shell/...`; the CLI rewrites `@/components/ui/*` to the project's `ui` alias but leaves `@/shell/*` as is.
- No existing `--canvas`-style conflicts are possible since v0.3.0 (the shell reads only `--shell-canvas`).

## Items

| Item | Contents | Depends on |
| --- | --- | --- |
| `shell-core` | `ShellLabels` (en/zh) + provider, `ShellSpace` path matching, persisted panel state, typing guard, J/K row navigation, mobile hook, fill-page context | — |
| `shell-layout` | `AppShell`, `Rail`, `PageHeader`, `PageBody`, `IconButton`, `PanelFrame` / `PanelSection` / `PanelRow` / `PanelAllRow`, `NavigationProgress` | core |
| `shell-menus` | `FilterMenu`, `DisplayMenu`, `MenuSection`, `MenuRow`, `MenuSwitch`, `Chips`, `ResetButton`, `HeaderSearch` | core |
| `shell-collection` | `CollectionTable`, `CollectionPager`, `useCollectionPage`, `BatchBar`, `ColumnsSection`, `ShellColumn` | core, menus |
| `shell-search` | `SearchDialog` (host search function + "Go to" spaces) | core |
| `shell-intro` | `FeatureIntro`, `IntroArtCard`, `IntroArtArrow` | — |

`shell-collection`, `shell-menus` and `shell-search` work without `shell-layout`, so an app with its own layout can adopt just the table or menus.

## Install (first time)

1. Add the registry to `components.json` (merge into `registries`, keep the others):
   ```json
   { "registries": { "@cdlab": "https://wuchendi.github.io/appshell/r/{name}.json" } }
   ```
2. Add the items. When the CLI asks to overwrite an existing `components/ui/*` file, answer **no** — the host's components are its own:
   ```bash
   yes n | bunx --bun shadcn@latest add @cdlab/shell-layout @cdlab/shell-collection @cdlab/shell-search
   ```
3. Exclude `src/shell/**` from the host's lint and format (Biome `files.includes: ["!src/shell/**"]`, ESLint `ignores`). The files follow appshell's own style; reformatting them makes every upgrade a noisy diff.
4. Canvas color (optional): the area behind the rail paints `var(--shell-canvas, var(--color-muted))`. Set `--shell-canvas` for light and dark in the host theme, using whatever dark-mode selector the host uses.
5. Wire it up — see "Using it" and [references/api.md](./references/api.md).

## Upgrade

Do **not** use `shadcn add` to upgrade: it prompts per file, so "no" also skips the shell files and `--overwrite` replaces the host's `components/ui`. Use the bundled script instead — it writes only the registry's own files (and their `@cdlab` dependencies) under `src/`:

```bash
node <skill-dir>/scripts/sync-shell.mjs --dir apps/web --dry-run          # preview, items = what is installed
node <skill-dir>/scripts/sync-shell.mjs --dir apps/web --ref v0.3.0       # pin a release (default: latest)
node <skill-dir>/scripts/sync-shell.mjs --dir apps/web shell-collection   # add or refresh specific items
```

It prints the shadcn components and npm packages the items import; install any the host lacks. Then:

1. Read the release notes / `docs/changelog.md` between the old and new version. Breaking changes so far: new `ShellLabels` keys (v0.2.0, v0.3.0), `--canvas` → `--shell-canvas` (v0.3.0), `CollectionTable headerClassName` no longer sets the sticky offset (v0.3.0).
2. `git diff src/shell` to review, then fix the host side (labels object, theme variable, call sites).
3. Typecheck, unit tests, and run the app (or its e2e) — the shell has no host-side tests of its own.

Never patch `src/shell/**` in the host. A fix there is lost on the next sync; it belongs upstream (open an issue or PR on `wuchendi/appshell`, or write the requirement down for whoever maintains it).

## Using it

- **Root route**: render `<AppShell spaces panels homeHref logo logoLabel account labels newAction onSearch layoutId>` around `<Outlet />`. `spaces` are the rail entries (`footer: true` ones sit at the bottom); `panels` maps a space key to its panel component.
- **Labels**: every visible string comes from `labels`. Use `shellLabelsEn` / `shellLabelsZh`, or build the object from the host's i18n. Keep the shell's placeholders intact — with i18next pass them through, e.g. `t("list.selected", { count: "{count}" })`.
- **Every page** starts with `<PageHeader title menu tools actions />` (filters and header search in `tools`, the display menu and icon buttons in `actions`).
- **List pages that must keep the column header and pager on screen**: put `<PageBody fill>` as a **direct child of the page's root element**, after the header, with the table (and pager) inside. Detail pages in the same space skip it and scroll as a whole.
- **Tables**: `ShellColumn<T>[]` + `<CollectionTable>`; client paging via `useCollectionPage(sortedRows)` + `<CollectionPager {...pager} />`; server paging by feeding `<CollectionPager page pageSize total onPageChange>` yourself.
- **Search**: render `<SearchDialog>` yourself, open it from `onSearch`, pass `search(query, signal)`.

Details, prop lists and gotchas: [references/api.md](./references/api.md). When in doubt, read the installed source in `src/shell/**` — it is the API.

## Workflow

1. **Fit check** — stack, router, alias (above). Note the package runner and the app root (`apps/web` in a monorepo).
2. **Install or sync** — first install via `shadcn add`; upgrades via `scripts/sync-shell.mjs`.
3. **Wire** — labels, spaces and panels, then per page: header, `PageBody fill` for lists, table and pager.
4. **Exclude** `src/shell/**` from host lint/format.
5. **Verify** — typecheck, tests, and load the app: fold the panel (Cmd/Ctrl+B), Cmd/Ctrl+K, J/K on a list, a fill list scrolled to the bottom (header and pager still visible), dark mode canvas.
