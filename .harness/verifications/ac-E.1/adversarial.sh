#!/usr/bin/env bash
# AC-E.1 adversarial: docs MUST document ALL FOUR AC-B.2 failure scenarios
# (missing binary, stale/absent API token, quota exceeded, network down).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
ROOT="$(repo_root)"
DOCS=()
for c in README.md docs/multi-provider-dispatch.md docs/README.md docs/troubleshooting.md; do
  [[ -f "$ROOT/$c" ]] && DOCS+=("$ROOT/$c")
done
(( ${#DOCS[@]} > 0 )) || fail "no candidate doc files found"

blob=$(cat "${DOCS[@]}" | tr '[:upper:]' '[:lower:]')

miss=()
echo "$blob" | grep -qE 'missing (binary|codex)|codex.*not (found|installed)|binary.*missing' \
  || miss+=("missing-binary")
echo "$blob" | grep -qE '(stale|absent|missing|invalid|expired).*(api[ _-]?key|token|openai_api_key)|(api[ _-]?key|token).*(stale|absent|missing|invalid|expired)' \
  || miss+=("stale/absent-api-token")
echo "$blob" | grep -qE 'quota|rate.?limit|429|throttl' \
  || miss+=("quota-exceeded")
echo "$blob" | grep -qE 'network|offline|no route|dns|connection (refused|reset|timed out)|unreachable' \
  || miss+=("network-down")

if (( ${#miss[@]} > 0 )); then
  fail "E.1 docs incomplete — all 4 B.2 scenarios required, missing: ${miss[*]}"
fi
pass "AC-E.1 adversarial (4/4 B.2 scenarios documented)"
