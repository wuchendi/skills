# Dependency Upgrade Playbook

Use this for `chore(deps): bump …` work. Three sub-flows: catalog bump, wrangler `compatibility_date` roll, and one-off package version pin.

## Decide the scope

Ask the user (or infer from their wording) which sub-flow:

1. **Catalog bump** — refresh many deps at once via `pnpm-workspace.yaml`. Most common.
2. **Compatibility date roll** — bump `compatibility_date` in every `wrangler.jsonc` to a new quarter.
3. **Single-app dep change** — add, remove, or pin one dep in one package.

Each has its own routine.

---

## Sub-flow A: Catalog bump

### A1 — Inspect

```bash
# What's outdated across the workspace
pnpm outdated -r --format json > /tmp/outdated.json   # or visual
pnpm outdated -r
```

Look at major-version jumps separately from minor/patch — they need release-note review.

### A2 — Decide what to bump

For each candidate, check at least one of:

- The package's CHANGELOG / release notes for the version range
- Whether any consumer in this workspace imports the symbols the release changed
- Whether the major version is supported by the runtime targets (Workers, Cloudflare Pages, browser)

Build a short table for the user before editing:

```
react           19.0.0 → 19.1.0    minor, safe
next            16.2.4 → 16.3.0    minor, safe (read CHANGELOG)
zod             4.4.3  → 5.0.0     MAJOR — breaking, defer
typescript      6.x    → 7.x       MAJOR — defer, needs catalog & per-app overlay review
```

Bump conservatively: minors and patches today; majors as separate PRs after release-note review.

### A3 — Edit `pnpm-workspace.yaml`

Edit the catalog versions. **Don't** edit individual `package.json` files — that defeats the catalog.

If you find an individual `package.json` that pins a version locally (literal `^x.y.z`) for a dep that lives in the catalog, that's drift. Migrate it to `catalog:prod` / `catalog:dev` as part of this PR.

### A4 — Reinstall and lockfile

```bash
pnpm install
git diff pnpm-lock.yaml | head -200       # quick sanity check
```

The lockfile churn should match the deps you bumped — large unrelated shifts mean something else changed (usually a transitive). Investigate before continuing.

### A5 — Verify

```bash
pnpm prepare                               # rebuild workspace packages in topo order
pnpm lint:biome
pnpm build                                 # full turbo build
pnpm --filter './packages/*' test          # only packages that have test scripts will run
```

For Workers, also boot dev locally (`pnpm --filter <worker> dev`) and hit at least one route — wrangler bumps occasionally break the dev runtime in ways `build` doesn't catch.

### A6 — Commit

```
chore(deps): bump catalog dependencies
```

Body lists the bumps in a table; one line per dep. Keep the diff focused — separate Major bumps and any code changes they require into their own commits.

---

## Sub-flow B: `compatibility_date` roll

Cloudflare publishes a new compat date roughly each quarter. The repo's commit history shows this is rolled in a single sweep.

### B1 — Find every wrangler config

```bash
grep -rln 'compatibility_date' apps/ --include 'wrangler.jsonc' --include 'wrangler.toml'
```

### B2 — Bump them all to today's-or-near date

Use the latest *released* compat date — check Cloudflare's docs (or the most recent release notes) for the right value. **Don't** invent a future date.

```jsonc
"compatibility_date": "<YYYY-MM-DD>",
```

If a Worker uses `compatibility_flags`, leave them as-is (they're orthogonal to the date).

### B3 — Verify each Worker boots

```bash
for w in $(ls apps); do   # or name the Workers you actually touched
  echo "=== $w ==="
  pnpm --filter @cdlab/$w dev &  # or run sequentially and curl
  sleep 3
  pkill -f "wrangler dev"
done
```

Or simpler: `pnpm build` at the root, then spot-boot 1-2 Workers manually.

### B4 — Commit

```
chore(workers): bump wrangler compatibility_date to <YYYY-MM-DD>
```

---

## Sub-flow C: Single-app dep change

### C1 — Decide where

- **Already in the catalog?** Use `"<dep>": "catalog:prod|dev"` in the app's `package.json`. Don't add a literal version.
- **Not in the catalog, but multiple apps will likely use it?** Add it to the catalog *first*, then reference `catalog:*`.
- **Truly app-local?** Pin the literal version in just that app's `package.json`. Mark it as a `dependencies` if it ships at runtime, `devDependencies` otherwise.

### C2 — Install and verify

```bash
pnpm --filter @cdlab/<app-name> add <dep>             # or `add -D <dep>` for devDependency
pnpm --filter @cdlab/<app-name> typecheck
pnpm --filter @cdlab/<app-name> build
```

If pnpm complains about `WARN catalogs vs literal version`, you set the wrong location — fix it.

### C3 — Commit

```
chore(<app>): add <dep> for <reason>
```

or

```
feat(<app>): use <dep> to <do thing>
```

If the dep enables a feature, the commit type is `feat`, not `chore`.

---

## Cross-cutting: when a Major bump lands

A Major bump (e.g. zod v3 → v4, drizzle, hono) usually requires code changes across multiple consumers. Treat it as a small refactor PR:

1. Bump the catalog version on a feature branch.
2. Run `pnpm install`. Note every typecheck failure.
3. Fix consumers one by one, commit per consumer (`refactor(<app>): adapt to <dep> v<N>`).
4. Final commit: `chore(deps): bump <dep> to v<N>` referencing the prep commits.

Don't squash the prep commits into the bump itself — keeping them separate lets reviewers diff each consumer change independently.

## Common pitfalls

- Bumping `react` and `next` separately — bump together, after checking the next release supports the new react.
- Major bumping `tsdown` / `vitest` without reading release notes — config shape (`tsdown.config.ts`) often changes.
- Bumping `typescript` Major alone — rerun `pnpm --filter @cdlab/tsconfig build` and verify each shared config still parses.
- New `compatibility_date` may implicitly flip a `compatibility_flags` default — diff the Cloudflare release notes for the date you're bumping to.
