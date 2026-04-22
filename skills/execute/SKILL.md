---
name: execute
description: "Convergent execution mode with 3-role mutual verification (Planner / Implementer / Verifier) plus an independent-model adversarial review. PLN and IMP are Claude subagents; VER runs on the Codex peer model (dispatched via codex:codex-rescue) so verdicts come from an independent model. An adversarial-review round at plan lock catches holes before Phase 2. Triggers: execute, implement, build it, ship it."
argument-hint: "[goal description or path to a goals file]"
allowed-tools: Read Glob Grep Bash Agent AskUserQuestion TaskCreate TaskUpdate TaskList
hooks:
  PreToolUse:
    - matcher: "Edit|Write|NotebookEdit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/skills/execute/gate-mutating.sh"
---

# Execute — Convergent Execution Harness

You are now in **convergent mode** with a **three-role agent system**, crossing models: PLN and IMP run as Claude subagents; **VER runs on the Codex peer model** via the `codex:codex-rescue` subagent. An **independent-model adversarial review** at the end of Phase 1 catches plan holes before Phase 2.

You are the orchestrator.

Arguments: `$ARGUMENTS` — a goal description, or a path to a file that states the goals.

> **Enforcement:** A `PreToolUse` hook gates `Edit`, `Write`, and `NotebookEdit`. Only the `imp` subagent may use them. The orchestrator, `pln`, and any VER seat (Codex or fallback) are blocked. **Code only ships through IMP.**

---

## The three roles

| Role | Dispatch | Model | Authority | Cannot do |
|------|----------|-------|-----------|-----------|
| 📋 PLN — Planner    | `Agent(subagent_type: "pln", ...)` | Claude | Decides WHAT to build and in WHAT ORDER | Write code; declare a goal met |
| 🔨 IMP — Implementer | `Agent(subagent_type: "imp", ...)` | Claude | Decides HOW to implement | Declare a goal met; skip gates; modify the plan |
| ✅ VER — Verifier   | `Agent(subagent_type: "codex:codex-rescue", prompt: <VER template>)` | **Codex (peer model)** | **Sole authority** on whether a goal is met; picks the verification shape; runs gates | Write production code; modify the plan |

Codex-VER prompts are templated in `skills/_shared/codex-ver-prompt.md`. There are five duty sections (Phase 0 baseline, Phase 1 plan review, Phase 2a verification design, Phase 2d verdict, Phase 3 report audit). Substitute `{{variables}}` per that file's instructions; prepend the charter block; pass as the `prompt` argument of the Codex dispatch.

**VER fallback.** If a Codex-VER dispatch errors (error return, empty body, or malformed output), fall back to `Agent(subagent_type: "ver-fallback", ...)` with the same template body. Annotate the run log / Phase 3 report with `VER: Claude fallback at <phase>`. A mono-model VER seat is a known weaker state — the annotation is non-negotiable.

**Adversarial review.** At the end of Phase 1 (after both IMP's buildability review and Codex-VER's verifiability review have accepted the plan), dispatch `Agent(subagent_type: "codex:codex-rescue", prompt: <adversarial-review template>)` using `skills/_shared/codex-adversarial-review-prompt.md`. This is a separate, independent-model gate on top of the intra-debate reviews: its job is to find holes, not to verify or design. See Phase 1 procedure below.

You orchestrate. Every code change goes through `Agent(subagent_type: "imp", ...)`. Every verification verdict goes through the Codex-VER dispatch (or its fallback). Planning and re-planning go through `Agent(subagent_type: "pln", ...)`.

---

## The core principle — verification fits the purpose

VER's job is not to run the most aggressive possible test battery. VER's job is to look at what each increment is supposed to make true and choose the narrowest check that would prove it. A goal like "logs contain a timestamp" needs one assertion. A goal like "handles 10K concurrent writes" needs a stress rig. A goal like "the layout doesn't clip on mobile" may need a manual check with an explicit rubric. Over-checking is noise, under-checking is self-confirmation — and a generic corpus of happy/edge/adversarial tests applied to every goal is still self-confirmation dressed up as rigor.

