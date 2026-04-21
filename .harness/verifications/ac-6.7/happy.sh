#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
PJ="$ROOT/.claude-plugin/plugin.json"
MJ="$ROOT/.claude-plugin/marketplace.json"
[[ -f "$PJ" && -f "$MJ" ]] || fail "manifest(s) missing"

PDESC="$(jq -r '.description' "$PJ")"
MDESC="$(jq -r '.plugins[0].description' "$MJ")"
[[ "$PDESC" != "null" && -n "$PDESC" ]] || fail "plugin.description missing"
[[ "$MDESC" != "null" && -n "$MDESC" ]] || fail "marketplace.description missing"

for bad in "3-persona" "3-role" "self-affirmation bias"; do
  if printf '%s' "$PDESC" | grep -qiF "$bad"; then
    fail "forbidden '$bad' present in plugin.description"
  fi
done
ok "plugin.description substring-clean"

bigrams() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9 \n-' ' ' \
    | awk '{
        for (i=1; i<NF; i++) print $i "_" $(i+1)
      }' \
    | sort -u
}

PB="$(bigrams "$PDESC")"
MB="$(bigrams "$MDESC")"
SHARED="$(comm -12 <(printf '%s\n' "$PB") <(printf '%s\n' "$MB"))"
SHARED_N="$(printf '%s\n' "$SHARED" | grep -c . || true)"

ok "shared bigrams: $SHARED_N"
printf '%s\n' "$SHARED" | sed 's/^/  /' || true

if (( SHARED_N < 2 )); then
  fail "need ≥ 2 shared bigrams; got $SHARED_N"
fi

pass "ac-6.7 happy PASS (shared_bigrams=$SHARED_N)"
