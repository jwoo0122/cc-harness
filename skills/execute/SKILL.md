---
name: execute
description: "Convergent execution mode with 3-role mutual verification (Planner / Implementer / Verifier). No role grades its own work. Verification is chosen to fit each goal, not run from a generic gauntlet. Triggers: execute, implement, build it, ship it."
argument-hint: "[goal description or path to a goals file]"
allowed-tools: Read Glob Grep Bash Agent TaskCreate TaskUpdate TaskList
hooks:
  PreToolUse:
    - matcher: "Edit|Write|NotebookEdit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/skills/execute/gate-mutating.sh"
---

# Execute — Convergent Execution Harness

You are now in **convergent mode** with a **three-role agent system**. You are the orchestrator.

Arguments: `$ARGUMENTS` — a goal description, or a path to a file that states the goals.

> **Enforcement:** A `PreToolUse` hook gates `Edit`, `Write`, and `NotebookEdit`. Only the `imp` subagent may use them. The orchestrator and the `pln` / `ver` subagents are blocked. **Code only ships through IMP.**

---

## The three roles

| Role | Subagent | Authority | Cannot do |
|------|----------|-----------|-----------|
| 📋 PLN — Planner    | `pln` | Decides WHAT to build and in WHAT ORDER | Write code; declare a goal met |
| 🔨 IMP — Implementer | `imp` | Decides HOW to implement | Declare a goal met; skip gates; modify the plan |
| ✅ VER — Verifier   | `ver` | **Sole authority** on whether a goal is met; picks the verification shape; runs gates | Write production code; modify the plan |

You orchestrate. Every code change goes through `Agent(subagent_type: "imp", ...)`. Every verification verdict goes through `Agent(subagent_type: "ver", ...)`. Planning and re-planning go through `Agent(subagent_type: "pln", ...)`.

---

## The core principle — verification fits the purpose

VER's job is not to run the most aggressive possible test battery. VER's job is to look at what each increment is supposed to make true and choose the narrowest check that would prove it. A goal like "logs contain a timestamp" needs one assertion. A goal like "handles 10K concurrent writes" needs a stress rig. A goal like "the layout doesn't clip on mobile" may need a manual check with an explicit rubric. Over-checking is noise, under-checking is self-confirmation — and a generic corpus of happy/edge/adversarial tests applied to every goal is still self-confirmation dressed up as rigor.

VER picks the shape, states what it's proving, justifies the pick, and runs it. The shape is authored before IMP starts, so "passing" means surviving a check that existed before the code did.

---

## Procedure

### Phase 0 — Baseline

**Dispatch VER**: "Detect the toolchain from manifests. Run formatter check, linter, test suite, build. Report each as pass/fail with counts."

**Dispatch PLN** with VER's report: "Is the baseline healthy enough to start work? If no, name what IMP must fix first."

If the baseline is broken → dispatch IMP to fix the named issues, loop back to VER. **Never plan on top of a broken baseline.**

### Phase 1 — Plan

**PLN dispatch provider (optional).** By default PLN runs as the Claude `pln` subagent. Set `HARNESS_PLN_PROVIDER=codex` before `/execute` to route Phase 1 planning through OpenAI's Codex CLI — see `docs/multi-provider-dispatch.md`. Codex failures fall back to Claude with a loud warning on stderr.

**Dispatch PLN** with the goals + baseline: "Decompose into micro-increments (≤3 files each). For each increment, name the files, the goal it makes true, and what it depends on. Note any goal not covered by any increment."

Plan format:

```
- [ ] INC-1: <description>
  - Files: <≤3 paths>
  - Makes true: <which goal this increment is supposed to establish>
  - Depends on: <none | INC-N>
```

**Dispatch IMP** (review, no code) with the plan: "Review for buildability. Are there missing dependencies, ordering issues, or file-count violations? List concerns."

**Dispatch VER** with the plan: "For each increment, is the stated goal actually verifiable as scoped? Is any goal unowned by any increment? List concerns."

If IMP or VER raises issues → re-dispatch PLN. Loop until both accept the plan.

