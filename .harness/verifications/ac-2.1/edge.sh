#!/usr/bin/env bash
# AC-2.1 edge: hook-script immutability via SHA256 baseline diff.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BASELINE="$SCRIPT_DIR/baseline.sha256"

# shellcheck source=../_shared/lib.sh
source "$SCRIPT_DIR/../_shared/lib.sh"

[[ -f "$BASELINE" ]] || fail "baseline.sha256 missing at $BASELINE — spec bundle incomplete"

cd "$REPO_ROOT"

while IFS= read -r line; do
  path="${line#*  }"
  [[ -f "$path" ]] || fail "expected hook file missing: $path"
done < "$BASELINE"

if ! shasum -a 256 -c "$BASELINE" >/tmp/ac-2.1-edge.out 2>&1; then
  echo "--- hash mismatch ---"
  cat /tmp/ac-2.1-edge.out
  echo "--- current hashes ---"
  while IFS= read -r line; do
    path="${line#*  }"
    shasum -a 256 "$path"
  done < "$BASELINE"
  fail "AC-2.1 edge: hook script(s) mutated since baseline."
fi

pass "AC-2.1 edge: both hook scripts byte-identical to baseline."
