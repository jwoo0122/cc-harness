# cc-harness

Two Claude Code slash commands that split one agent's work into separate seats so the evidence that a change is done comes from a role that didn't write the change.

```
/plugin marketplace add jwoo0122/cc-harness
/plugin install cc-harness@cc-harness
```

## Role separation beats self-confirmation

A single agent that writes code and then grades it rewards self-confirmation — the context that produced the answer also approves it. The harness breaks that loop by dispatching each seat as an isolated subagent with its own tool budget. `/explore` runs four read-only personas in parallel; a `PreToolUse` hook blocks `Edit`, `Write`, `NotebookEdit`, and (for Claude seats) `Bash` so no persona can mutate the repo. `/execute` runs three roles — Planner, Implementer, Verifier — and a hook permits mutation only when the dispatched subagent reports `agent_type=imp`. Separation is structural, not a reminder in a prompt.

## Cross-model adversarial pressure

Role separation on one model is still one model grading itself. The harness crosses models for the seats whose job is to find fault: the **Skeptic** in `/explore`, the **Verifier** across every phase of `/execute`, and a dedicated **adversarial review** round that gates entry to Phase 2. Those seats run on the Codex peer model (`codex:codex-rescue` subagent); Planner, Implementer, Optimist, Pragmatist, and Empiricist stay on Claude. When Codex is unreachable, the skills fall back to Claude seats and annotate the run as mono-model — so users can see which runs ran in the weaker state. Details: `docs/codex-peer-integration.md`.

## Verification has to fit the purpose

A pre-authored adversarial gauntlet run against every change is theatrical — it grades the work against a generic rubric, not the goal that was actually set. The Verifier's job in `/execute` is the opposite: look at what this increment is supposed to make true, then choose the narrowest check that would prove it. A goal like "logs contain a timestamp" needs one assertion; a goal like "handles 10K concurrent writes" needs a stress rig. Over-checking is noise, under-checking is self-confirmation, and the Verifier has to justify the shape it picked before the Implementer starts writing.

## What's in the box

- `/explore` — 4-persona divergent debate (Optimist / Pragmatist / Skeptic / Empiricist). Read-only. The Skeptic seat runs on the Codex peer model so adversarial pressure is cross-model, not Claude-on-Claude. Produces a synthesis the user reviews before any code is written.
- `/execute` — convergent planner/implementer/verifier loop. Only the Implementer can mutate files; the Verifier runs on the Codex peer model and has sole authority to declare a goal met. An adversarial review round at the end of Phase 1 catches plan holes before implementation starts.

Prerequisite for cross-model operation: the `codex:codex-rescue` peer subagent must be available (run `/codex:setup` if in doubt). Skills still run without it, falling back to Claude seats with a visible annotation.
