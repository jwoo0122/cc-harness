#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"

portable_timeout() {
  local secs="$1"; shift
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout --preserve-status "$secs" "$@"
  elif command -v timeout >/dev/null 2>&1; then
    timeout --preserve-status "$secs" "$@"
  else
    perl -e '
      use strict; use warnings;
      my $secs = shift @ARGV;
      my $pid = fork() // die "fork: $!";
      if ($pid == 0) { exec @ARGV or exit 127; }
      local $SIG{ALRM} = sub { kill "TERM", $pid; sleep 1; kill "KILL", $pid; exit 124; };
      alarm $secs;
      waitpid($pid, 0);
      exit($? >> 8);
    ' "$secs" "$@"
  fi
}

ROOT="$(repo_root)"
SCRIPT="$ROOT/skills/_shared/call-codex.sh"
[[ -x "$SCRIPT" ]] || fail "call-codex.sh missing"
scratch=$(mk_scratch ac-D.2-adv)
trap "cleanup_scratch $scratch" EXIT

export PATH="/usr/bin:/bin"
unset OPENAI_API_KEY CODEX_API_KEY || true
set +e
printf 'plan\n' | "$SCRIPT" >"$scratch/out2" 2>"$scratch/err2"
rc2=$?
set -e
(( rc2 == 2 )) || fail "expected exit 2 (preflight), got $rc2"
grep -qE 'Codex[[:space:]]+preflight[[:space:]]+failed' "$scratch/err2" \
  || fail "exit-2 stderr not loud-branded"

export PATH="$scratch:/usr/bin:/bin"
cp "$HERE/../_shared/codex-stub/codex" "$scratch/codex"; chmod +x "$scratch/codex"
export CODEX_STUB_MODE=hang
export HARNESS_CODEX_TIMEOUT=1
export OPENAI_API_KEY="sk-faketest0000000000000000000000000000000000000000"
set +e
printf 'plan\n' | portable_timeout 10 "$SCRIPT" >"$scratch/out3" 2>"$scratch/err3"
rc3=$?
set -e
(( rc3 == 3 )) || fail "expected exit 3 (timeout), got $rc3"
grep -qiE 'timeout|timed out' "$scratch/err3" || fail "exit-3 stderr missing timeout warning"
sec=$(md_section "$ROOT/skills/execute/SKILL.md" "## Phase 1")
printf '%s\n' "$sec" | grep -qiE 'fall[[:space:]-]?back|claude[[:space:]]+pln' \
  || fail "Phase 1 does not bind exit 2/3 → Claude PLN fallback"
pass "AC-D.2 adversarial (rc2=$rc2 rc3=$rc3)"
