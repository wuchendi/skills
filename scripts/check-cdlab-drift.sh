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

# 1. Package scope — a rename here breaks every generated package.json.
upstream_scope=$(sed -n 's/.*"name": "\(@[^/]*\)\/.*/\1/p' "$ROOT/packages/tsconfig/package.json")
skill_scopes=$(grep -rhoE '@[a-z0-9-]+/' "$SKILL" | sort -u)
for s in $skill_scopes; do
  case "$s" in
    "$upstream_scope"/|@types/|@hono/|@next/|@nuxt/|@nuxtjs/|@vueuse/|@libsql/|@cloudflare/|@dotns/|@base-ui/|@tanstack/|@opennextjs/|@tailwindcss/) ;;
    *) report "unknown package scope '$s' (upstream uses '$upstream_scope/')" ;;
  esac
done

# 2. Referenced apps/packages that no longer exist upstream.
#    Two citation styles appear in the playbooks, both must be checked:
#      `apps/<name>/...` / `packages/<name>/...`   (explicit)
#      `<name>/src/...`                            (bare, e.g. byplay-log/src/index.ts)
names=$( (ls "$ROOT/apps"; ls "$ROOT/packages") | sort -u )
refs=$( { grep -rhoE '(apps|packages)/[a-zA-Z][a-zA-Z0-9_-]+' "$SKILL" | cut -d/ -f2
          grep -rhoE '\b[a-zA-Z][a-zA-Z0-9_-]{2,}/src/' "$SKILL" | cut -d/ -f1
        } | sort -u )
for ref in $refs; do
  grep -qx "$ref" <<<"$names" && continue
  # 'src' and the glob placeholders are not app names
  case "$ref" in src|apps|packages|'*'|'<name>'|'<app-name>'|'<pkg-name>') continue ;; esac
  report "references '$ref' — not in upstream apps/ or packages/"
done

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
for pj in "$SKILL"/skills/cdlab-projects/assets/templates/*/package.json; do
  while read -r dep ver; do
    [ -z "$dep" ] && continue
    case "$ver" in catalog:*|workspace:*) continue ;; esac
    grep -qx "$dep" <<<"$catalogued" \
      && report "$(basename "$(dirname "$pj")")/package.json pins '$dep': $ver but it is in the catalog"
  done < <(sed -n '/"\(dev\)\?[Dd]ependencies"/,/}/p' "$pj" \
           | sed -n 's/ *"\([^"]*\)": *"\([^"]*\)".*/\1 \2/p')
done

if [ "$drift" -eq 0 ]; then
  echo "no drift detected against $ROOT"
fi
exit "$drift"
