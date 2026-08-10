#!/usr/bin/env bash
# Report where the cdlab-projects skill has drifted from the upstream monorepo.
#
# The skill deliberately carries no copies of the workspace config (see
# references/stack.md), but its templates and playbooks still name real apps,
# packages and a wrangler compatibility_date. Those rot silently when upstream
# renames or retires something. This script surfaces that.
#
# Usage: check-cdlab-drift.sh [path-to-projects-monorepo]
#        CDLAB_ROOT=/path/to/projects check-cdlab-drift.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# whole plugin dir, not just skills/ — the README and marketplace.json name
# reference apps too, and go stale the same way
SKILL="$REPO/skills/misc/cdlab-projects"
ROOT="${1:-${CDLAB_ROOT:-/srv/work/projects}}"

if [ ! -d "$ROOT/apps" ]; then
  echo "upstream monorepo not found at: $ROOT" >&2
  echo "pass it as \$1 or set CDLAB_ROOT; or clone:" >&2
  echo "  git clone --depth 1 https://github.com/WuChenDi/projects /tmp/cdlab-ref" >&2
  exit 2
fi

drift=0
report() { drift=1; printf 'DRIFT  %s\n' "$1"; }

# Every workspace member's package.json, once — reused by several checks below.
upstream_pkgjson=$(ls "$ROOT"/apps/*/package.json "$ROOT"/packages/*/package.json 2>/dev/null)

# 1. Package scope — a rename here breaks every generated package.json.
#    The allowed set is derived from what upstream actually depends on, so a new
#    third-party scope upstream doesn't produce a false positive here.
upstream_scope=$(sed -n 's/.*"name": "\(@[^/]*\)\/.*/\1/p' "$ROOT/packages/tsconfig/package.json")
#    Docs count too: `@dotns/nsl` is a globally-installed CLI, so it appears in
#    upstream's CLAUDE.md but in nobody's dependencies.
known_scopes=$( { echo "$upstream_scope/"
                  # shellcheck disable=SC2086
                  grep -hoE '"@[a-z0-9-]+/' $upstream_pkgjson | tr -d '"'
                  git -C "$ROOT" grep -hoE '@[a-z0-9-]+/' -- '*.md' 2>/dev/null || true
                } | sort -u )
skill_scopes=$(grep -rhoE '@[a-z0-9-]+/' "$SKILL" | sort -u)
for s in $skill_scopes; do
  grep -qx "$s" <<<"$known_scopes" && continue
  report "unknown package scope '$s' (upstream uses '$upstream_scope/')"
done

# 2. Referenced apps/packages that no longer exist upstream.
#    Membership is decided by the presence of a package.json, NOT by the
#    directory existing: a retired app can leave a stale node_modules/ behind
#    (SecureC did exactly that after being merged into dropply) and a
#    directory-only check happily calls that alive.
#    Two citation styles appear in the playbooks, both must be checked:
#      `apps/<name>/...` / `packages/<name>/...`   (explicit)
#      `<name>/src/...`                            (bare, e.g. byplay-log/src/index.ts)
names=$(sed -E 's|.*/(apps\|packages)/([^/]+)/package\.json$|\2|' <<<"$upstream_pkgjson" | sort -u)
refs=$( { grep -rhoE '(apps|packages)/[a-zA-Z][a-zA-Z0-9_-]+' "$SKILL" | cut -d/ -f2
          grep -rhoE '\b[a-zA-Z][a-zA-Z0-9_-]{2,}/src/' "$SKILL" | cut -d/ -f1
        } | sort -u )
for ref in $refs; do
  grep -qx "$ref" <<<"$names" && continue
  # 'src' and the glob placeholders are not app names
  case "$ref" in src|apps|packages|'*'|'<name>'|'<app-name>'|'<pkg-name>') continue ;; esac
  report "references '$ref' — not a workspace member upstream"
done

# 2b. Cited source files that have moved or been deleted.
#     The playbooks send the agent to read specific files ("re-read
#     dropply-web/src/lib/crypto.ts before touching crypto"). Those rot
#     independently of the app still existing, so check each path.
while read -r path; do
  [ -z "$path" ] && continue
  owner=${path%%/*}
  # only paths under a known workspace member are checkable
  grep -qx "$owner" <<<"$names" || continue
  [ -e "$ROOT/apps/$path" ] || [ -e "$ROOT/packages/$path" ] \
    || report "cites '$path' — file does not exist upstream"
done < <(grep -rhoE '\b[a-zA-Z][a-zA-Z0-9_-]*/src/[a-zA-Z0-9_./-]+\.(ts|tsx|css)\b' "$SKILL" \
         | sed 's|^apps/||' | sort -u)

# 3. compatibility_date lag in the worker template.
tpl_date=$(grep -oE '"compatibility_date": *"[0-9-]+"' \
           "$SKILL/skills/cdlab-projects/assets/templates/worker-app/wrangler.jsonc" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)
up_date=$(grep -rhoE '"compatibility_date": *"[0-9-]+"' "$ROOT"/apps/*/wrangler.jsonc \
          | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort -r | head -1)
if [ -n "$tpl_date" ] && [ -n "$up_date" ] && [ "$tpl_date" != "$up_date" ]; then
  report "worker template compatibility_date $tpl_date < upstream $up_date"
fi

# 4. Literal versions in template package.json for deps that ARE in the catalog.
#    (A literal is fine when the dep isn't catalogued — that mirrors upstream.)
catalogued=$(sed -n "/^catalogs:/,/^[a-z]/p" "$ROOT/pnpm-workspace.yaml" \
             | grep -oE "^ +'?[@a-z0-9./-]+'?:" | tr -d " ':" | sort -u)
#    5. Literal versions that ARE legitimately outside the catalog (the Nuxt
#       deps) still go stale — compare them against what upstream pins.
for pj in "$SKILL"/skills/cdlab-projects/assets/templates/*/package.json; do
  tpl=$(basename "$(dirname "$pj")")
  while read -r dep ver; do
    [ -z "$dep" ] && continue
    case "$ver" in catalog:*|workspace:*) continue ;; esac
    if grep -qx "$dep" <<<"$catalogued"; then
      report "$tpl/package.json pins '$dep': $ver but it is in the catalog"
      continue
    fi
    # Not catalogued — upstream pins it literally too, so the versions should agree.
    # shellcheck disable=SC2086
    up_vers=$(grep -hoE "\"$dep\": *\"[^\"]+\"" $upstream_pkgjson \
              | sed -E 's/.*: *"([^"]+)"/\1/' | sort -u)
    [ -z "$up_vers" ] && continue
    grep -qxF "$ver" <<<"$up_vers" \
      || report "$tpl/package.json pins '$dep': $ver — upstream uses $(tr '\n' ' ' <<<"$up_vers")"
  done < <(sed -n '/"\(dev\)\?[Dd]ependencies"/,/}/p' "$pj" \
           | sed -n 's/ *"\([^"]*\)": *"\([^"]*\)".*/\1 \2/p')
done

if [ "$drift" -eq 0 ]; then
  echo "no drift detected against $ROOT"
fi
exit "$drift"
