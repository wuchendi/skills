# Code Review Playbook (cdlab layer)

Pre-commit / pre-PR self-review for the cdlab `projects` monorepo. Use when the user asks for a self-review, sanity-check, or pre-PR pass on their own branch.

> **First**, run the generic methodology from the [`pre-pr-review`](https://github.com/WuChenDi/skills/tree/main/skills/engineering/pre-pr-review) skill — diff pull, surface-area scan, X-implies-Y missing-co-changes detection, green/yellow/red verdict format. **Then** apply the cdlab-specific layers below.

> If the diff touches React or Next code, also run [`react-best-practices`](https://github.com/WuChenDi/skills/tree/main/skills/engineering/react-best-practices) over it. The recurring misses in this repo are §3 `api-*`: a write that only invalidates the list it came from (`api-mutation-invalidate`), a `queryKey` missing a param the `queryFn` reads (`api-query-key-factory`), and an unbounded search key firing per keystroke (`api-stable-query-key`).

This file only documents what's specific to this monorepo. The generic logic lives in `pre-pr-review`.

## cdlab-specific automated layer

Run in this order; stop on first hard failure and fix the root cause:

```bash
pnpm lint:biome                                          # root, full repo
pnpm --filter @cdlab/<changed-pkg-or-app> typecheck   # per touched workspace
pnpm --filter @cdlab/<changed-pkg-or-app> lint        # if app has its own lint
pnpm --filter @cdlab/<changed-pkg-or-app> test        # if tests exist
pnpm --filter @cdlab/<changed-pkg-or-app> build       # final smoke
```

Turbo skips unaffected packages, so multi-filter runs are cheap.

If the change touches this skill itself (not the monorepo), also run `bash scripts/check-cdlab-drift.sh` from the skills repo — it catches references to apps that upstream has retired.

If a Biome rule fails, **fix the code, not the rule**. Don't add `// biome-ignore` lines unless there's a genuine reason (and write the reason in the comment).

## cdlab-specific style checks

Walk the diff against the **§Style cheatsheet in `SKILL.md`** — it's already in context, and it's the single source for these rules. Biome catches most of them, but not the ones that are conventions rather than lint rules (naming, package metadata, dev-script shape).

## cdlab-specific dependency checks

- [ ] No new literal version pin for a dep that already lives in the catalog (`pnpm-workspace.yaml`).
- [ ] If a dep is added to one app's `package.json`, would another app likely want it too? If yes, promote to catalog now.
- [ ] Cross-package import uses `"@cdlab/<name>": "workspace:*"`, not a literal version.
- [ ] If a `packages/*` library was edited, was it rebuilt? (`pnpm prepare` or per-package `build`.)

## cdlab-specific architecture checks

- [ ] New code lives in the right layer (Workers: `src/routes/` `src/lib/` `src/cron/`; Next: `src/components/<feature>/` `src/stores/<feature>-store.ts` `src/lib/`).
- [ ] No app-specific logic leaked into `packages/utils` or `packages/ui` (they stay app-agnostic).
- [ ] No duplicated helper that already exists in `@cdlab/utils` / `@cdlab/ui`.
- [ ] If a Worker touches the DB: filtered by `eq(table.isDeleted, 0)`. **Never** `db.delete()` — soft-delete on writes.
- [ ] If a Next app uses i18n (next-intl): every new string has keys in **both** `messages/en.json` and `messages/zh.json`.
- [ ] New env vars declared in `wrangler.jsonc` `vars` (with placeholder), `.env.example`, and `src/types.ts` if the app has a typed `createConfig`.

## cdlab-specific X-implies-Y patterns

When walking the Step 4 missing-co-changes scan from `pre-pr-review`, check these cdlab-specific pairs:

- New app added → `biome.json` `overrides` updated? Otherwise Biome silently skips lint domain rules for that app.
- New i18n string in `en.json` → mirror in `zh.json`? (Or vice versa — broken locale at runtime if missing.)
- New deps in `package.json` → actually used somewhere? Bloat otherwise.
- Drizzle schema edited → `pnpm db:gen` run? Migration missing → prod will crash.
- New Worker route file → registered in `src/routes/index.ts`? 404 in prod otherwise.
- New CF binding (KV / D1 / AI / DO) added in code → declared in `wrangler.jsonc`? Runtime error otherwise.
- Significant architectural change → `CLAUDE.md` updated? Drift starts here.

## cdlab-specific commit conventions

- Subject in **Conventional Commits** form (`feat`, `fix`, `chore`, `refactor`, `docs`, `build`, `test`).
- Scope (when meaningful) is the app or package: `feat(flnk): …`, `chore(deps): …`.
- Subject imperative, English, ≤ 72 chars.
- **No mention of AI assistants / model names / `Co-authored-by` trailers** — git policy across this repo's history.

## cdlab-specific common pitfalls

- **Trusting a green typecheck** — typecheck doesn't catch missing migrations, missing i18n keys, missing wrangler bindings. The X-implies-Y scan above is exactly for these.
- **Suppressing a Biome rule** to silence a single warning — usually the warning is right.
- **Letting a Major bump sneak in via `pnpm install` mass-update** — read `pnpm-lock.yaml` diff for unexpected jumps.
- **Stamping a commit on top of unrelated staged changes** — `git diff --staged` before commit, every time.
