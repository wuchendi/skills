# cdlab-projects

Personal maintenance skill for [`@cdlab/projects-monorepo`](https://github.com/WuChenDi/projects). Bundles flow-oriented playbooks + scaffolding templates so day-to-day work in the repo (or in a new repo cloning this style) lands consistently without re-deriving conventions every time.

Not designed to be a generic monorepo helper. Everything is anchored to the actual apps in the repo (baccarat, byplay-log, dropply-api/web, flnk, flox, wepush, …).

Covers scaffolding apps and shared packages, dependency/catalog upgrades, cross-app refactors, feature work, pre-PR self-review, and doc sync. `SKILL.md` is the router — see its intent table for what maps to which playbook.

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
