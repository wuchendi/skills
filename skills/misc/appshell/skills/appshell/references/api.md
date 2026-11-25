# appshell API and gotchas

Reference for the installed files under `shell/**` (`src/shell/**` in apps with `src/`), as of v0.4.2. Imports are `@/shell/<folder>/<file>`. When this disagrees with the installed source, the source wins.

## Router (`shell-router-tanstack` / `shell-router-next`) — `@/shell/router`

Both items install `shell/router.tsx` with the same exports; the shell routes only through them.

- `ShellLink` — `href` (an app path; query and hash allowed) plus anchor props.
- `useShellPathname()` — the current path without the base path. It is the path of the page on screen: on TanStack Router it reads `resolvedLocation`, so during a slow navigation (code split chunk, `beforeLoad`, `loader`) the rail and panel switch together with the page, as `usePathname` does on Next.js.
- `useShellNavigate()` — `(href) => void`.
- `useShellNavigating()` — drives `NavigationProgress`. On Next.js there is no router-wide pending state: it covers navigations started through `ShellLink` / `useShellNavigate` (the rail, panel rows and search use them); plain `next/link` elsewhere does not drive the bar.

## Layout (`shell-layout`)

### `AppShell` — `@/shell/layout/app-shell`

| Prop | Notes |
| --- | --- |
| `spaces: ShellSpace[]` | `{ key, href, label, icon, exact?, match?: string[], footer? }`. `match` adds path prefixes that belong to the space; `footer` puts it at the rail's foot. |
| `panels?: Record<key, ComponentType>` | The panel beside a space's pages. A space without one has no panel. |
| `homeHref`, `logo`, `logoLabel` | Logo link at the top of the rail; `logoLabel` is its accessible name. |
| `account?: ReactNode` | Control at the rail's foot (account menu). |
| `newAction?: { label, onSelect }` | Rail "new" button; the bare `C` key runs it. Pass `undefined` to hide (e.g. read-only users). |
| `onSearch?: () => void` | Rail search button and Cmd/Ctrl+K. The host renders the dialog. |
| `banner?: ReactNode` | Above the page inside the content card. |
| `labels?: ShellLabels` | Defaults to English. |
| `prefs?: ShellPrefs \| "client"` | Where the panel's stored state comes from. A `ShellPrefs` object: the `appshell` cookie as the server read it (`readShellPrefs(cookieHeader)` from `@/shell/core/prefs`), from a server-rendered layout so the first render matches the client. `"client"`: a statically prerendered host; the shell renders the defaults, then applies the cookie in a layout effect right after hydration, without the fold animation. Omitted: client-only (SPA) hosts; the shell reads `document.cookie` while rendering. |

Behaviour: Cmd/Ctrl+B folds the panel (animated, the page never remounts); the panel edge folds it too. A rail entry navigates to its space's `href`; only when that page is shown and the space has a panel does the click fold or unfold instead (from a detail page it goes back to `href`; a space without a panel always navigates). Open state and width persist in the `appshell` cookie (`0`/`1` plus an optional `:<width %>`), one width for every space. `useShellPanel()` (`@/shell/core/panel-state`) gives `{ open, toggle, setOpen }`. Below `md` the rail and panel move into a sheet behind a top bar; the inline panel is also hidden by CSS there, so a server render on a phone shows the page full width.

On Next.js render `AppShell` from a `"use client"` component: `spaces` (icons), `panels`, `newAction` and `onSearch` cannot cross the server/client boundary.

### `PageHeader` — `@/shell/layout/page-header`

`title`, `menu?` (makes the title a dropdown — pass `DropdownMenuRadioGroup` items), `tools?` (right after the title: `FilterMenu`, `ResetButton`, `HeaderSearch`), `actions?` (right side: `DisplayMenu`, `IconButton`s). Sticky at the top of the page; shows the space icon and, while the panel is folded, a button to unfold it.

### `PageBody` — `@/shell/layout/page-body`

`<PageBody fill>` switches the page to fill mode: the page stops scrolling as a whole, the body gets the height left under the header, and a child scrolls on its own. The shell detects it with CSS `:has([data-shell-fill])` — no state, nothing remounts.

- It must be a **direct child of the page root** (the element the route component returns) or the root itself. Deeper nesting does not get the height.
- Inside it: a `CollectionTable` (scrolls itself) followed by `CollectionPager`, or your own `ScrollArea` with `className="min-h-0 flex-1"`.
- Content taller than the window still scrolls with the page instead of being clipped.
- Without `fill` it is a plain `div`.