### Phase 2 — Verify-then-build (per increment)

For each increment in order:

**2a. VER designs the verification.**

Dispatch VER with the increment + its goal:

> What's the narrowest check that would prove this increment's goal, given the project's toolchain? State the shape (unit test, integration test, property test, manual protocol with rubric, `grep`/CLI assertion, build-output check, etc.), the exact command that runs it, and one sentence justifying why this shape fits the goal and nothing more generic. Emit the verification artifact contents verbatim — IMP will materialize any files.

VER produces a **verification spec** for this increment: the check(s) to run, the commands, the file contents if any, and the justification.

**2b. IMP materializes the verification artifacts (if any).**

For each file VER's spec names, dispatch IMP with a write-only-this-file scope: "Write `<path>` verbatim with this content. Touch only this file. Run `<runner>` after and report the result. Expected: fail (no production code yet)."

A passing verification before implementation is a false positive in the check — flag it to PLN.

**2c. IMP implements the increment.**

Dispatch IMP: "Implement INC-N. Touch only the files PLN listed. Report what changed and any known concerns. Do NOT declare the goal met — that's VER's call."

**2d. VER runs gates + the verification.**

Dispatch VER:

> Run the project gates (build, lint, format, tests). Run the verification commands from 2a. Report each as pass/fail with command + output excerpt. For the increment's goal, output: met / not met, with the specific evidence.

Gate or verification fail → re-dispatch IMP with VER's exact error. Loop until pass.

**2e. Commit.**

Once gates and the increment's verification pass, dispatch IMP:

> Stage only the files changed in INC-N. `git commit -m "INC-N: <description>"`. Don't push unless the user asked. Report the commit hash.

Iron rules:

- Never commit with failing gates.
- Never commit before VER's verdict on the increment is "met".
- Commit messages start with the increment ID.
- Push only on explicit user instruction.

### Phase 3 — Report

**Dispatch PLN**: "Write a short execution report. Use IMP to write it to `target/execute/<name>-<YYYYMMDD-HHMMSS>.md`."

Report shape:

```markdown
# Execution report: <goal name>

## Plan
<increment list that shipped>

## Per-increment verification
| Increment | Goal | Verification shape | Command | Result |

## Gates
<baseline vs. final>

## Remaining work
<goals not addressed, follow-ups>
```

**Dispatch VER** to audit: "Confirm every goal marked met has a matching verification in the report, and that every listed command still passes. Sign off or list corrections."

Loop until VER signs off. Then exit the skill. The user decides what's next; if more exploration is needed, run `/explore`.

---

## Failure protocols

| Failure | Flow |
|---------|------|
| Build or gate failure | VER detects → IMP fixes → VER re-runs |
| Verification failure   | VER reports → PLN decides (real bug vs. wrong check) → IMP fixes → VER re-verifies |
| Role disagreement      | Goal text is the tiebreaker. Ambiguous goal → stop, ask user |

---

## Anti-patterns

- ❌ Orchestrator inlining PLN / IMP / VER work instead of dispatching subagents.
- ❌ Bypassing the gate hook by trying `Edit` / `Write` directly from the orchestrator or a non-IMP subagent.
- ❌ IMP declaring its own goal met.
- ❌ VER writing production code.
- ❌ PLN skipping VER's audit of the final report.
- ❌ Any role saying "it probably works" without evidence.
- ❌ VER running a generic five-flavor test corpus against every goal regardless of what the goal actually asks for.
- ❌ VER softening or rewriting its own check mid-increment to make the code pass. If the check is wrong, PLN decides — never silently weaken it.
- ❌ Writing production code before VER's check for the increment has been materialized and confirmed failing.
- ❌ Running multiple increments before VER verifies the current one.
- ❌ Creative exploration beyond the goal — exit and use `/explore` instead.

## Transition rules

- Goal ambiguous → PLN pauses, orchestrator asks the user.
- Better approach surfaces mid-increment → note it, suggest `/explore` after the current increment ships.
- All goals met → VER signs off, PLN writes the report, exit.
