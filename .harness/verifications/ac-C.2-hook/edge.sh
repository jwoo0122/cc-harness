#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
HOOK="$(repo_root)/skills/explore/block-mutating.sh"
probe() {
  local cmd="$1" expected="$2"
  local in="{\"tool_name\":\"Bash\",\"agent_type\":\"skp\",\"tool_input\":{\"command\":$(python3 -c "import json,sys;print(json.dumps(sys.argv[1]))" "$cmd")}}"
  set +e
  printf '%s' "$in" | "$HOOK" >/dev/null 2>/dev/null
  local rc=$?
  set -e
  [[ "$rc" == "$expected" ]] || fail "probe [$cmd] expected rc=$expected got $rc"
}
# exact call-codex.sh → allow
probe ".harness/scripts/call-codex.sh" 0
# with trailing newline/spaces → allow (common subprocess artifact)
probe ".harness/scripts/call-codex.sh  " 0
# absolute path → block (hook regex is relative)
probe "/home/user/.harness/scripts/call-codex.sh" 2
# ../ traversal → block
probe ".harness/scripts/../../evil/call-codex.sh" 2
# unknown provider name → block (C.3 tightens)
probe ".harness/scripts/call-evil.sh" 2
pass "AC-C.2 edge"
