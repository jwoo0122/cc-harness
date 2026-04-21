#!/usr/bin/env bash
# PreToolUse hook for /explore — blocks mutating tools for the entire skill
# lifetime. Bash is allowed only for provider-call invocations matching the
# shared allow-list at skills/_shared/_provider-allowlist.sh.

set -euo pipefail

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null || echo "unknown")"
AGENT_TYPE="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("agent_type",""))' 2>/dev/null || echo "")"

# Bash provider-call whitelist — load shared allow-list
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || echo "")"
  SHARED="${CLAUDE_PLUGIN_ROOT:-}/skills/_shared/_provider-allowlist.sh"
  if [ ! -f "$SHARED" ]; then
    # Hook-relative fallback: derive plugin root from this script's own path.
    HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
    SHARED="$HOOK_DIR/../_shared/_provider-allowlist.sh"
  fi
  if [ -f "$SHARED" ]; then
    # shellcheck disable=SC1090
    source "$SHARED"
    if harness_is_provider_call "$COMMAND"; then
      exit 0
    fi
  fi
fi

# Otherwise: block (existing behavior — unchanged error text below for anyone
# who was trying Edit/Write/Bash before).

cat >&2 <<EOF
BLOCKED: /explore is divergent (read-only) mode.
Tool blocked: ${TOOL_NAME}
Caller: ${AGENT_TYPE:-orchestrator}

This skill never writes code or runs shell commands. Use Read, Glob, Grep,
WebSearch, WebFetch only. Bash is blocked because it can mutate the filesystem
or repository state — defeating the read-only contract.

Exception: Bash commands matching .harness/scripts/call-<provider>.sh
(per skills/_shared/_provider-allowlist.sh) are permitted for provider-
dispatch scripts; all other Bash is blocked.

The output of /explore is a synthesis document the user reviews. To ship,
exit /explore and run /execute against acceptance criteria.

If you intended to save the synthesis itself, print it to the conversation
or hand the path to /execute as a one-line "save this document" criterion.
EOF
exit 2
