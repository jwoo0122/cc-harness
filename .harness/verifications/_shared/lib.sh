#!/usr/bin/env bash
# Shared helpers for .harness/verifications/ac-*/*.sh
# Sourced, never executed directly.

# --- reporters -------------------------------------------------------------
pass() { echo "PASS: $*"; exit 0; }
fail() { echo "FAIL: $*" >&2; exit 1; }
skip() { echo "SKIP: $*"; exit 0; }

# Backwards-compat alias used by some scripts.
ok() { echo "OK: $*"; }

# --- repo-root resolution --------------------------------------------------
repo_root() {
  git rev-parse --show-toplevel
}

harness_repo_root() {
  local src_dir="$1"
  (cd "$src_dir/../../.." && pwd)
}

# --- scratch helpers -------------------------------------------------------
mk_scratch() {
  local label="${1:-harness-ver}"
  mktemp -d "/tmp/${label}.XXXXXX"
}

cleanup_scratch() {
  local d="$1"
  case "$d" in
    /tmp/*) rm -rf "$d" ;;
    *) echo "refusing to rm outside /tmp: $d" >&2; return 1 ;;
  esac
}

# --- markdown section extraction (heading-anchored, no HTML markers) ------
# $1 = file, $2 = heading literal (e.g. "## Phase 5")
# Prints heading line + everything until the next top-level "## " heading (exclusive).
md_section() {
  local file="$1" heading="$2"
  awk -v h="$heading" '
    $0 == h { in_sec=1; print; next }
    in_sec && /^## / { exit }
    in_sec { print }
  ' "$file"
}

# --- token count approximation --------------------------------------------
# Whitespace-separated words, NOT BPE tokens. Used by AC-2.4 and shared with IMP
# so both sides use one definition. Documented in ac-2.4/README.md.
token_count() {
  if [[ $# -gt 0 ]]; then
    printf '%s' "$1" | wc -w | tr -d '[:space:]'
  else
    wc -w | tr -d '[:space:]'
  fi
}
