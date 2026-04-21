#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/skills/execute/SKILL.md"
sec=$(md_section "$S" "## Phase 1")
hits=0
matched=()
for kw in 'HARNESS_PLN_PROVIDER' 'call-codex.sh' 'codex exec' 'preflight' 'loud-fail' 'fallback'; do
  if printf '%s\n' "$sec" | grep -qF "$kw"; then
    hits=$((hits+1))
    matched+=("$kw")
  fi
done
(( hits >= 4 )) || fail "Phase 1 lacks codex-provider specifics (hits=$hits/6; matched=[${matched[*]:-}])"
pass "AC-D.3 happy (hits=$hits/6; matched=[${matched[*]}])"
