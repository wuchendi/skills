---
name: refactor-extract
description: Sink shared logic from multiple call sites into a shared module (utils package, common helper, shared lib). Trigger when the user wants to "extract this", "DRY this up", "consolidate this duplication", "sink this into a shared package", "pull this out into utils", or otherwise move duplicated code from N call sites into one home. Walks — confirm worth extracting (≥2 callers, no caller-specific state), decide the shape, two-commit pattern (extract + migrate), verify per consumer, when to NOT refactor. Skip for in-app file reorganisation that doesn't cross a module/package boundary, and skip for shallow duplication (3 near-identical lines is not worth abstracting).
metadata:
  author: wudi
  version: "2026.08.09"
  source: https://github.com/WuChenDi/skills
---

# refactor-extract

Disciplined extraction of duplicated logic into a shared module. Stack-agnostic — applies to monorepos (`packages/*`), single-repo shared dirs (`src/lib/`, `internal/pkg/`), or language-level shared packages.

## Step 1 — Confirm it's worth extracting

Before moving anything, sanity-check three things. If any answer is "no", **abort and tell the user why**.

### ≥ 2 callers (or imminent ≥ 2)

If only one caller exists today, leave the code there. Premature shared modules are worse than duplication — you're paying the abstraction cost without anyone using it. Three or more callers is the comfortable trigger; two is borderline (extract only if the surface is stable).

> **Rule of thumb**: 3 near-identical lines is not duplication worth abstracting. 3 identical 30-line functions is.

### Stable surface

If the function shape is still churning across callers (different signatures, different return types, frequent refactors), wait. The shared API will churn just as much, and every callsite will pay the migration cost twice.

### No caller-specific state

The function must not reach into the caller's logger, config object, request context, store, ORM connection, or any other thing only the caller has. Either:

- Pass those dependencies in as **arguments** (the cleanest fix), or
- Keep the function local to the caller.

Extracting code that secretly depends on caller-specific state produces a "shared" module that only one caller can actually use.

## Step 2 — Decide the new shape *before* moving anything

Don't move files before you know the target structure. State out loud:

1. **What's the function name and signature?** (As if you're documenting it for a stranger.)
2. **Where does it live?** Pick the home up-front. If the project has existing capability folders (e.g. `utils/format/`, `utils/clipboard/`, `utils/download/`), reuse one when it fits; only create a new folder for a genuinely new capability.
3. **What does the public API expose?** The smallest surface that all callers need — nothing more. If 1 of 3 callers needs an extra option, add it as an argument, not an internal branch.

If you can't articulate these three in a sentence each, you don't understand the extraction yet — go back and read the call sites.

## Step 3 — Move and re-export (in this order)

1. Create the new file under the chosen home (e.g. `<shared-package>/src/<capability>/<name>.ts`).
2. **Add a test next to it.** If the project uses tests at all, the shared module is exactly where they pay off — multiple consumers, single source of truth.
3. Re-export from the package's barrel / public entry, so consumers can import it via the package's public API rather than reaching into internals.
4. Build the shared package if it has a build step. (Without this, consumers will pull stale `dist/`.)
5. In each consumer, replace the local copy with an import from the shared package.
6. Delete the now-unused local file.
7. Run typecheck per consumer to confirm no orphaned imports.

## Step 4 — Verify

```bash
# Shared package itself
<test-the-shared-package>
<build-the-shared-package>

# Each consumer
<typecheck-consumer-1>
<typecheck-consumer-2>
…

# Repo-wide smoke
<lint>
<build>
```

The exact commands depend on the project — check `CLAUDE.md` / scripts. **Do not skip typechecking each consumer individually**: a missed import path is the most common breakage in this kind of refactor.

## Step 5 — Commit shape

Two commits, in this order:

```
refactor(<shared-pkg>): extract <name> from <consumer-a>, <consumer-b>
refactor(<consumer-a>, <consumer-b>): consume <name> from <shared-pkg>
```

The first commit adds the new code + tests. The second deletes duplicates and switches imports. This makes review easier — the reviewer can verify the extraction is faithful before checking each migration.

If the diff is small and the project's culture allows, one commit is acceptable. Use judgment.

**Never bundle a behaviour change into the refactor.** If you "improve" the extracted version while moving it, you've made the diff impossible to review and the refactor un-bisectable. Land the move first; land any improvement as a separate commit.

## When to NOT refactor

Push back on the user if:

- They want to "clean up" code they didn't write and there's no concrete bug or hand-off pressure.
- The refactor would touch ≥ 5 files for a stylistic improvement (variable rename, file split). The cost of review usually exceeds the benefit.
- The duplication is shallow — three near-identical lines is not "duplication" worth abstracting.
- The "shared" abstraction would have a single caller after the move (you're moving code, not extracting).
- You can't satisfy Step 1's "no caller-specific state" check without contorting the API.

When in doubt, point at the duplication, name the cost (X files touched, Y test cases to verify, Z migration commits), and ask if it's worth doing now.

## Common pitfalls

- **Refactor + feature in the same commit.** Always split.
- **Sinking a helper that depends on the caller's logger / config / request context.** Pass deps in or keep it local.
- **Forgetting to rebuild the shared module** after editing — consumers pull stale `dist/` until you do.
- **Extracting too early** (1 caller, hoping a 2nd shows up) — the abstraction will be wrong because you only have one shape to learn from.
- **Extracting too late** (5+ callers diverged) — you'll have to reconcile divergent shapes during the extraction, doubling the work.
- **Inventing a fancier API while extracting** — keep the shape that callers already use; add cleverness in a follow-up if at all.

## Composing with project-specific extract skills

Project-specific skills (e.g. one that knows where a particular monorepo's `packages/utils` lives, what its naming conventions are, what test framework to use) should run **on top of** this skill, not duplicate it. Pattern:

1. This skill — confirm-extract decision, two-commit pattern, when-not-to.
2. Project skill — adds the actual paths, naming conventions, and verification commands.
