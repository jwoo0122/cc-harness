#!/usr/bin/env bash
# PreToolUse hook for /explore — blocks mutating tools for the entire skill
# lifetime, including subagents.
#
# Exception: Bash is permitted for Codex peer subagents (subagent_type starting
# with "codex"). /explore's SKP seat runs on codex:codex-rescue, which needs
# internal Bash to exec the codex CLI. Claude subagents (opt/pra/emp and any
# Claude fallback) remain blocked from Bash — they are strictly Read/Glob/Grep/
# WebSearch/WebFetch.
#
# Edit/Write/NotebookEdit are blocked for every caller (including Codex).
# /explore produces a synthesis document the orchestrator prints to the
# conversation; any file authorship belongs in /execute.

set -euo pipefail

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null || echo "unknown")"
AGENT_TYPE="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("agent_type",""))' 2>/dev/null || echo "")"

# Codex peer subagent Bash pass-through.
if [ "$TOOL_NAME" = "Bash" ]; then
  case "$AGENT_TYPE" in
    codex:*|codex-*)
      exit 0
      ;;
  esac
fi

cat >&2 <<EOF
BLOCKED: /explore is divergent (read-only) mode.
Tool blocked: ${TOOL_NAME}
Caller: ${AGENT_TYPE:-orchestrator}

This skill never writes code or runs arbitrary shell commands. Claude
personas (opt/pra/emp and any Claude fallback) use Read, Glob, Grep,
WebSearch, WebFetch only.

Exception: Bash is permitted for Codex peer subagents (agent_type starting
with "codex") — Codex needs internal Bash to execute. Edit/Write/NotebookEdit
remain blocked for every caller, Codex included.

The output of /explore is a synthesis document the user reviews. To ship,
exit /explore and run /execute against the agreed-on goal.
EOF
exit 2
