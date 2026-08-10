# worker-app template

Cloudflare Worker (Hono + optional Drizzle) skeleton in cdlab projects style.

## Placeholders to replace

| Placeholder              | Where it appears                                     | Example replacement                |
|--------------------------|------------------------------------------------------|------------------------------------|
| `__APP_NAME__`           | `package.json`, `wrangler.jsonc`                     | `byplay-log`                       |
| `__APP_DESCRIPTION__`    | `package.json`, `src/index.ts` welcome JSON          | `Player log monitor`               |
| `__DB_NAME__`            | `wrangler.jsonc`, `package.json` `db:*` scripts      | `byplay`                           |

```bash
cd apps/<app-name>
find . -type f \( -name '*.ts' -o -name '*.json' -o -name '*.jsonc' -o -name '*.example' \) -exec \
  sed -i \
    -e "s/__APP_NAME__/<app-name>/g" \
    -e "s/__APP_DESCRIPTION__/<one-line description>/g" \
    -e "s/__DB_NAME__/<db-name>/g" \
    {} +
```

## DB or no DB?

The template ships with the **Drizzle (libsql + d1) two-dialect setup**. If your worker doesn't need a database, delete:

- `drizzle.config.ts`
- `src/database/`
- `src/lib/db.ts`
- The `db:*`, `cf:localdb`, `cf:remotedb` scripts in `package.json`
- `drizzle-orm`, `drizzle-kit`, `@libsql/client` from `package.json` deps
- The `d1_databases` block and `LIBSQL_*` / `CLOUDFLARE_*` vars in `wrangler.jsonc`

## After creating

```bash
pnpm install
pnpm --filter @cdlab/<app-name> cf-typegen      # generate CloudflareBindings type
pnpm --filter @cdlab/<app-name> typecheck
pnpm --filter @cdlab/<app-name> dev
```

## Adding to the workspace

1. Add `dev:<short>` (and optionally `deploy:<short>`) aliases to root `package.json`.
2. No Biome override needed — Workers use the recommended-off baseline.
3. If using D1: create the database via Cloudflare dashboard or `wrangler d1 create __DB_NAME__`, paste the ID into `wrangler.jsonc`, then `pnpm db:gen && pnpm cf:localdb`.
