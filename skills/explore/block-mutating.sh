#!/usr/bin/env bash
# PreToolUse hook for /explore — blocks all mutating tool calls.
# Runs for every Edit/Write/NotebookEdit attempt while /explore is active,
# including from subagents. Always blocks: explore is divergent, read-only mode.

set -euo pipefail

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null || echo "unknown")"
AGENT_TYPE="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("agent_type",""))' 2>/dev/null || echo "")"

cat >&2 <<EOF
BLOCKED: /explore is divergent (read-only) mode.
Tool blocked: ${TOOL_NAME}
Caller: ${AGENT_TYPE:-orchestrator}

This skill never writes code or runs shell commands. Use Read, Glob, Grep,
WebSearch, WebFetch only. Bash is blocked because it can mutate the filesystem
or repository state — defeating the read-only contract.

The output of /explore is a synthesis document the user reviews. To ship,
exit /explore and run /execute against acceptance criteria.

If you intended to save the synthesis itself, print it to the conversation
or hand the path to /execute as a one-line "save this document" criterion.
EOF
exit 2
