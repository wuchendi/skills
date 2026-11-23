# appshell API and gotchas

Reference for the installed files under `src/shell/**` (as of v0.3.1). Imports are `@/shell/<folder>/<file>`. When this disagrees with the installed source, the source wins.

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
| `layoutId?: string` | localStorage key of the saved panel width; give each app its own. |

Behaviour: Cmd/Ctrl+B folds the panel (animated, the page never remounts); clicking the current rail entry or the panel edge folds it too; the open state persists (`appshell-panel-open`). Below `md` the rail and panel move into a sheet behind a top bar.

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
- `PanelRow` — `to` (link) or `onClick` (button; then navigates to `to` if given) or neither (plain text). `icon` or `dot` (`success | info | progress | warning | danger | muted`; `progress` pulses), `count`, `active`, `menu` (right-click entries), `inset` (reserves the marker slot so a row without icon/dot lines up).
- `PanelAllRow to label` — muted closing "view all" row.
- Rows linking to the same path must pass `active` themselves; the router's fuzzy match is disabled on purpose.

### `IconButton` — `@/shell/layout/icon-button`

`label` (tooltip + accessible name), `icon`, `keys?` (shortcut hint chips), `side?`, plus button props.

## Collection (`shell-collection`)

### `ShellColumn<T>` — `@/shell/collection/columns`

`{ key, header, width?, align?: "start" | "end", sortKey?, core?, hideable?, cell(row) }`. The first column is the primary one (default track `minmax(14rem,1fr)`, never hideable); others default to `6.5rem`. `core` columns stay on narrow screens. `width` is any CSS grid track.

### `CollectionTable` — `@/shell/collection/collection-table`

| Prop | Notes |
| --- | --- |
| `columns`, `rows`, `getRowId` | `rows` is what to show — already filtered, sorted and (when paging) sliced. |
| `hiddenColumns?: string[]` | Keys hidden via `ColumnsSection`. |
| `sort?: { key, direction?, onSort(key) }` | The table only renders the header state; the host sorts. |
| `selection?: { selected: Set, onToggle(id, on), onToggleAll(on) }` | "Select all" acts on `rows` — with paging, the current page. |
| `onOpen?(row)` | Row click (outside its own controls) or Enter. |
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

Rows carry `data-shell-row`; J/K and arrows move between them, starting from the first row when nothing is focused. Elements matching `ROW_INTERACTIVE` (links, buttons, checkboxes, menu items) do not open the row.

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

`FilterMenu count onReset` (header button, count badge) and `DisplayMenu` (icon button) are popovers; fill them with `MenuSection label` + `Chips` (multi-select pills; `ChipCount` for a count badge), `MenuRow label` (a labelled control row), `MenuSwitch`. `ResetButton onClick` clears filters; `HeaderSearch value onChange placeholder?` is an expanding search field.

## Search (`shell-search`)

`<SearchDialog open onOpenChange spaces search resultsLabel />` — `search(query, signal) => Promise<ShellSearchResult[]>` with `{ id, label, detail?, icon?, onSelect }`. The dialog adds a "Go to" group built from `spaces`.

## Labels (`shell-core`)

`ShellLabels` keys (v0.3.0): `toggleSidebar`, `openMenu`, `search`, `searchPlaceholder`, `searchEmpty`, `goTo`, `filter`, `filterActive` (`{count}`), `display`, `reset`, `clearSearch`, `loading`, `selectedCount` (`{count}`), `selectAll`, `deselectAll`, `clearSelection`, `columns`, `pagerTotal` (`{total}`), `pagerSelected` (`{count}`, `{total}`), `pagerPage` (`{page}`, `{pages}`), `pageSize` (`{size}`), `firstPage`, `previousPage`, `nextPage`, `lastPage`. A typed host object fails typecheck when a release adds keys — that is the signal to add translations.

## Gotchas

- **Base UI, not Radix**: custom triggers use `render={<Button … />}`, not `asChild`. Menu radio items keep the menu open unless given `closeOnClick`.
- **Theme**: only `--shell-canvas` is read; nothing is injected into the host theme except the `shell-nav-progress` keyframes. Hosts on HSL-channel themes or `data-theme` dark mode work as long as `--color-muted` is a full color.
- **Fill mode needs the direct-child rule** above; a wrapper `<div>` between the page root and `PageBody` silently disables it.
- **Row backgrounds are opaque** (`color-mix` of `--color-secondary` into `--color-background`) so the pinned actions can cover what scrolls under them; a `getRowClassName` that sets a translucent background breaks that.
- **Panels that mount late** (a space that appears after an async check) require v0.3.0 or later; v0.2.1 crashed with "Panel constraints not found".
- **Don't edit `src/shell/**` in the host**; sync and fix upstream.
