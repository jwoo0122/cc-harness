#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
S="$(repo_root)/skills/execute/SKILL.md"
sec=$(md_section "$S" "## Phase 1")
echo "$sec" >/tmp/ac-D.1-phase1.$$
trap 'rm -f /tmp/ac-D.1-phase1.$$' EXIT
# Within a 5-line sliding window, we need: a conditional keyword + the env var + 'codex'.
found=0
awk '
{ buf[NR]=$0 }
NR>=5 {
  window=""
  for(i=NR-4;i<=NR;i++) window = window "\n" buf[i]
  if (match(tolower(window),/if|else|when|만약|조건/) \
      && index(window,"HARNESS_PLN_PROVIDER") \
      && match(tolower(window),/codex/)) {
    print "HIT"; exit
  }
}' /tmp/ac-D.1-phase1.$$ | grep -q HIT && found=1
(( found == 1 )) || fail "Phase 1 does not express HARNESS_PLN_PROVIDER=codex as a conditional branch"
pass "AC-D.1 edge"
