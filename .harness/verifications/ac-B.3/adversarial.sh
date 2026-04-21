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

SCRIPT="$(repo_root)/.harness/scripts/call-codex.sh"
grep -qE '\b60\b' "$SCRIPT" || fail "default 60s timeout literal missing from call-codex.sh"
scratch=$(mk_scratch ac-B.3-adv)
trap "cleanup_scratch $scratch" EXIT
cp "$HERE/../_shared/codex-stub/codex" "$scratch/codex"
chmod +x "$scratch/codex"
export PATH="$scratch:$PATH"
export OPENAI_API_KEY="sk-faketest0000000000000000000000000000000000000000"
export CODEX_STUB_MODE=hang

export HARNESS_CODEX_TIMEOUT=0
set +e
printf 'x\n' | portable_timeout 5 "$SCRIPT" >"$scratch/out0" 2>"$scratch/err0"
rc0=$?
set -e
if (( rc0 == 124 )); then
  [[ ! -s "$scratch/out0" ]] || fail "TIMEOUT=0 produced fake output before external kill"
else
  (( rc0 != 0 )) || fail "TIMEOUT=0 silently returned success"
  grep -qiE 'invalid|must be|>=|positive|clamp' "$scratch/err0" \
    || fail "TIMEOUT=0 rejected without explanation"
fi

export HARNESS_CODEX_TIMEOUT=-5
set +e
printf 'x\n' | portable_timeout 5 "$SCRIPT" >"$scratch/out1" 2>"$scratch/err1"
rc1=$?
set -e
(( rc1 != 0 )) || fail "negative timeout silently accepted"
pass "AC-B.3 adversarial (rc0=$rc0 rc1=$rc1)"
