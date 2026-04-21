#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
ROOT="$(repo_root)"
SHARED="$ROOT/skills/_shared/_provider-allowlist.sh"
[[ -f "$SHARED" ]] || fail "shared allow-list file missing at $SHARED"

# shellcheck disable=SC1090
source "$SHARED" || fail "sourcing $SHARED failed"

[[ -n "${HARNESS_PROVIDER_WHITELIST_REGEX:-}" ]] \
  || fail "HARNESS_PROVIDER_WHITELIST_REGEX is not defined after sourcing shared allow-list"

declare -F harness_is_provider_call >/dev/null \
  || fail "harness_is_provider_call function is not defined after sourcing shared allow-list"

harness_is_provider_call "skills/_shared/call-codex.sh" \
  || fail "harness_is_provider_call rejected a well-formed skills/_shared/call-codex.sh invocation"

if harness_is_provider_call "ls -la"; then
  fail "harness_is_provider_call accepted 'ls -la' — allow-list not enforcing strict regex"
fi

pass "AC-C.3 happy — strict regex + provider-list enforcement wired via shared allow-list"
