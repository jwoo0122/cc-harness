#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
HOOK="$(repo_root)/skills/execute/gate-mutating.sh"
[[ -x "$HOOK" ]] || fail "gate-mutating.sh missing"
declare -a attacks=(
  ".harness/scripts/../../evil/call-codex.sh"
  "skills/_shared/call-evil.sh"
  ".harness/scripts/cаll-codex.sh"
  ".harness/scripts/CALL-codex.sh"
  "skills/_shared/call-codex.sh; rm -rf /tmp/x"
  "skills/_shared/call-codex.sh && ls"
  "skills/_shared/call-codex.sh\$(id)"
)
fails=0
for cmd in "${attacks[@]}"; do
  in="{\"tool_name\":\"Bash\",\"agent_type\":\"pln\",\"tool_input\":{\"command\":$(python3 -c "import json,sys;print(json.dumps(sys.argv[1]))" "$cmd")}}"
  set +e
  printf '%s' "$in" | "$HOOK" >/dev/null 2>/dev/null
  rc=$?
  set -e
  if (( rc == 0 )); then
    echo "BYPASS PASSED (should have blocked): $cmd" >&2
    fails=$((fails+1))
  fi
done
(( fails == 0 )) || fail "$fails/${#attacks[@]} bypass attempts succeeded"
pass "AC-C.3 adversarial (${#attacks[@]}/${#attacks[@]} blocked)"
