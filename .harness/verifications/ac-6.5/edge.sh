#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

SCRATCH="$(mk_scratch ac-6.5-edge)"
trap 'rm -rf "$SCRATCH"' EXIT

cat > "$SCRATCH/fake.md" <<'EOF'
# Title
The harness separates roles.
```
# comment — I wrote this; we will iterate
echo "our test"
```
No pronouns outside the fence.
EOF

STRIPPED="$(awk '
  BEGIN { in_fence=0 }
  /^[[:space:]]*(`{3,}|~{3,})/ { in_fence = 1 - in_fence; next }
  { if (!in_fence) print }
' "$SCRATCH/fake.md")"

COUNT="$(printf '%s\n' "$STRIPPED" | grep -oiE '\b(I|we|our|my|us)\b' | wc -l | tr -d '[:space:]' || true)"

if (( COUNT != 0 )); then
  fail "edge: fence-aware stripping failed (got $COUNT, want 0)"
fi
ok "fenced pronouns correctly ignored"

cat > "$SCRATCH/fake2.md" <<'EOF'
# Title
We built this.
EOF
STRIPPED="$(awk 'BEGIN{in_fence=0} /^[[:space:]]*(`{3,}|~{3,})/{in_fence=1-in_fence; next} {if(!in_fence) print}' "$SCRATCH/fake2.md")"
COUNT="$(printf '%s\n' "$STRIPPED" | grep -oiE '\b(I|we|our|my|us)\b' | wc -l | tr -d '[:space:]' || true)"
if (( COUNT == 0 )); then
  fail "edge: prose 'We' not detected"
fi
pass "ac-6.5 edge PASS (fence-aware pronoun detection)"
