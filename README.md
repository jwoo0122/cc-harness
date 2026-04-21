# cc-harness

Two Claude Code slash commands that split one agent's work into separate seats so the evidence that a change is done comes from a role that didn't write the change.

```
/plugin marketplace add jwoo0122/cc-harness
/plugin install cc-harness@cc-harness
```

## Role separation beats self-confirmation

A single agent that writes code and then grades it rewards self-confirmation — the context that produced the answer also approves it. The harness breaks that loop by dispatching each seat as an isolated subagent with its own tool budget. `/explore` runs four read-only personas in parallel; a `PreToolUse` hook blocks `Edit`, `Write`, `NotebookEdit`, and `Bash` so no persona can mutate the repo. `/execute` runs three roles — Planner, Implementer, Verifier — and a hook permits mutation only when the dispatched subagent reports `agent_type=imp`. Separation is structural, not a reminder in a prompt.

## Verification has to fit the purpose

A pre-authored adversarial gauntlet run against every change is theatrical — it grades the work against a generic rubric, not the goal that was actually set. The Verifier's job in `/execute` is the opposite: look at what this increment is supposed to make true, then choose the narrowest check that would prove it. A goal like "logs contain a timestamp" needs one assertion; a goal like "handles 10K concurrent writes" needs a stress rig. Over-checking is noise, under-checking is self-confirmation, and the Verifier has to justify the shape it picked before the Implementer starts writing.

## What's in the box

- `/explore` — 4-persona divergent debate (Optimist / Pragmatist / Skeptic / Empiricist). Read-only. Produces a synthesis the user reviews before any code is written.
- `/execute` — convergent planner/implementer/verifier loop. Only the Implementer can mutate files; the Verifier decides whether a goal is met, against a check chosen to fit the goal.

Optional: set `HARNESS_PLN_PROVIDER=codex` to route the Planner through OpenAI's Codex CLI instead of Claude — see `docs/multi-provider-dispatch.md`.
