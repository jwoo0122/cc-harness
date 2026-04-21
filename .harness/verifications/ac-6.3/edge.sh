#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

SCRATCH="$(mk_scratch ac-6.3-edge)"
trap 'rm -rf "$SCRATCH"' EXIT

{
  echo "# Fake"
  echo ""
  echo "## Install"
  for i in $(seq 1 18); do echo "line $i"; done
  echo "## Next"
  echo "irrelevant"
} > "$SCRATCH/fake.md"

ln="$(grep -nE '^##+ Install\b' "$SCRATCH/fake.md" | head -1 | cut -d: -f1)"
next="$(awk -v s="$ln" 'NR>s && /^##+ / {print NR; exit}' "$SCRATCH/fake.md")"
span=$(( next - ln ))
if (( span < 16 )); then
  fail "edge: counter undercounted synthetic 20-line block (got $span)"
fi
ok "synthetic 20-line Install block correctly measured at $span"

{
  echo "# Fake"
  echo ""
  echo "## Install"
  echo "Run this:"
  echo ""
  echo '`/plugin marketplace add foo/bar`'
  echo ""
  echo "## Next"
} > "$SCRATCH/fake2.md"

ln="$(grep -nE '^##+ Install\b' "$SCRATCH/fake2.md" | head -1 | cut -d: -f1)"
next="$(awk -v s="$ln" 'NR>s && /^##+ / {print NR; exit}' "$SCRATCH/fake2.md")"
span=$(( next - ln ))
if (( span > 15 )); then
  fail "edge: counter overcounted synthetic 5-line block (got $span)"
fi
pass "ac-6.3 edge PASS (heading-bounded and blank-bounded spans measured correctly)"
