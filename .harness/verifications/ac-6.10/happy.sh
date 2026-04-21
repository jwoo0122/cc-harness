#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
F="$ROOT/README.md"
[[ -f "$F" ]] || fail "README.md missing"

LOW="$(tr '[:upper:]' '[:lower:]' < "$F")"

check_any() {
  local label="$1"; shift
  for p in "$@"; do
    if printf '%s' "$LOW" | grep -qE "$p"; then
      ok "P[$label] matched: $p"
      return 0
    fi
  done
  fail "principle coverage missing: $label"
}

check_all() {
  local label="$1"; shift
  for p in "$@"; do
    if ! printf '%s' "$LOW" | grep -qE "$p"; then
      fail "principle coverage missing: $label — required token regex: $p"
    fi
  done
  ok "P[$label] all tokens matched"
}

check_any "P1 self-confirmation" '\bself-confirmation\b' '\bconfirmation bias\b'
check_all "P2 interview+ambiguity" '\binterview\b' '\bambiguity\b'
check_all "P3 pre-arranged+verification" '\bpre-arranged\b' '\bverification\b'
check_any "P4 persist+cross-session" 'persist.*cross-session|persist.*across sessions|cross-session.*persist|across sessions.*persist'

if grep -qE '\(partial\)|\bpartial\b' "$F"; then
  grep -nE '\(partial\)|\bpartial\b' "$F" >&2
  fail "hedge adjective 'partial' / '(partial)' present"
fi
ok "no '(partial)' hedge"

pass "ac-6.10 happy PASS (all 4 principles, no hedge)"
