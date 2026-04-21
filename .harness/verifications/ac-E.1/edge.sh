#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
D="$(repo_root)/docs/multi-provider-dispatch.md"
# Need a code fence containing HARNESS_PLN_PROVIDER=codex.
awk '
/^[[:space:]]*```/ { in_fence=!in_fence; next }
in_fence && /HARNESS_PLN_PROVIDER[[:space:]]*=[[:space:]]*codex/ { found=1 }
END { exit(found?0:1) }
' "$D" || fail "docs missing a fenced example of HARNESS_PLN_PROVIDER=codex"
pass "AC-E.1 edge"
