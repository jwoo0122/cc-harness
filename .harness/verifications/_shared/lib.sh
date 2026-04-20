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
# Fence-aware: lines inside ``` or ~~~ code fences are not treated as headings,
# so fenced snippets containing "## " won't end the section.
md_section() {
  local file="$1" heading="$2"
  awk -v h="$heading" '
    BEGIN { in_fence = 0; in_sec = 0 }
    # Toggle fence state on lines that are exactly a code fence opener/closer,
    # optionally with leading whitespace and an info-string (language token).
    /^[[:space:]]*(`{3,}|~{3,})[[:space:]]*[[:alnum:]_+-]*[[:space:]]*$/ {
      in_fence = 1 - in_fence
      if (in_sec) print
      next
    }
    {
      if (in_fence) {
        if (in_sec) print
        next
      }
      if ($0 == h) { in_sec = 1; print; next }
      if (in_sec && /^## /) exit
      if (in_sec) print
    }
  ' "$file"
}

# --- forbidden-phrase detection (declaration-context aware) ----------------
# $1 = extended regex pattern, $2 = file
# Prints unguarded matches (FILENAME:LINENO:line). Exits 1 if any unguarded
# match exists, 0 otherwise. A match is "guarded" (ignored) if the same line
# also contains a declaration-context keyword such as "must not", "do not",
# "forbidden", "금지", "never", "shall not", "禁止", "no silent", "no auto",
# "no warn", "don't", "cannot".
grep_forbidden_phrase() {
  local pattern="$1" file="$2"
  awk -v pat="$pattern" '
    BEGIN {
      # declaration-context keywords (lowercased for tolower() comparison)
      ncount = split("must not|do not|forbidden|금지|never|shall not|禁止|no silent|no auto|no warn|don\47t|don’t|cannot|should not|may not", negs, "|")
      found = 0
    }
    {
      line_lower = tolower($0)
      if (match(line_lower, tolower(pat))) {
        guarded = 0
        for (i = 1; i <= ncount; i++) {
          if (index(line_lower, negs[i]) > 0) {
            guarded = 1
            break
          }
        }
        if (!guarded) {
          print FILENAME ":" NR ":" $0
          found = 1
        }
      }
    }
    END { exit (found ? 1 : 0) }
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