### Panels — `@/shell/layout/panel`

- `PanelFrame title actions?` — the panel: 48px title row over a scrolling body.
- `PanelSection label?` — a group; clicking the label folds it.
- `PanelRow` — `href` (link; a full app path, query included) or `onClick` (button; then navigates to `href` if given) or neither (plain text). `icon` or `dot` (`success | info | progress | warning | danger | muted`; `progress` pulses), `count` (a number hides at 0; a node, e.g. an animated number, always shows), `active`, `menu` (right-click entries), `inset` (reserves the marker slot so a row without icon/dot lines up).
- `PanelAllRow href label` — muted closing "view all" row.
- Rows pass `active` themselves (compare `useShellPathname()` and any filter state); rows linking to the same path cannot be told apart by the router.

### `IconButton` — `@/shell/layout/icon-button`

`label` (tooltip + accessible name), `icon`, `keys?` (shortcut hint chips), `side?`, plus button props.

## Collection (`shell-collection`)

### `ShellColumn<T>` — `@/shell/collection/columns`

`{ key, header, label?, width?, align?: "start" | "end", sortKey?, core?, hideable?, cell(row) }`. `label` names the column in `ColumnsSection` when `header` is not text (else a text `header`, else `key`). The first column is the primary one (default track `minmax(14rem,1fr)`, never hideable); others default to `6.5rem`. `core` columns stay on narrow screens. `width` is any CSS grid track.

### `CollectionTable` — `@/shell/collection/collection-table`

