# cdlab-projects

Personal maintenance skill for [`@cdlab/projects-monorepo`](https://github.com/WuChenDi/projects). Bundles flow-oriented playbooks + scaffolding templates so day-to-day work in the repo (or in a new repo cloning this style) lands consistently without re-deriving conventions every time.

Not designed to be a generic monorepo helper. Everything is anchored to the actual apps in the repo (baccarat, byplay-log, dropply-api/web, flnk, flox, SecureC, wepush, …).

## What it covers

| Intent                    | Reference                              |
|---------------------------|----------------------------------------|
| Scaffold a new app        | `references/new-app.md` + `assets/templates/{nextjs-app,worker-app,nuxt-app}` |
| Scaffold a shared package | `references/new-package.md` + `assets/templates/package` |
| Upgrade dependencies      | `references/deps-upgrade.md`           |
| Cross-app refactor        | `references/refactor.md`               |
| Add a feature to an app   | `references/new-feature.md`            |
| Review a change           | `references/code-review.md`            |
| Sync `CLAUDE.md` / README | `references/update-docs.md`            |

The shared technical baseline (`stack.md`, `conventions.md`) is loaded only when needed.

## Stack baked in

The cdlab projects baseline:

- pnpm workspaces with two catalogs (`prod`, `dev`)
- Turborepo with concurrency 50
- Biome (single quotes, no semicolons, `useImportType` separated, `noFloatingPromises`, `noTsIgnore`, zod `import * as z`)
- `@dotns/nsl` dev proxy (`http://<name>.localhost:3355`)
- Cloudflare Pages / Workers / D1 + Drizzle (`DB_TYPE=libsql|d1`)
- Next.js (App Router) for browser apps, Hono for Workers, Nuxt 4 for the dashboard
- `next-intl` (`en`/`zh`) by default
- Conventional Commits, English remote-visible metadata

## Install

```bash
claude --plugin-dir ./skills/misc/cdlab-projects
```

Triggers automatically when you say things like:

- "spin up a new worker / add a next app"
- "bump catalog / upgrade deps / roll wrangler compatibility_date"
- "sink this logic into packages/utils"
- "self-review before I open a PR / run lint"
- "update CLAUDE.md"

## Directory layout

```
cdlab-projects/
├── .claude-plugin/plugin.json
├── README.md
└── skills/cdlab-projects/
    ├── SKILL.md               # router + style cheatsheet
    ├── references/            # detailed playbooks (loaded on demand)
    └── assets/
        └── templates/         # minimal app/package skeletons
```

## License

MIT
