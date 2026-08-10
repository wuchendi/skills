# Refactor Playbook (cdlab layer)

Refactor work for the cdlab `projects` monorepo. Use when the user wants to extract / consolidate / reorganise / reuse code across the workspace boundary.

## Routing

| Pattern                                    | Where the new code lives          | Section          |
|--------------------------------------------|-----------------------------------|------------------|
| Multiple apps repeat the same helper       | `packages/utils` (a new module)   | §A — Sink to utils |
| One app has tangled internal modules       | inside the same app, no package   | §B — In-app reorg  |
| A shadcn/ui-style component duplicated     | `packages/ui/src/components`      | §C — Sink to ui    |

If the user's intent doesn't fit, ask which it is.

---

## §A — Sink shared logic to `packages/utils`

> **First**, run the generic methodology from the [`refactor-extract`](https://github.com/WuChenDi/skills/tree/main/skills/engineering/refactor-extract) skill — confirm-extract decision (≥2 callers, stable surface, no caller-specific state), decide the shape, two-commit pattern, when-not-to-refactor. **Then** apply the cdlab-specific layers below.

### A1 — cdlab-specific home selection

`packages/utils/src/` is organized by capability, one **flat module per capability** — not a folder each. Current modules:

- `clipboard.ts` — copy-to-clipboard
- `download.ts` — `downloadFile` (single Blob/URL) and `downloadFilesAsZip` (batch ZIP via dynamic `jszip`); ZIP naming convention `{prefix}_yyyyMMdd_HHmmss.zip`
- `format.ts` — formatting utilities
- `idb-store.ts` — IndexedDB-backed key/value store
- `logger.ts` — browser-side logger
- `password.ts` — password generation / strength
- `np/` — numerical-precision math (the one capability big enough to earn a folder)

Extend an existing module when the new helper fits. Add a new one only for a genuinely new capability (e.g. `cache.ts`, `cron.ts`) — and only promote it to a folder once it outgrows a single file, the way `np/` did.

Confirm the current shape with `ls $ROOT/packages/utils/src` before adding — this list drifts.

Recent extraction precedent: `download.ts` consolidated logic that used to live separately in `bycut`, `clearify`, `dropply-web`, `vidl`. See `refactor(utils): extract shared download utilities` (commit `44bcadd`) for the shape of that move.

### A2 — cdlab-specific move steps

1. Create (or extend) `packages/utils/src/<capability>.ts`.
2. Add tests next to it (`<capability>.test.ts`) using **vitest**.
3. Re-export from `packages/utils/src/index.ts` so consumers can `import { x } from '@cdlab/utils'`. (If subpath exports are configured, also re-export from the subpath barrel.)
4. Build the package: `pnpm --filter @cdlab/utils build` (or `dev --watch` if you'll iterate).
5. In each consumer app, replace the local copy with `import { x } from '@cdlab/utils'`.
6. Delete the now-unused local file. Run `pnpm --filter @cdlab/<app> typecheck` to confirm no orphaned imports.

### A3 — cdlab-specific verification

```bash
pnpm --filter @cdlab/utils test
pnpm --filter @cdlab/utils build
pnpm --filter @cdlab/<consumer-1> typecheck
pnpm --filter @cdlab/<consumer-2> typecheck
pnpm lint:biome
pnpm build
```

### A4 — cdlab-specific commit shape

Two commits, in this order:

```
refactor(utils): extract <name> from <app1>, <app2>
refactor(<app1>, <app2>): consume <name> from @cdlab/utils
```

(In practice the repo sometimes squashes these into one commit. Use judgment; if the diff is small, one commit is fine.)

---

## §B — In-app reorganisation

Moving files / renaming directories within one app, not crossing package boundaries. The `refactor-extract` skill does **not** cover this case (it's about cross-module extraction). Use this section directly.

### B1 — Decide the new shape first

Don't move files before you know the target structure. Sketch it out (in the conversation, not in a doc):

```
src/
├── core/managers/         (existing)
├── services/              (existing)
└── stores/                (existing)
```

Then identify what changes and why. Vague rationales like "it's cleaner" are red flags — push the user to articulate the concrete benefit (testability, locality, dependency direction).

### B2 — Move in one commit per logical group

A pure rename / move should land in **one commit per logical group**, with no behavior change. If you change behavior in the same commit, splitting them later becomes painful.

### B3 — Update imports atomically

- Use the editor's "rename file" / "move file" rather than `git mv` + manual import edits when possible.
- After every move, run `pnpm --filter @cdlab/<app> typecheck` before continuing. Don't accumulate broken intermediate states.

### B4 — Verify

```bash
pnpm --filter @cdlab/<app> typecheck
pnpm --filter @cdlab/<app> lint
pnpm --filter @cdlab/<app> build
pnpm --filter @cdlab/<app> dev    # boot once and exercise the path
```

### B5 — Commit shape

```
refactor(<app>): reorganize <subsystem> into <new-shape>
```

Body explains *why*. The diff should be ~99% renames + import path edits. If you see real logic changes, you accidentally bundled a feature change into the refactor — split it.

---

## §C — Sink a UI component to `packages/ui`

> Same principle: run the generic [`refactor-extract`](https://github.com/WuChenDi/skills/tree/main/skills/engineering/refactor-extract) decision (≥2 callers, no caller state, stable surface) **first**, then apply the cdlab UI specifics below.

### C1 — cdlab-specific fit check

`packages/ui` is a no-build, source-only library. Components are shadcn/ui-flavored: primitive, unopinionated, take all data via props, no app-specific imports. Reference: existing `packages/ui/src/components/*` (Button, Card, Tabs, Tooltip, DropdownMenu, etc.) and the `IK*` and `reactbits/*` curated sets.

If the component pulls from an app's Zustand store or makes API calls, it doesn't belong here yet — split the presentational layer out first, then sink only the dumb part. Recent precedent: `refactor(ui): migrate asset components to shared library` (commit `8cd269a`).

### C2 — cdlab-specific subpaths

- `packages/ui/src/components/<name>.tsx` for shadcn-derived primitives
- `packages/ui/src/hooks/<name>.ts` for hooks
- `packages/ui/src/lib/<name>.ts` for utilities
- `packages/ui/src/IK/<name>.tsx` / `reactbits/<name>.tsx` only for vendored sets — don't add ad-hoc files here

`packages/ui/src/components/**/*.tsx` and `reactbits/**/*.tsx` are **excluded from Biome** (third-party-derived). Don't try to lint them; if you do edit one, keep the original style.

### C3 — Update consumers

```ts
// before:
import { Button } from '@/components/ui/button'

// after:
import { Button } from '@cdlab/ui/components/button'
```

`packages/ui` has no build step — consumers pick up the new file the moment it lands (subject to the consuming app's bundler reading `node_modules/@cdlab/ui/src/`, which is configured by `paths` in tsconfig).

### C4 — Verify and commit

```bash
pnpm --filter @cdlab/<consumer-1> typecheck
pnpm --filter @cdlab/<consumer-2> typecheck
pnpm build
```

```
refactor(ui): consolidate <Component> into shared library
```

---

## cdlab-specific common pitfalls

- **Forgetting to rebuild `packages/utils`** after editing — consumers pull stale `dist/` until you do (`pnpm --filter @cdlab/utils build`).
- Moving a Biome-excluded file (`packages/ui/src/components/*` shadcn vendored) and accidentally lint-formatting it — keep the original style.
- Sinking a UI component that still touches a Zustand store or fetcher — `packages/ui` is presentational only.
