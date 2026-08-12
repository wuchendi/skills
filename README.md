# Skills

A personal collection of reusable **Claude Code Plugins / Skills**.

## Install

Use the `skills` CLI (open agent skills standard):

```bash
# Install all skills globally
npx skills add wuchendi/skills --global

# Install a specific skill globally
npx skills add wuchendi/skills --skill cdlab-projects --global
npx skills add wuchendi/skills --skill explain-words --global

# Install to the current project only (drop --global)
npx skills add wuchendi/skills

# List available skills
npx skills add wuchendi/skills --list
```

Or load a plugin directly from a local folder (useful during development):

```bash
claude --plugin-dir ./skills/fun/explain-words
```

After loading, skills are invoked with a **namespace prefix**:

```
/explain-words:explain-words Serendipity
```

## Reference

### Engineering

Stack-agnostic methodology skills. Compose with project-specific skills.

- **[pre-pr-review](./skills/engineering/pre-pr-review/skills/pre-pr-review/SKILL.md)** — Pre-commit / pre-PR self-review: pull the diff, scan for scope creep, walk a surface-area checklist, detect missing co-changes (X-implies-Y), render a green/yellow/red verdict.
- **[react-best-practices](./skills/engineering/react-best-practices/skills/react-best-practices/SKILL.md)** — 86 rules across 9 categories for React/Next.js, loaded one file at a time from an index: eliminating waterfalls, bundle size, server-side performance, re-renders, rendering, JS micro-optimizations, plus an API & data-layer section for TanStack Query (query keys, invalidation, `enabled` gating, infinite queries, SSR prefetch, optimistic updates).
- **[refactor-extract](./skills/engineering/refactor-extract/skills/refactor-extract/SKILL.md)** — Sink shared logic into a shared module: confirm worth extracting (≥2 callers, no caller-specific state), decide the shape, two-commit pattern (extract + migrate), verify per consumer.

### Misc

Project-specific or one-off tools — kept around but not generally applicable.

- **[cdlab-projects](./skills/misc/cdlab-projects/skills/cdlab-projects/SKILL.md)** — Maintenance skill for the cdlab `projects` monorepo: scaffold apps/packages, bump pnpm catalog and wrangler compat dates, refactor across apps, run pre-commit/PR self-review, sync `CLAUDE.md` / README. Layers cdlab-specific conventions on top of `pre-pr-review` and `refactor-extract`.
- **[ikui](./skills/misc/ikui/skills/ikui/SKILL.md)** — Find, install, and compose components and business blocks from the ikui registry (`@ikui`): a shadcn-style copy-paste React library for media/timeline editing UI (waveforms, thumbnail strips, timeline ruler/element/playhead, audio/video trimmers, image compare/crop). Installs via the shadcn CLI; pulls the live component manifest at load time.

### Fun

Tools for fun, not serious engineering work.

- **[explain-words](./skills/fun/explain-words/skills/explain-words/SKILL.md)** — Deconstruct an English word into etymology, semantics, nuance, and visual topology, then render a museum-quality HTML card.

## License

[MIT](./LICENSE) License © 2025-PRESENT [wudi](https://github.com/WuChenDi)
