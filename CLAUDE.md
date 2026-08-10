# CLAUDE.md

Working notes for Claude when editing this repo. Read alongside `CONTEXT.md` for the shared vocabulary.

## What this repo is

A personal collection of **Claude Code plugins**, each shipping one or more **skills**. The repo is the source for `npx skills add wuchendi/skills`; it is not a runtime — code here is loaded by other Claude installations.

## Layout rules

```
skills/<category>/<plugin>/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json   # optional
└── skills/<skill>/
    ├── SKILL.md
    └── assets/ | references/   # optional
```

- One plugin per folder. One skill per plugin is the norm; multi-skill plugins are allowed but rare.
- Plugin folder name == plugin name == skill name (so the namespace prefix matches: `/<plugin>:<skill>`).
- `<category>` is one of `engineering/`, `productivity/`, `misc/`, `fun/`. Pick the most honest fit; do not invent a new category for a single skill.

## Categories — when to use which

- **engineering** — generic code-work methodology (TDD loops, debugging loops, architecture review). Reusable across any codebase.
- **productivity** — generic engineer workflow tools that aren't code-specific (output compression, interview-style requirement gathering).
- **misc** — project-specific or single-purpose tools. Anchored to one repo or one narrow scenario. `cdlab-projects` lives here because it only makes sense inside the cdlab `projects` monorepo.
- **fun** — non-engineering tools kept for play. `explain-words` lives here.

## Adding or editing a skill

1. Place the plugin under the right `<category>/`.
2. Register its path in `.claude-plugin/plugin.json` at the repo root.
3. The `SKILL.md` frontmatter `description` is the trigger contract — it must describe **when to fire** in concrete phrases the user is likely to say. Vague descriptions are the #1 reason a skill never gets used.
4. Keep `metadata.author`, `metadata.version`, `metadata.source` filled in.

## Versioning

**CalVer `YYYY.MM.DD`** (zero-padded). Skills are content, not stable APIs — date-based versions are honest about that and let users see freshness at a glance. Do not use SemVer.

When you change a skill, bump the date in **all three** places so they stay in sync:

- `skills/<category>/<plugin>/.claude-plugin/plugin.json` → `version`
- `skills/<category>/<plugin>/.claude-plugin/marketplace.json` → `metadata.version` (if present)
- `skills/<category>/<plugin>/skills/<skill>/SKILL.md` → frontmatter `metadata.version`

Multiple edits the same day reuse the same date — no suffix needed.

## Verifying changes

- `bash scripts/list-skills.sh` — should list every `SKILL.md`. If a skill is missing, the path or filename is wrong.
- `bash scripts/link-skills.sh` — symlinks every skill into `~/.claude/skills/` for local testing. Refuses to run if `~/.claude/skills` is itself a symlink back into this repo.
- `bash scripts/check-cdlab-drift.sh [path-to-projects]` — for `misc/cdlab-projects` only: flags references to apps/packages that upstream has renamed or retired, a stale worker `compatibility_date`, and literal versions that belong in the catalog. Run it before touching that skill. Skills anchored to a live repo go stale silently; this makes it visible.

## Style

- **English only** for everything that ships: `SKILL.md`, `references/*.md`, plugin metadata, commit messages, PR text. Claude routes skills semantically, so Chinese trigger phrases in a `description` add no real matching value over a clear English description — don't include them. Exception: locale-specific scaffolding files (e.g. `messages/zh.json`, native language names in a language selector) must stay in their native language since that *is* their purpose.
- The `fun/` category is exempt from the English rule — those skills can be in whatever language fits their output.
- No emojis in skill content unless the skill is generating user-facing output (e.g. `explain-words` cards).
- No mentions of AI tooling vendors (Claude / Anthropic / OpenAI / etc.) in commit messages or PR text.

## What not to add

- Tutorials, philosophy essays, or marketing copy in the root README. Keep it to: install, reference list, license.
- Per-skill READMEs that duplicate `SKILL.md`. The plugin's own README is fine if it adds installation context the SKILL doesn't cover.
- New top-level docs (`ARCHITECTURE.md`, `ROADMAP.md`, etc.) without an explicit reason. This repo is small; a sprawling doc tree hides the actual content.
