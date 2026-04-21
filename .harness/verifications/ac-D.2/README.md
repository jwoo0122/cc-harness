# AC-D.2 — Fallback on Codex exit 2/3 (loud)

Proves: SKILL.md explicitly binds Codex exit 2 OR 3 to Claude-PLN fallback
with stderr warning, excludes the phrase "silent fallback" as an allowed
mode, and call-codex.sh really does emit those exit codes in both scenarios.

## Known false-pass risks
- We cannot runtime-prove the orchestrator chooses Claude; grepping Phase 1
  is a proxy. A stronger check would require an orchestrator simulator —
  out of iter-4 scope.
