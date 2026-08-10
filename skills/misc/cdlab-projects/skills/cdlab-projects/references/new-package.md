# New Package Playbook

Use this when the user wants to add a new shared package under `packages/`.

## When to make a new package vs. extend an existing one

Default to **extending an existing package** unless you have a clear reason:

- New helper that's logically generic → `@cdlab/utils` (add a module, re-export from `src/index.ts`)
- New shadcn/ui component or hook → `@cdlab/ui` (drop the file in `src/components/` or `src/hooks/`; consumers import via subpath)
- New TypeScript config preset → `@cdlab/tsconfig` (add a JSON file extending `base.json`)
- Crypto primitive used in multiple apps → `@cdlab/cipher`

Make a **new package** only when:

- The functionality has a distinct surface area that doesn't fit any existing one (e.g. a new domain like "feature flags", "tracing", "image-pipeline").
- It has a sensible standalone semver story (you'd want to publish it, even if you don't actually publish to npm).
- Bundling it into an existing package would force consumers to drag in unrelated dependencies.

If unsure, ask the user once: "Standalone package, or just a new submodule inside `utils`?"

## Step 1 — Pick a build profile

Two profiles cover almost every case:

| Profile             | When to pick                                                                | Template                        |
|---------------------|-----------------------------------------------------------------------------|---------------------------------|
| **Built (`tsdown`)** | Library code consumed by Workers/Node and browsers; needs a `dist/` ship   | `assets/templates/package`      |
| **Source-only**     | React UI library or hooks, where consumers want raw TSX (like `@cdlab/ui`) | (no template — mirror `packages/ui` if it exists) |

Default is **built**. Ask only if it's not obvious.

## Step 2 — Copy and rename

```bash
cp -r <skill-path>/assets/templates/package/. packages/<pkg-name>/
cd packages/<pkg-name>
# Replace placeholders inside files. The template README lists them.
#   __PKG_NAME__         → <pkg-name>
#   __PKG_DESCRIPTION__  → "<one-line>"
```

The package name is `@cdlab/<pkg-name>` (kebab-case, no `pkg` suffix or similar — just the bare name).

## Step 3 — Decide entry points

Open `tsdown.config.ts` and set `entry`:

- **Single entry** (most cases): `entry: ['src/index.ts']`. Consumers `import { … } from '@cdlab/<name>'`.
- **Multiple entries** (runtime-split, e.g. `crypto.node.ts` / `crypto.web.ts` like `uncrypto`): list them all and configure `exports` in `package.json` with `browser` / `node` / `default` conditions.
- **Subpath exports** (like `utils/format`, `utils/download`): list each entry and add a matching `exports` map.

Match the `package.json` `main` / `module` / `types` / `browser` fields to whatever the `exports` map says. If `exports` is set, `main` / `module` are mostly there for legacy resolvers.

## Step 4 — TypeScript config

The template extends `@cdlab/tsconfig/utils.json`. If the package is React-flavored, switch to `@cdlab/tsconfig/react-library.json` instead.

```jsonc
{
  "extends": "@cdlab/tsconfig/utils.json",
  "include": ["."],
  "exclude": ["node_modules", "dist"]
}
```

Keep `include: ["."]` — it lets vitest pick up `test/**` without extra configuration.

## Step 5 — Tests

`vitest` is the standard. The template ships a `test/` folder and a `test:watch` script. If the package is browser-only, add `happy-dom` to the catalog and configure vitest with `environment: 'happy-dom'`.

## Step 6 — Wire into the workspace

1. **Catalog deps**: same rule as new apps — anything already in `pnpm-workspace.yaml` references `catalog:*`.
2. **Add to `pnpm prepare`**: it already runs `turbo run build --filter=./packages/*`, so a new package is picked up automatically *if* it has a `build` script. Make sure it does (the template provides `build: "tsdown"`).
3. **Topological build order**: Turbo handles this via the `^build` `dependsOn`. The package's own dependencies on other workspace packages should be declared via `workspace:*` so Turbo orders builds correctly.

## Step 7 — Install, build, test

```bash
pnpm install                                   # `prepare` will build the new package
pnpm --filter @cdlab/<pkg-name> typecheck
pnpm --filter @cdlab/<pkg-name> test
pnpm --filter @cdlab/<pkg-name> build       # explicit, to verify dist/ is correct
```

Open `dist/` and check the entry shapes match `exports` in `package.json`. A wrong `dist/` layout is the most common bug here.

## Step 8 — Use it from an app

Once published into the workspace, an app consumes it via:

```jsonc
// apps/<app>/package.json
"dependencies": {
  "@cdlab/<pkg-name>": "workspace:*"
}
```

Then `import { … } from '@cdlab/<pkg-name>'`. After editing the package, rebuild it (`pnpm --filter @cdlab/<pkg-name> build` or `dev --watch`) so consumers see the new symbols.

## Step 9 — Update CLAUDE.md (if it exists)

Add a `#### @cdlab/<pkg-name>` subsection under `### Shared packages` describing:

- Public API (named exports / classes)
- Whether it's built (`tsdown`) or source-only
- Any notable runtime constraints (browser-only, Node-only, dual)
- Which apps consume it (only if the count is small and informative)

Don't dump the full README in there — keep it terse and architectural.

## Common pitfalls

- Missing `build` script — `pnpm prepare` skips the package, consumers fail to resolve.
- Mismatched `exports` and `main` — bundlers may pick the legacy `main` and miss conditional exports. Set both consistently.
- Runtime deps in `devDependencies` — consumers won't install them.
- Suffixed names like `@cdlab/<name>-utils` — drop the suffix, use the bare `@cdlab/<name>`.
