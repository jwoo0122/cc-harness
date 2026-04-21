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

SCRIPT="$(repo_root)/skills/_shared/call-codex.sh"
scratch=$(mk_scratch ac-B.3-edge)
trap "cleanup_scratch $scratch" EXIT
cp "$HERE/../_shared/codex-stub/codex" "$scratch/codex"
chmod +x "$scratch/codex"
export PATH="$scratch:$PATH"
export OPENAI_API_KEY="sk-faketest0000000000000000000000000000000000000000"
export CODEX_STUB_MODE=hang
export HARNESS_CODEX_TIMEOUT=1
start=$(date +%s)
set +e
printf 'plan\n' | portable_timeout 10 "$SCRIPT" >"$scratch/out" 2>"$scratch/err"
rc=$?
set -e
elapsed=$(( $(date +%s) - start ))
(( rc == 3 )) || fail "expected exit 3 on timeout, got $rc"
(( elapsed < 10 )) || fail "timeout took $elapsed s (>=10 s) — not honored"
grep -qiE 'timeout|timed out' "$scratch/err" || fail "stderr missing timeout warning"
pass "AC-B.3 edge (rc=$rc elapsed=${elapsed}s)"
