#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
D="$(repo_root)/docs/multi-provider-dispatch.md"
[[ -f "$D" ]] || fail "docs/multi-provider-dispatch.md missing"
# Required section markers (heading literal OR regex).
sections=(
  'overview|개요|Overview'
  'usage|사용법|HARNESS_PLN_PROVIDER'
  'failure[[:space:]]*mode|실패[[:space:]]*모드|Failure'
  'debug|디버그'
  'iter[[:space:]-]*5|roadmap|로드맵'
)
for re in "${sections[@]}"; do
  grep -qiE "$re" "$D" || fail "docs missing section matching /$re/"
done
pass "AC-E.1 happy"
