# package template

Built (`tsdown`) workspace package skeleton in cdlab projects style.

## Placeholders to replace

| Placeholder              | Where it appears                        | Example                  |
|--------------------------|------------------------------------------|--------------------------|
| `__PKG_NAME__`           | `package.json`                           | `cache`                  |
| `__PKG_DESCRIPTION__`    | `package.json`                           | `Lightweight in-memory cache` |

```bash
cd packages/<pkg-name>
find . -type f \( -name '*.ts' -o -name '*.json' \) -exec \
  sed -i \
    -e "s/__PKG_NAME__/<pkg-name>/g" \
    -e "s/__PKG_DESCRIPTION__/<one-line description>/g" \
    {} +
```

## What the template ships

- `tsdown` build producing both ESM (`dist/index.mjs`) and CJS (`dist/index.cjs`) with `.d.mts` types
- `vitest` ready in `test/`
- TypeScript config extending `@cdlab/tsconfig/utils.json`
- `prepack` script that builds before publish (even though packages here are private)

## After creating

```bash
pnpm install                                       # `prepare` will build new package
pnpm --filter @cdlab/<pkg-name> typecheck
pnpm --filter @cdlab/<pkg-name> test
pnpm --filter @cdlab/<pkg-name> build
```

## Adding multiple entry points

If you need runtime-split entries (browser vs node), edit `tsdown.config.ts`:

```ts
entry: ['src/index.web.ts', 'src/index.node.ts']
```

Then update `package.json` `exports` with the `browser` / `node` / `default` conditions. See `@cdlab/uncrypto` as a reference.

## Consuming from an app

```jsonc
// apps/<consumer>/package.json
"dependencies": {
  "@cdlab/<pkg-name>": "workspace:*"
}
```

```ts
import { … } from '@cdlab/<pkg-name>'
```

After editing the package, rebuild it (`pnpm --filter @cdlab/<pkg-name> build` or `dev --watch`) so consumers see the new symbols.
