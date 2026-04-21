#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

SCRATCH="$(mk_scratch ac-6.4-edge)"
trap 'rm -rf "$SCRATCH"' EXIT

cat > "$SCRATCH/bq.md" <<'EOF'
# T
> some quoted line | with a pipe
> another quoted line | with a pipe
EOF

A="$(awk '
  BEGIN { in_fence=0; run=0; tables=0 }
  /^[[:space:]]*(`{3,}|~{3,})/ { in_fence = 1 - in_fence; run=0; next }
  {
    if (!in_fence && $0 ~ /^\|.*\|[[:space:]]*$/) { run++; if (run==2) tables++ } else { run=0 }
  }
  END { print tables }' "$SCRATCH/bq.md")"
if [[ "$A" != "0" ]]; then
  fail "edge: blockquote with pipes mis-counted as table ($A)"
fi
ok "blockquote pipes correctly ignored"

cat > "$SCRATCH/fenced.md" <<'EOF'
# T
```
| a | b |
|---|---|
| 1 | 2 |
```
EOF

B="$(awk '
  BEGIN { in_fence=0; run=0; tables=0 }
  /^[[:space:]]*(`{3,}|~{3,})/ { in_fence = 1 - in_fence; run=0; next }
  {
    if (!in_fence && $0 ~ /^\|.*\|[[:space:]]*$/) { run++; if (run==2) tables++ } else { run=0 }
  }
  END { print tables }' "$SCRATCH/fenced.md")"
if [[ "$B" != "0" ]]; then
  fail "edge: fenced table mis-counted ($B)"
fi
ok "fenced table correctly ignored"

cat > "$SCRATCH/real.md" <<'EOF'
# T
| a | b |
|---|---|
| 1 | 2 |
EOF
C="$(awk '
  BEGIN { in_fence=0; run=0; tables=0 }
  /^[[:space:]]*(`{3,}|~{3,})/ { in_fence = 1 - in_fence; run=0; next }
  { if (!in_fence && $0 ~ /^\|.*\|[[:space:]]*$/) { run++; if (run==2) tables++ } else { run=0 } }
  END { print tables }' "$SCRATCH/real.md")"
if [[ "$C" != "1" ]]; then
  fail "edge: real table miscounted (got $C, want 1)"
fi
pass "ac-6.4 edge PASS (blockquote, fences, real table all handled)"
