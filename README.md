# cc-harness

The harness splits one agent's work into read-only debate, planner, implementer, and verifier seats so that evidence, not self-confirmation, decides when a change is done.

cc-harness ships as a Claude Code plugin with two slash commands — `/explore` for divergent debate and `/execute` for convergent execution. Install it from inside Claude Code:

```
/plugin marketplace add jwoo0122/cc-harness
/plugin install cc-harness@cc-harness
```

## Avoiding self-confirmation through role separation

A single agent that writes code and then grades the same code tends toward self-confirmation: the context that produced the answer also rewards it. The harness removes that shortcut by dispatching each seat as an isolated subagent with its own tool budget. `/explore` runs four personas — OPT, PRA, SKP, EMP — in parallel read-only windows; no persona can mutate the repo, and unanimous round-one agreement is disallowed so dissent has to surface. `/execute` runs a three-role separation: PLN plans increments and acceptance criteria, IMP writes code, VER grades it. The Planner cannot run tests. The Implementer cannot declare an AC passed. The Verifier cannot edit source. Enforcement is structural. A `PreToolUse` hook at `skills/explore/block-mutating.sh` rejects Edit, Write, NotebookEdit, and Bash in explore mode, and `skills/execute/gate-mutating.sh` permits mutation only when the dispatched subagent reports `agent_type=imp`. Role separation is a property of the process, not a reminder in a prompt.

## Interview until ambiguity is gone

`/explore` opens with an orchestrator interview that fires `AskUserQuestion` on four triggers: a vague topic, contradictory project context, a persona-interpretation split after round one, and a user-resolvable synthesis tension before the final brief. The exchange runs tiki-taka until ambiguity is gone. Between subagent dispatches the interview is a chat pattern carried out inside the orchestrator turn, not a hook-enforced gate, so the user should refuse a premature dispatch in chat rather than rely on the plugin to block it.

## Pre-arranged verification before code

`/execute` treats verification as a first-class authoring step. In Phase 1.5, VER writes the adversarial test corpus into `.harness/verifications/` before IMP touches production code, so the grader's rubric exists prior to the work being graded. PLN authors acceptance criteria first. VER then materializes each criterion as an executable check. Only after that does IMP begin the increment. Each registered check is recorded in `.harness/verification-registry.json` with its command, the acceptance criterion it targets, and the increment that introduced it. When IMP finishes an increment, VER runs the newly added checks, then re-runs the full registered set as a regression sweep, so a later increment cannot silently invalidate an earlier one. This is pre-arranged verification: the bar is fixed in the repository before the code exists, and every iteration re-measures against the accumulated bar rather than a rubric written after the fact.

## Spec that persists across sessions

State carries across sessions through two durable artifacts. `.harness/verification-registry.json` keeps the registered check set, and each loop writes `.iteration-<N>/brief.md`, `verify-report.md`, and `decision-log.md` capturing intent, results, and the rationale for entering the next iteration. A new session can replay the last iteration triple and re-run the registry to recover ground truth. The gap: per-acceptance-criterion progress inside an in-flight iteration is not persisted, so resuming mid-iteration means rereading the triple and asking the user which acceptance criteria already passed.
