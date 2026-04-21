#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

SCRATCH="$(mk_scratch ac-6.10-edge)"
trap 'rm -rf "$SCRATCH"' EXIT

echo "Coverage is (partial)." > "$SCRATCH/a.md"
if ! grep -qE '\(partial\)|\bpartial\b' "$SCRATCH/a.md"; then
  fail "edge: '(partial)' not detected"
fi
ok "(partial) detected"

echo "This is partial." > "$SCRATCH/b.md"
if ! grep -qE '\(partial\)|\bpartial\b' "$SCRATCH/b.md"; then
  fail "edge: 'partial' word not detected"
fi
ok "bare 'partial' detected"

echo "This is partially-ordered." > "$SCRATCH/c.md"
if grep -qE '\bpartial\b' "$SCRATCH/c.md"; then
  fail "edge: 'partially' unexpectedly matched \\bpartial\\b"
fi
ok "'partially' correctly NOT matched (word-boundary works)"

for phrase in "persist across sessions" "cross-session persist" "persist cross-session" "across sessions persistence"; do
  echo "$phrase" > "$SCRATCH/p4.md"
  LOW="$(tr '[:upper:]' '[:lower:]' < "$SCRATCH/p4.md")"
  if ! printf '%s' "$LOW" | grep -qE 'persist.*cross-session|persist.*across sessions|cross-session.*persist|across sessions.*persist'; then
    fail "edge: P4 regex rejected valid phrasing: $phrase"
  fi
done
pass "ac-6.10 edge PASS"