VER picks the shape, states what it's proving, justifies the pick, and runs it. The shape is authored before IMP starts, so "passing" means surviving a check that existed before the code did.

Because VER runs on an independent model from PLN and IMP, the verdict is not a self-grade of the planner's or the implementer's output. That cross-model separation is structural, not prompt-enforced.

---

## Procedure

### Phase 0 — Baseline

**Dispatch Codex-VER** with Section A of `codex-ver-prompt.md`: "Detect the toolchain from manifests. Run formatter check, linter, test suite, build. Report each as pass/fail with counts."

**Dispatch PLN** with Codex-VER's report: "Is the baseline healthy enough to start work? If no, name what IMP must fix first."

If the baseline is broken → dispatch IMP to fix the named issues, loop back to Codex-VER. **Never plan on top of a broken baseline.**

If Codex-VER errors, fall back to `ver-fallback` and annotate.

### Phase 1 — Plan

**Dispatch PLN** with the goals + baseline: "Decompose into micro-increments (≤3 files each). For each increment, name the files, the goal it makes true, and what it depends on. Note any goal not covered by any increment."

Plan format:

```
- [ ] INC-1: <description>
  - Files: <≤3 paths>
  - Makes true: <which goal this increment is supposed to establish>
  - Depends on: <none | INC-N>
```

**Dispatch IMP** (review, no code) with the plan: "Review for buildability. Are there missing dependencies, ordering issues, or file-count violations? List concerns."

**Dispatch Codex-VER** with Section B of `codex-ver-prompt.md`: for each increment, is the stated goal actually verifiable as scoped? Is any goal unowned by any increment? List concerns.

If IMP or Codex-VER raises issues → re-dispatch PLN. Loop until both accept the plan.

**Adversarial review (end of Phase 1, independent gate).**

Once IMP and Codex-VER have both accepted, dispatch `Agent(subagent_type: "codex:codex-rescue", prompt: <adversarial-review template>)` using `skills/_shared/codex-adversarial-review-prompt.md`. The reviewer's sole job is to find holes in the locked plan — goal coverage, ordering, scope leakage, hidden assumptions, failure-mode coverage, size honesty.

- **PASS** → proceed to Phase 2.
- **FAIL** → re-dispatch PLN with the findings; once revised, re-run the Phase 1 chain (IMP review → Codex-VER review → adversarial review) from the top. Each revision is a fresh cycle with its own attempt counter.
- **Attempt cap: 3.** After three consecutive FAILs, escalate to the user with `AskUserQuestion`:
  - "Continue looping (allow attempt 4+)"
  - "Accept current plan despite findings (override)"
  - "Abort /execute"
- **Codex error on adversarial review** → annotate the run log with `Adversarial review: Codex dispatch failed`, then **proceed to Phase 2 without blocking**. Do not fall back to Claude for adversarial review: Claude grading a plan Claude shaped is exactly the self-confirmation the gate exists to prevent.

### Phase 2 — Verify-then-build (per increment)

For each increment in order:

**2a. Codex-VER designs the verification.**

Dispatch Codex-VER with Section C of `codex-ver-prompt.md` (the Phase 2a template) for this increment. The template demands:

> The narrowest check that would prove the goal, given the toolchain. State the shape (unit test, integration test, property test, manual protocol with rubric, `grep`/CLI assertion, build-output check, etc.), the exact command that runs it, and one sentence justifying why this shape fits the goal and nothing more generic. Emit the verification artifact contents verbatim — IMP will materialize any files.

The output is the **verification spec** for this increment: the check(s) to run, the commands, the file contents if any, and the justification.

**2b. IMP materializes the verification artifacts (if any).**

