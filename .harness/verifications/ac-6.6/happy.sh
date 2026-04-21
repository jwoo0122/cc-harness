#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
F="$ROOT/.claude-plugin/marketplace.json"
[[ -f "$F" ]] || fail "marketplace.json missing"

DESC="$(jq -r '.plugins[0].description' "$F")"
[[ "$DESC" != "null" && -n "$DESC" ]] || fail "plugins[0].description is null or empty"

LEN=${#DESC}
ok "description length = $LEN chars (limit 200)"
if (( LEN > 200 )); then
  fail "marketplace description length $LEN exceeds 200"
fi

for bad in "3-persona" "3-role" "self-affirmation"; do
  if printf '%s' "$DESC" | grep -qiF "$bad"; then
    fail "forbidden substring '$bad' present in marketplace description"
  fi
  ok "no '$bad'"
done
pass "ac-6.6 happy PASS"
