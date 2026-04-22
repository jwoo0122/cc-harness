#!/usr/bin/env bash
# PreToolUse hook for /execute — gates mutating tools to the IMP subagent only.
# Allows Edit/Write/NotebookEdit when agent_type=imp; blocks otherwise
# (orchestrator, pln, any VER seat, anything else). This enforces the
# role-separation iron law: only IMP writes code.
#
# Bash is NOT on the hook's matcher list (see skills/execute/SKILL.md
# frontmatter), so Bash calls — including Codex-VER's internal Bash when
# running gates and verifications — do not reach this script at all. There
# is no provider allow-list here anymore: it existed to bypass a defunct
# subprocess-wrapper path. Codex is now dispatched as a peer subagent
# (codex:codex-rescue) via the Agent tool.

set -euo pipefail

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null || echo "unknown")"
AGENT_TYPE="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("agent_type",""))' 2>/dev/null || echo "")"

# IMP always allowed (iron law).
if [ "$AGENT_TYPE" = "imp" ]; then
  exit 0
fi

cat >&2 <<EOF
BLOCKED: /execute restricts mutating tools to the IMP subagent.
Tool blocked: ${TOOL_NAME}
Caller: ${AGENT_TYPE:-orchestrator}

In /execute, only the 'imp' subagent may use Edit/Write/NotebookEdit.
The orchestrator dispatches IMP via the Agent tool with subagent_type="imp"
and a tightly scoped prompt (single increment, named files only).

If you are the orchestrator and need to make code changes, dispatch IMP.
If you are PLN or a VER seat (Codex or fallback), you are out of role —
surface the need and let the orchestrator dispatch IMP.
EOF
exit 2
