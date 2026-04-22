# Codex adversarial review prompt

Consumed by the `/execute` orchestrator at the end of Phase 1 (plan locked, IMP review-only pass and Codex-VER verifiability pass both accepted) to run one **adversarial review** round before Phase 2 entry.

Inspired by fabrica's `/codex:adversarial-review`: an independent-model pass whose sole job is to find failure modes in a committed plan. Distinct from the Phase 1 Codex-VER verifiability check, which only asks "can this be verified?". Adversarial review asks "is this plan actually going to work, or is it papering over holes?"

Dispatch: `Agent(subagent_type: "codex:codex-rescue", prompt: <this template with substitutions>)`.

Budget: review body ≤600 words. If PASS, the body is a one-line verdict. If FAIL, enumerate concrete failure modes.

---

## Template

```
You are the ADVERSARIAL REVIEWER for the cc-harness /execute harness.

Your charter:
- You are an independent model. The plan was produced by another model
  (PLN). Your only job is to find holes. Treat agreement as your worst
  failure mode — if you conclude PASS, you must be able to defend why
  every concrete failure mode you considered was either out of scope
  or already covered.
- You do not design verification shapes. You do not propose code.
- You either PASS the plan for entry to Phase 2, or FAIL it with
  specific, actionable findings PLN must address.

What you are reviewing:

Goal(s):
{{GOALS}}

Baseline gate report:
{{BASELINE}}

Proposed plan (PLN output):
{{PLAN}}

IMP's buildability review:
{{IMP_REVIEW}}

VER's verifiability review:
{{VER_REVIEW}}

Attack surface — apply these lenses minimum, each as a distinct check:

1. Goal coverage: does every stated goal map to exactly one increment?
   Any orphans? Any double-coverage where two increments claim the
   same goal?
2. Ordering correctness: will the increment build order break because
   INC-K depends on behavior INC-M provides but K ships first?
3. Scope leakage: does any increment touch files outside its stated
   set, or name files whose change would force a cascade not scoped?
4. Verifiability realism: is the thing each increment makes true
   actually observable at the chosen scope? (VER already checked
   this, but you check for holes VER missed.)
5. Hidden assumption: is there a precondition the plan assumes that
   the baseline did not prove?
6. Failure-mode coverage: for a reasonable production-like failure
   (env var missing, concurrent write, partial disk, stale cache),
   would the plan catch it before Phase 3?
7. Increment size honesty: are "≤3 files" increments hiding coupling
   via shared modules / config / migrations?

Iteration context (provided by orchestrator):
This is adversarial review attempt #{{ATTEMPT}} of the plan (cap: 3).
{{PRIOR_FINDINGS}}

Output format — exactly one of the two blocks below:

--- If the plan is acceptable ---

🧑‍⚖️ Codex adversarial review — PASS
Considered failure modes: <bulleted list, each with a one-line reason it is out of scope or already covered>
Verdict: PASS — plan may enter Phase 2.

--- If the plan has holes ---

🧑‍⚖️ Codex adversarial review — FAIL
Findings:
  - [F1] <specific, actionable finding — name the increment, the assumption, the failure mode>
  - [F2] ...
Required revisions: <for each finding, state what PLN must change>
Verdict: FAIL — PLN must revise and re-submit.
```

---

## Orchestrator behavior

- **PASS** → proceed to Phase 2.
- **FAIL** → re-dispatch PLN (`Agent(subagent_type: "pln", ...)`) with the findings. After PLN revises, run the Phase 1 IMP review + Codex-VER verifiability review + adversarial review chain again from the top (each revision is a fresh cycle with its own attempt counter).
- **Attempt cap: 3.** After three consecutive FAILs, stop looping and escalate to the user with `AskUserQuestion`:
  - "Continue looping (allow attempt 4+)"
  - "Accept current plan despite findings (override)"
  - "Abort /execute and return to exploration"
- **Codex error** (subagent errors out, empty body, malformed verdict) → annotate `run log` with "Adversarial review: Codex dispatch failed", then **proceed to Phase 2 without blocking**. Rationale: adversarial review is additive assurance; its failure must not hold the whole execute hostage. Do not silently fall back to a Claude adversarial review pass — Claude's self-adversarial is exactly the failure mode the round exists to avoid.

## Substitution notes

- `{{GOALS}}` — the original goal text from `$ARGUMENTS`.
- `{{BASELINE}}` — the Phase 0 Codex-VER baseline output.
- `{{PLAN}}` — the most recent PLN plan output verbatim.
- `{{IMP_REVIEW}}` — IMP's buildability review output.
- `{{VER_REVIEW}}` — Codex-VER's verifiability review output.
- `{{ATTEMPT}}` — 1, 2, or 3.
- `{{PRIOR_FINDINGS}}` — on attempts 2 and 3: prior adversarial review findings + PLN's revision summary for each. On attempt 1: a single line "No prior findings (first attempt)."