For each file the spec names, dispatch IMP with a write-only-this-file scope: "Write `<path>` verbatim with this content. Touch only this file. Run `<runner>` after and report the result. Expected: fail (no production code yet)."

A passing verification before implementation is a false positive in the check — flag it to PLN.

**2c. IMP implements the increment.**

Dispatch IMP: "Implement INC-N. Touch only the files PLN listed. Report what changed and any known concerns. Do NOT declare the goal met — that's VER's call."

**2d. Codex-VER runs gates + the verification.**

Dispatch Codex-VER with Section D of `codex-ver-prompt.md` (Phase 2d template) for this increment:

> Run the project gates (build, lint, format, tests). Run the verification commands from 2a. Report each as pass/fail with command + output excerpt. For the increment's goal, output: met / not met, with the specific evidence.

Gate or verification fail → re-dispatch IMP with Codex-VER's exact error. Loop until pass.

**2e. Commit.**

Once gates and the increment's verification pass, dispatch IMP:

> Stage only the files changed in INC-N. `git commit -m "INC-N: <description>"`. Don't push unless the user asked. Report the commit hash.

Iron rules:

- Never commit with failing gates.
- Never commit before the VER verdict on the increment is "met".
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

## Seat annotations
<any phases where VER ran in fallback; whether adversarial review was skipped due to Codex error>

## Remaining work
<goals not addressed, follow-ups>
```

**Dispatch Codex-VER** with Section E of `codex-ver-prompt.md` (report audit): confirm every goal marked met has a matching verification in the report, and that every listed command still passes. Sign off or list corrections.

Loop until Codex-VER signs off (with fallback annotation on error). Then exit the skill. The user decides what's next; if more exploration is needed, run `/explore`.

---

## Failure protocols

| Failure | Flow |
|---------|------|
| Build or gate failure | Codex-VER detects → IMP fixes → Codex-VER re-runs |
| Verification failure   | Codex-VER reports → PLN decides (real bug vs. wrong check) → IMP fixes → Codex-VER re-verifies |
| Role disagreement      | Goal text is the tiebreaker. Ambiguous goal → stop, ask user |
| Codex-VER dispatch error | Fall back to `ver-fallback` for that one call; annotate run log; continue |
| Adversarial review Codex error | Annotate run log; proceed to Phase 2 without blocking. Do NOT fall back to Claude for this one step |
| Adversarial review FAIL × 3 | Escalate via `AskUserQuestion`: continue looping / override / abort |

---

## Anti-patterns

- ❌ Orchestrator inlining PLN / IMP / VER work instead of dispatching subagents.
- ❌ Bypassing the gate hook by trying `Edit` / `Write` directly from the orchestrator or a non-IMP subagent.
- ❌ IMP declaring its own goal met.
- ❌ VER (Codex or fallback) writing production code.
- ❌ PLN skipping Codex-VER's audit of the final report.
- ❌ Any role saying "it probably works" without evidence.
- ❌ Silently using `ver-fallback` without annotating the run log — users need to know when the verdict went mono-model.
- ❌ Falling back to Claude for the adversarial review when Codex errors — that re-introduces the self-confirmation the gate exists to prevent.
- ❌ Skipping the adversarial review round because PLN and Codex-VER already approved — the two intra-debate reviews and the adversarial review are different gates.
- ❌ VER running a generic five-flavor test corpus against every goal regardless of what the goal actually asks for.
- ❌ VER softening or rewriting its own check mid-increment to make the code pass. If the check is wrong, PLN decides — never silently weaken it.
- ❌ Writing production code before the check for the increment has been materialized and confirmed failing.
- ❌ Running multiple increments before VER verifies the current one.
- ❌ Creative exploration beyond the goal — exit and use `/explore` instead.

## Transition rules

- Goal ambiguous → PLN pauses, orchestrator asks the user.
- Better approach surfaces mid-increment → note it, suggest `/explore` after the current increment ships.
- All goals met → Codex-VER signs off, PLN writes the report, exit.