| Prop | Notes |
| --- | --- |
| `columns`, `rows`, `getRowId` | `rows` is what to show — already filtered, sorted and (when paging) sliced. |
| `getRowLabel?(row)` | The row checkbox's name, "Select {name}". Defaults to a text primary cell, then the id — pass it when the primary cell is a node. |
| `hiddenColumns?: string[]` | Keys hidden via `ColumnsSection`. |
| `sort?: { key, direction?, onSort(key) }` | The table only renders the header state; the host sorts. |
| `selection?: { selected: Set, onToggle(id, on), onToggleAll(on) }` | "Select all" acts on `rows` — with paging, the current page. |
| `onOpen?(row)` | Row click (inside the row's own DOM, outside its controls) or Enter. Clicks in menus and dialogs rendered from `rowActions` / `renderSubRow` do not open the row. |
| `rowMenu?(row)` | Right-click menu entries (`ContextMenuItem`s). |
| `rowActions?(row)` | Trailing cell revealed on hover/focus; `actionsWidth` sets its track. |
| `renderSubRow?(row)` | Full-width block under the row while it returns non-null. The host owns the expanded set; J/K skips sub-rows. |
| `loading?` | 8 skeleton rows under the header. |
| `empty?` | Shown instead of the rows when there are none (header kept). |
| `headerClassName?` | Extra classes for the header strip. Placement is automatic: fixed above the rows in a fill body, `sticky top-12` (under the page header) elsewhere. |

Layout (v0.3.1):

- **Cells clip.** A `cell()` that returns a string or number is wrapped in a truncating span (ellipsis); a custom node manages its own overflow (`block truncate`, `min-w-0`). Cells keep a 4px inset, so focus rings of controls inside them are not cut off.
- **Rows grow.** Rows are at least 36px (`min-h-9 py-1`) and grow with multi-line cells. Keep row controls at most 28px tall (`size="icon-sm"`), or single-line rows grow past 36px.
- **Wide tables scroll inside themselves.** The table's minimum width is the sum of its track minimums (`minmax(a, …)` counts `a`, fixed lengths count as is, `fr`/`auto` count 0) plus gaps; narrower containers get a horizontal scrollbar on the rows, and the header follows sideways. Give wide columns a real minimum (`minmax(10rem,1fr)`), not `1fr`, or they collapse instead of scrolling.
- **The table never widens its parent** (`contain: inline-size`): it takes the width it is given. Do not place it as a flex item in a row without a width; in a card, grid cell or column it fills the available width.
- **Actions stay pinned** to the right edge while the rows scroll sideways.

Rows carry `data-shell-row`; J/K and arrows move between them, starting from the first row when nothing is focused. Links, buttons, inputs, labels, checkboxes and menu items inside a row do not open it.

### Paging — `@/shell/collection/use-collection-page`, `collection-pager`, `pager`

```tsx
// Client mode: filter and sort first, then slice.
const { rows, pager } = useCollectionPage(sorted, { pageSize: 50 });
<PageBody fill>
  <CollectionTable rows={rows} ... />
  <CollectionPager {...pager} selected={selected.size} />
</PageBody>

// Server mode: rows is the current page from the server.
<CollectionPager page={page} pageSize={size} total={total}
  onPageChange={setPage} onPageSizeChange={s => { setSize(s); setPage(1); }} />
```

`CollectionPager` shows the total (or "selected / total" while `selected > 0`), a page-size menu (only with `onPageSizeChange`; `pageSizes` defaults to 20/50/100), "page X of Y" and first/previous/next/last. `useCollectionPage` clamps the page when rows shrink and restarts at page 1 on a new size. Pure helpers: `paginate`, `pageCount`, `clampPage`.

### `BatchBar`, `ColumnsSection`

- `BatchBar count onClear` + action buttons (`BatchBarSeparator` between groups) — render it after the list while rows are selected. In a fill body it floats above the pager; elsewhere it sticks to the bottom.
- `ColumnsSection columns hidden onToggle(key)` — column switches for the `DisplayMenu`.

## Menus (`shell-menus`)

`FilterMenu count onReset` (header button, count badge) and `DisplayMenu` (icon button) are popovers; fill them with `MenuSection label` + `Chips` (multi-select pills; `ChipCount` for a count badge), `MenuRow label` (a labelled control row), `MenuSwitch`. `ResetButton onClick` clears filters; `HeaderSearch value onChange placeholder?` is an expanding search field (`/` opens it, Esc clears).

## Search (`shell-search`)

`<SearchDialog open onOpenChange spaces search resultsLabel />` — `search(query, signal) => Promise<ShellSearchResult[]>` with `{ id, label, detail?, icon?, media?, onSelect }`, debounced 200 ms and aborted when superseded. The dialog adds a "Go to" group built from `spaces`, shows `labels.loading` while a search is pending and `labels.searchFailed` when it rejects (results cleared). `detail` is muted text flush right (e.g. a short URL). `media` is a node shown in place of `icon` for thumbnails and avatars; size it `size-8` so rows stay even.

## Labels (`shell-core`)

`ShellLabels` (`@/shell/core/labels`, plain data; `useShellLabels` lives in `@/shell/core/labels-context`) keys (v0.4.1, unchanged in v0.4.2): `toggleSidebar`, `openMenu`, `search`, `searchPlaceholder`, `searchEmpty`, `searchFailed`, `goTo`, `filter`, `filterActive` (`{count}`), `display`, `reset`, `clearSearch`, `loading`, `selectedCount` (`{count}`), `selectAll`, `deselectAll`, `selectRow` (`{name}`), `clearSelection`, `columns`, `pagerTotal` (`{total}`), `pagerSelected` (`{count}`, `{total}`), `pagerPage` (`{page}`, `{pages}`), `pageSize` (`{size}`), `firstPage`, `previousPage`, `nextPage`, `lastPage`. A typed host object fails typecheck when a release adds keys — that is the signal to add translations.

## Gotchas

- **Shortcuts**: bare `C` (`newAction`), `/` (`HeaderSearch`) and J/K do nothing while typing, during IME composition or with focus in a modal dialog (`isBareKeyBlocked` in `@/shell/core/is-typing`); Cmd/Ctrl+B and Cmd/Ctrl+K always work.
- **Next.js**: every shipped component is `"use client"`; import `shellLabels*`, `readShellPrefs`, `ShellSpace` helpers and collection helpers freely on the server, but render shell components from client components when passing functions or icons.
- **Base UI, not Radix**: custom triggers use `render={<Button … />}`, not `asChild`. Menu radio items keep the menu open unless given `closeOnClick`.
- **Theme**: only `--shell-canvas` is read; nothing is injected into the host theme except the `shell-nav-progress` keyframes. Hosts on HSL-channel themes or `data-theme` dark mode work as long as `--color-muted` is a full color.
- **Fill mode needs the direct-child rule** above; a wrapper `<div>` between the page root and `PageBody` silently disables it.
- **Row backgrounds are opaque** (`color-mix` of `--color-secondary` into `--color-background`) so the pinned actions can cover what scrolls under them; a `getRowClassName` that sets a translucent background breaks that.
- **Panels that mount late** (a space that appears after an async check) require v0.3.0 or later; v0.2.1 crashed with "Panel constraints not found".
- **Don't edit the shell folder in the host**; sync and fix upstream.
