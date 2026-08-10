# nuxt-app template

Minimal Nuxt 4 (Vue 3) app skeleton in cdlab projects style. Deploys to Vercel by default.

## Placeholders to replace

| Placeholder              | Where it appears                        | Example                  |
|--------------------------|------------------------------------------|--------------------------|
| `__APP_NAME__`           | `package.json`                          | `repo-changelog`         |
| `__APP_DESCRIPTION__`    | `package.json`                          | `Release tracker`        |

```bash
cd apps/<app-name>
find . -type f \( -name '*.ts' -o -name '*.vue' -o -name '*.json' \) -exec \
  sed -i \
    -e "s/__APP_NAME__/<app-name>/g" \
    -e "s/__APP_DESCRIPTION__/<one-line description>/g" \
    {} +
```

## After creating

1. `pnpm install`
2. `pnpm --filter @cdlab/<app-name> dev` (boots at `http://<app-name>.localhost:3355`)

## Adding to the workspace

- Add `dev:<short>` to root `package.json`.
- **Important**: Nuxt apps run their own ESLint. Add `apps/<app-name>/**` to `biome.json` `files.includes` exclusions and don't add a `next` / `react` / `vue` lint domain override.
