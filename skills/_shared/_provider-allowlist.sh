#!/usr/bin/env bash
# Shared provider allow-list for cc-harness hook scripts.
#
# Sourced by:
#   skills/execute/gate-mutating.sh  (execute-mode PreToolUse gate)
#   skills/explore/block-mutating.sh (explore-mode PreToolUse gate)
#
# Exposes:
#   HARNESS_PROVIDER_WHITELIST_REGEX — anchored regex for accepted provider-call
#     command strings.
#   harness_is_provider_call <command> — returns 0 on match, 1 otherwise.
#
# Policy:
#   - Baseline allowed providers: codex, gemini.
#   - Extendable at invocation time via `HARNESS_PROVIDERS=...` env
#     (space-separated lowercase [a-z]+ tokens). Invalid tokens silently dropped.
#   - If the final provider set is empty (e.g., baseline line edited out and no
#     env extension), the regex rejects ALL inputs. No fallback — deliberate
#     disable works.
#   - Tail after script path: optional whitespace + safe argv tokens only.
#     Safe chars in tokens: [A-Za-z0-9._/=-]. Shell metachars (&, |, ;, $,
#     backtick, >, <, parentheses, newlines, quotes) REJECTED.
#   - Trailing whitespace after the script path with no further tokens is OK.
#   - Suffix drift (call-evil.sh), path traversal (../), absolute paths all
#     rejected by the anchored regex structure.

# Baseline — can be commented out to fully disable (combined with empty HARNESS_PROVIDERS).
_harness_provider_baseline() {
  echo "codex gemini"
}

# Build provider list: baseline + env extension (validated).
_harness_providers() {
  local baseline
  baseline="$(_harness_provider_baseline)"
  local extra="${HARNESS_PROVIDERS:-}"
  local all="$baseline $extra"
  local out=()
  local p
  for p in $all; do
    if [[ "$p" =~ ^[a-z]{2,20}$ ]]; then
      out+=("$p")
    fi
  done
  # Deduplicate; empty → empty output
  if (( ${#out[@]} == 0 )); then
    return 0
  fi
  printf '%s\n' "${out[@]}" | sort -u | paste -sd'|' -
}

# Rebuild regex. If plist is empty, build an impossible-to-match pattern so
# harness_is_provider_call returns 1 for everything.
_harness_rebuild_regex() {
  local plist
  plist="$(_harness_providers)"
  if [[ -z "$plist" ]]; then
    # Impossible pattern: two anchors with nothing between → never matches a non-empty string.
    HARNESS_PROVIDER_WHITELIST_REGEX='a\Zb'
    return 0
  fi
  # Pattern:
  #   ^ \.harness/scripts/call-<plist>\.sh
  #   then optional: whitespace, with optional run of safe tokens separated by whitespace
  # Explicit regex (ERE via bash [[ =~ ]]):
  HARNESS_PROVIDER_WHITELIST_REGEX='^\.harness/scripts/call-('"$plist"')\.sh[[:space:]]*([A-Za-z0-9._/=-]+[[:space:]]*)*$'
}

_harness_rebuild_regex

# Public predicate. Re-evaluates HARNESS_PROVIDERS + baseline at call time.
harness_is_provider_call() {
  local cmd="${1:-}"
  _harness_rebuild_regex
  [[ "$cmd" =~ $HARNESS_PROVIDER_WHITELIST_REGEX ]]
}
