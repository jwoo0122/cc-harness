#!/usr/bin/env bash
# PreToolUse hook for /execute — gates mutating tools to the IMP subagent only.
# Allows Edit/Write/NotebookEdit when agent_type=imp; blocks otherwise
# (orchestrator, pln, ver, anything else). This enforces the role-separation
# iron law: only IMP writes code.
#
# Exception: Bash invocations of provider-call scripts
# (.harness/scripts/call-<provider>.sh) are permitted from any agent_type so
# that PLN / VER / the orchestrator can consult external providers. The
# allow-list is defined by the shared file
# skills/_shared/_provider-allowlist.sh (sourced at runtime so edits to the
# list take effect without modifying this hook).

set -euo pipefail

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null || echo "unknown")"
AGENT_TYPE="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("agent_type",""))' 2>/dev/null || echo "")"

# IMP always allowed (iron law).
if [ "$AGENT_TYPE" = "imp" ]; then
  exit 0
fi

# Bash provider-call whitelist — sourced from shared allow-list file.
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || echo "")"
  SHARED="${CLAUDE_PLUGIN_ROOT:-}/skills/_shared/_provider-allowlist.sh"
  if [ ! -f "$SHARED" ]; then
    # Fallback: resolve relative to this hook's location (repo layout:
    # skills/execute/gate-mutating.sh -> skills/_shared/_provider-allowlist.sh).
    HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
    SHARED="$HOOK_DIR/../_shared/_provider-allowlist.sh"
  fi
  if [ -f "$SHARED" ]; then
    # shellcheck disable=SC1090
    source "$SHARED"
    if declare -F harness_is_provider_call >/dev/null 2>&1; then
      if harness_is_provider_call "$COMMAND"; then
        exit 0
      fi
    fi
  fi
fi

cat >&2 <<EOF
BLOCKED: /execute restricts mutating tools to the IMP subagent.
Tool blocked: ${TOOL_NAME}
Caller: ${AGENT_TYPE:-orchestrator}

In /execute, only the 'imp' subagent may use Edit/Write/NotebookEdit.
Exception: Bash commands matching the provider allow-list
(.harness/scripts/call-<provider>.sh) are permitted for all agent types.

The orchestrator dispatches IMP via the Agent tool with subagent_type="imp"
and a tightly scoped prompt (single increment, named files only).

If you are the orchestrator and need to make code changes, dispatch IMP.
If you are PLN or VER, you are out of role — surface the need and let the
orchestrator dispatch IMP.
EOF
exit 2
