# Documentation Sync Playbook

Use this when a change is **architecturally meaningful** and the docs need to follow. The goal is to keep `CLAUDE.md` (and to a smaller extent the README) accurate enough that a future agent or contributor can rely on it.

## When does a change require a doc update?

**Yes**, update docs:

- New app added or removed
- New shared package added, renamed, or removed
- A cross-cutting convention changes (e.g. lint rule, naming pattern, branch policy)
- A new runtime / framework / build tool is introduced
- A deprecated pattern is officially retired (e.g. "we no longer use X anywhere")
- A non-obvious architectural decision worth recording (why `clearify` builds with `--webpack`)

**No**, leave docs alone:

- Renaming a variable, fixing a typo, internal refactor with no API change
- Adding a single component or store inside an existing app
- Bug fixes
- Style-only changes

When in doubt, ask: "would a future contributor be confused if this isn't documented?"

## Where to write

There are three audiences, three docs:

| File              | Audience                                | What it should contain                                                |
|-------------------|-----------------------------------------|------------------------------------------------------------------------|
| `CLAUDE.md`       | Future Claude / coding agents           | Architecture, conventions, gotchas. Terse, declarative, scannable.    |
| `README.md`       | Humans (showcasing the project)         | Marketing copy + per-app summaries with screenshots and live URLs.    |
| `apps/<x>/README.md` | Humans setting up that one app       | Specific run/deploy instructions for that app. Short.                 |

Most architectural changes update **`CLAUDE.md`**. README changes are usually only needed when an app's user-visible feature set changes, or when a new app/package is added.

## CLAUDE.md structure (canonical sections)

```
# CLAUDE.md
## Project Overview              — one-paragraph elevator pitch
## Commands                      — workspace-wide and per-app scripts
## Architecture                  — major subsection per family
   ### Cloudflare Workers (Hono backends)
      #### <app-name>            — entry, routes, key files, gotchas
   ### Next.js apps
      #### <app-name>            — same shape
   ### Nuxt 4 app
      #### <app-name>
   ### Shared packages
      #### @cdlab/<pkg>
## Conventions                   — lint, deps, i18n, IDs, soft-delete, API envelope, misc
```

When you add to it, **put the new content in the right section** — don't append at the bottom.

## How to write a CLAUDE.md entry

For a new app, write a `#### <app-name>` block matching the shape of its neighbors:

```
#### <app-name> — <one-line value prop>

Entry: `src/index.ts`. <One-paragraph architecture overview — what kind of app, what it does, what its top-level shape is.>

- `<key file>` — <why it matters in one line>
- `<another key file>` — <…>
- <Anything genuinely surprising — a workaround, a constraint, a "don't do X here" gotcha>
```

For a new convention under `## Conventions`, write a heading + 2-5 lines explaining what and why:

```
### <Convention name>

<What the rule is, in one sentence.> <When it applies / what it prevents in 1-2 more.>
```

## Tone and length rules

- **Terse, architectural, scannable** — bullet points, not prose.
- **Declarative, present tense** — "App X uses Y", not "We chose to use Y because...".
- **Name files and folders** — `src/durable-objects/game-room.ts` is more useful than "the game room module".
- **Mention gotchas explicitly** — if there's a workaround for a bug, write a comment-style line: "**Bug-fixed quirk** (see comment in `webSocketClose`): hibernation calls `webSocketClose` *after* the socket is already closed — never call `ws.close()` from there or it throws."
- **Don't repeat what code already says** — the CLAUDE.md is for things the code doesn't show: rationale, constraints, conventions, gotchas. Resist tutorial-style prose.

## Step 1 — Find the section to edit

```bash
grep -n '^####' CLAUDE.md          # quick app/package index
grep -n '^###' CLAUDE.md           # framework families and conventions sections
```

Confirm the new content slots into an existing section. If it doesn't, ask: am I adding the wrong kind of content, or is there genuinely a new top-level concern (rare)?

## Step 2 — Edit, don't rewrite

When updating an existing block, **edit the lines that drifted** — don't rewrite the whole section. The diff should be small and focused.

When you must rewrite (e.g. an app's architecture genuinely changed), keep the heading and the bullet structure of neighboring entries.

## Step 3 — Verify the edit

- Re-read the section end-to-end. Does it still parse as a coherent narrative?
- Is the new entry consistent in tone and depth with its neighbors?
- Are there any other places that reference the same thing? (Top-of-file table, "Conventions" section, README app list.)

```bash
grep -n '<the thing you changed>' CLAUDE.md README.md README.zh-CN.md
```

## Step 4 — README sync (only if user-visible)

`README.md` and `README.zh-CN.md` are paired. Updating one without the other is the most common doc bug.

If you added a new app that has a public URL or user-visible feature set:

1. Add a new `### <AppName>` section under `## Applications` with the same shape as its neighbors (intro line, public URL, 2-3 bullets, optional `<details><summary>Preview</summary>` block with image).
2. Mirror the addition in `README.zh-CN.md` — translate, don't just paste English.
3. If there's a top-of-README badge or table of contents listing apps, update it too.

## Step 5 — Commit shape

Doc-only commit:

```
docs: <what you updated and why, in 1 line>
```

Examples:

```
docs(claude): document new flnk route group
docs(readme): add ByTTS to applications list
docs(conventions): clarify catalog vs literal version policy
```

If the doc update is a tail on a feature commit, prefer keeping it in the same commit as the feature (so the doc never describes code that doesn't exist on that ref).

## When there is no CLAUDE.md yet

If the project is fresh and has no `CLAUDE.md`, offer to seed one. Use the canonical structure above. The minimum useful seed:

```
# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

<two-paragraph description of what this monorepo is, who uses it, what runtime families it spans>

## Commands

<workspace-wide pnpm/turbo scripts, then per-app convenience aliases>

## Architecture

<one section per app — keep terse>

## Conventions

<lint, deps, i18n, IDs, commits — copy from this skill's SKILL.md style cheatsheet, abbreviated>
```

Don't write the whole 300-line doc at once. Start with the skeleton + one app, and grow it as more apps land.

## Common pitfalls

- Editing `README.md` without `README.zh-CN.md` (or vice versa) — pair them.
- Restating what the code already says — CLAUDE.md is for what code can't show: rationale, constraints, gotchas.
- Leaving "Bug-fixed quirk" notes after the underlying bug is fixed — delete them when the workaround goes away.
- README sections describing planned features — README is shipped state only.
