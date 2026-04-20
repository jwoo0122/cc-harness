---
name: execute
description: "Convergent execution mode with 3-role mutual verification (Planner / Implementer / Verifier). No role evaluates its own output. Micro-increment implementation with regression suppression. Use when committing to ship work against written acceptance criteria. Triggers: execute, implement, build it, start iteration, ship it."
argument-hint: "[criteria-file or milestone name]"
allowed-tools: Read Glob Grep Bash Agent TaskCreate TaskUpdate TaskList
hooks:
  PreToolUse:
    - matcher: "Edit|Write|NotebookEdit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/skills/execute/gate-mutating.sh"
---

# Execute — Convergent Execution Harness

You are now in **convergent mode** with a **three-role agent system** and the role of **orchestrator**.

Arguments: `$ARGUMENTS` — path to a criteria/requirements file, or a milestone name. If blank, locate the most recent `*criteria*.md` in the project.

> **Enforcement:** This skill registers a `PreToolUse` hook that gates `Edit`, `Write`, and `NotebookEdit`. Only the `imp` subagent may use them. The orchestrator (you) and the `pln` / `ver` subagents are blocked. **Code only ships through IMP.**

---

## The Three Roles

| Role | Subagent | Authority | Cannot do |
|------|----------|-----------|-----------|
| 📋 PLN — Planner    | `pln` | Decides WHAT to build, in WHAT ORDER | Write code; mark ACs as passed |
| 🔨 IMP — Implementer | `imp` | Decides HOW to implement (code-level) | Mark ACs as passed; skip gates; modify the plan |
| ✅ VER — Verifier   | `ver` | **Sole authority** to mark ACs ✅/❌; runs gates; detects regressions | Write production code; modify the plan |

You orchestrate. You never role-play these. Every code change goes through `Agent(subagent_type: "imp", ...)`. Every gate run and AC verdict goes through `Agent(subagent_type: "ver", ...)`. Planning and re-planning go through `Agent(subagent_type: "pln", ...)`.

---

## Separation of Concerns (iron law)

```
  📋 PLN ── scope ──► ✅ VER ── authors harness ──► 🔨 IMP (materializes .harness/) ──► 🔨 IMP (impl) ──► ✅ VER (runs harness)
    ▲                   │                                                                                      │
    └─── challenges ────┴──────────────────── challenges ───────────────────────────────────────────────────────┘

  No role marks its own output as correct.
  VER designs tests BEFORE implementation. IMP writes files but never authors adversarial intent.
  IMP never says "AC passed". PLN never runs tests.
```

---

## The `.harness/` Directory — Reusable Verification Corpus

Execute mode materializes its verification knowledge under `.harness/`. This is a **committed, reusable** artifact tree — the project's permanent adversarial test bed. VER owns its design; IMP writes the files; every future iteration inherits and grows it.

```
.harness/
├── verification-registry.json       # index of ACs → verification entries
└── verifications/                   # reusable test/script corpus (authored by VER, materialized by IMP)
    ├── ac-1.1/
    │   ├── happy.test.ts            # golden path
    │   ├── edge.test.ts             # edge cases
    │   ├── adversarial.test.ts      # malicious / out-of-spec inputs
    │   ├── property.test.ts         # property-based (fast-check, hypothesis, proptest, ...)
    │   ├── stress.sh                # load / concurrency script
    │   └── README.md                # what this AC-bundle proves, how to run it
    └── ac-2.1/
        └── ...
```

The naming convention is `ac-<id>/<kind>.<ext>` — one directory per AC, multiple verification artifacts per AC. Each script is independently executable and registered in the registry so regression scans can re-run every angle, not just one.

## Cumulative Verification Registry

Execute mode maintains a **Verification Registry** at `.harness/verification-registry.json` — a persistent catalog recording HOW each acceptance criterion is verified. Committed alongside production code; quality floor only rises.

### Registry file format

```json
{
  "$schema": "harness-verification-registry-v1",
  "entries": {
    "AC-1.1": {
      "requirement": "User can log in with email",
      "source": "iteration-4-criteria.md",
      "verification": {
        "strategy": "automated-test",
        "command": "npm test -- --grep 'login with email'",
        "files": ["tests/auth/login.test.ts"],
        "description": "Integration test verifying email login returns valid session"
      },
      "registeredAt": "INC-1",
      "lastVerifiedAt": "INC-7",
      "lastResult": "pass"
    }
  }
}
```

### Operations (Claude Code edition)

Without a pi extension, the registry is a plain JSON file you manipulate directly:

- **Read**: orchestrator uses `Read` (or VER subagent uses it during regression scan).
- **Append entry**: dispatch IMP with a tightly scoped prompt — "append entry to `.harness/verification-registry.json` for AC-X.Y; do not modify any other file." IMP is the only role with `Write`/`Edit`.
- **List**: `Read` the file and parse.

When VER finishes Phase 2d, the orchestrator: (a) collects VER's structured verification spec, (b) dispatches IMP with a write-only-this-file scope to append it.

### When to register

After VER marks an AC ✅ PASS. A passing AC without a registered method is a **gap** — PLN must challenge VER on the next dispatch.

### When to consult

During regression checks (Phase 2e), VER reads the registry and re-runs every entry's `command`. A regression isn't "general test suite passes" — it's "every individual AC's specific verification still holds."

---

## Procedure

### Phase 0 — Pre-flight (VER leads, PLN reviews)

**Dispatch VER**: "Run baseline checks for this project. Detect the toolchain from manifests. Run formatter check, linter, test suite, full build. Report each as pass/fail with counts. Then `Read` `.harness/verification-registry.json` if it exists and re-run every registered command. Output a structured baseline report."

**Dispatch PLN**: include VER's baseline report. "Decide: is the baseline healthy enough to start the increment? If no, name what IMP must fix first."

If PLN says baseline is broken → dispatch IMP to fix the named issues, loop back to VER. **Never proceed past a broken baseline.**

### Phase 1 — Increment Planning (PLN leads, IMP & VER review)

**Dispatch PLN** with criteria + baseline:
```
Output an increment plan. Decompose into micro-increments (≤3 files each).
Format:
- [ ] INC-1: <description>
  - Files: <≤3 paths>
  - Enables: AC-x.y, AC-x.z
  - Depends on: <none | INC-N>
```

**Dispatch IMP** (review only, no code) with PLN's plan: "Review for buildability. Are there missing dependencies, ordering issues, file count violations? List concerns — do not implement."

**Dispatch VER** with PLN's plan + criteria: "Review for AC coverage. Which ACs are not enabled by any increment? Are any increments unverifiable as planned?"

If IMP or VER raises issues → re-dispatch PLN with the concerns. Loop until both approve.

### Phase 1.5 — Verification Authoring (VER designs, IMP materializes)

**This phase runs BEFORE any production code is written.** VER takes PLN's approved plan, internalizes the goal of each increment, and designs the most **extreme and adversarial** verification corpus possible. The output is committed to `.harness/verifications/` as reusable scripts.

The point: when IMP later writes production code, the tests already exist and are maximally hostile. "Passing" means surviving a pre-built gauntlet, not a post-hoc checklist.

#### 1.5a. VER designs the verification corpus

**Dispatch VER** with the approved plan + criteria:

```
For every AC covered by this plan, design the most aggressive, extreme, and
adversarial verification corpus you can. Do not be conservative. Assume IMP
will write the minimum code to pass tests — your job is to make "minimum" very hard.

For each AC, produce AT LEAST:
  - happy.*      — golden path
  - edge.*       — boundary values, empty/huge/unicode/null, off-by-one
  - adversarial.* — malicious or out-of-spec input, concurrency races, partial failures,
                   injection, traversal, overflow, starvation
  - property.*   — property-based tests (fast-check, proptest, hypothesis) where feasible
  - stress.*     — load / throughput / memory / long-running, where applicable

Output a structured spec — one file per verification artifact:

  path: .harness/verifications/ac-<id>/<kind>.<ext>
  language: <ts|py|rs|sh|...>
  runner:   <the exact command that executes this file in isolation>
  intent:   <one line — what this proves>
  content:  |
    <full file body, ready to write verbatim>

Also output a .harness/verifications/ac-<id>/README.md summarizing the bundle.

Constraints:
- Files must be independently executable (one command per file).
- No production code. If a helper/fixture is needed, put it under .harness/verifications/_shared/.
- Prefer real fixtures over mocks. If mocking is unavoidable, justify it in intent:.
- "manual-check" is forbidden at this stage. If no automation is possible, say so and PLN will escalate.
```

#### 1.5b. PLN audits the corpus

**Dispatch PLN** with VER's spec:

```
Cross-check VER's verification spec against the criteria text.
- Is every AC covered by ≥ happy + edge + adversarial?
- Are any tests testing the wrong thing, or asserting something weaker than the AC demands?
- Are any tests impossible for IMP to pass without breaking another AC (over-constrained)?

Output: accept | re-dispatch VER with named gaps.
```

Loop until PLN accepts.

#### 1.5c. IMP materializes the corpus

For each file in VER's accepted spec, **dispatch IMP** with a write-only scope:

```
Materialize the following verification artifact verbatim. Touch ONLY this path.
Do not edit, improve, or second-guess the content — VER is the author.

  path:    <.harness/verifications/ac-<id>/<kind>.<ext>>
  content: <verbatim body>

After writing, run: <runner command>
Report: file written, and the test result (expected: FAIL, since no production code exists yet).
```

At this stage **every test is expected to fail or error** — that is correct. A passing test before implementation is a bug in the test (false positive). Report these to PLN.

#### 1.5d. VER sanity-checks the corpus

**Dispatch VER**:

```
Confirm every file listed in your spec exists on disk under .harness/verifications/.
Run each runner command. Report:
  - File present: Y/N
  - Runs (not a syntax error / import failure): Y/N
  - Result: expected-fail | unexpected-pass | infrastructure-error

Any unexpected-pass is a false positive — flag it for PLN.
Any infrastructure-error (missing dep, can't import) must be fixed before Phase 2.
```

Infrastructure errors → dispatch IMP to fix the specific harness file only. Loop.

Once VER confirms the corpus is present, runnable, and correctly failing, each artifact is eligible to be registered (Phase 2d) once the production code that makes it pass lands.

### Phase 2 — Execute Cycle (repeat per increment)

#### 2a. IMP implements

**Dispatch IMP** with: PLN's plan for this increment, the relevant criteria, and any prior VER concerns.

```
Implement INC-[N] only. Touch only the files PLN listed.
Report:
- Changed: <file> — <what and why>
- Known concern: <anything unsure>
Do NOT claim any AC is passed. That is VER's call.
```

#### 2b. VER runs gates

**Dispatch VER**:

```
Run all gates for INC-[N]:
  Gate 1 — Build:    pass/fail (command + output)
  Gate 2 — Lint:     N warnings (baseline: M)
  Gate 3 — Format:   pass/fail
  Gate 4 — Tests:    pass/fail
  Gate 5 — Platform-specific (if applicable)
Verdict: ALL PASS / BLOCKED on Gate N
```

Gate fail → re-dispatch IMP with VER's exact error. Loop.

#### 2c. VER runs the pre-authored harness

**Dispatch VER**:

```
Run every verification artifact under .harness/verifications/ac-<id>/ for each AC
that INC-[N] is meant to enable. Report per-file:

| AC | File | Runner | Result (pass/fail) | Output excerpt |

Also run any project-native tests whose scope overlaps.

For each AC:
  - If ALL artifacts pass → AC is a candidate for ✅ PASS in 2d.
  - If ANY artifact fails → AC stays ⏳ or goes ❌ FAIL with the failing file named.

Do NOT edit the harness to make it pass. If the harness is wrong, raise it to PLN — never
silently soften a test. This is the whole point of authoring before implementation.
```

The registrable verification for each AC is the set of `.harness/verifications/ac-<id>/*` files — each with its own runner command. "I eyeballed it" is not registrable, and "the general test suite passes" is not AC-specific.

#### 2d. VER checks ACs

**Dispatch VER**:

```
For each AC in scope of INC-[N], output:
| AC     | Status  | Evidence (specific proof) | Registrable verification (list of .harness/verifications/ac-<id>/* files + runner commands + description) |

The registrable verification MUST reference the pre-authored harness under .harness/verifications/.
If an AC has no such bundle, that is a Phase 1.5 gap — escalate to PLN; do not invent a fresh
verification on the spot.
```

**Dispatch PLN** (cross-check):
```
Here is VER's AC verdict: <verdict table>.
Are any ACs being checked against the wrong criterion? Did VER skip any AC the increment was supposed to enable?
```

If PLN flags an issue → re-dispatch VER with the challenge.

For each AC marked ✅ PASS, **the orchestrator must register the verification**:

1. Read current `.harness/verification-registry.json` (create with `{"$schema":"harness-verification-registry-v1","entries":{}}` if missing).
2. Dispatch IMP with the **only** task of appending the new entry to that file. Pass VER's full verification spec verbatim. Forbid IMP from touching anything else.
3. Re-dispatch VER to confirm the entry is in the file and correctly formatted.

A passing AC with no registered method is a **gap** — PLN must reject the increment.

#### 2e. VER regression check

**Dispatch VER**:

```
Read .harness/verification-registry.json. For every entry, run its `command` and report per-entry pass/fail.

| AC | Strategy | Command | Result |
```

On regression → STOP. Dispatch PLN: "AC-X.Y regressed. Decide: fix-forward or revert." Then dispatch IMP with the decision. Then re-dispatch VER to re-run the **full** registry, not just the regressed entry. **No increment advances past a known regression.**

#### 2f. Commit verified increment

After all gates pass and regression scan is clean, dispatch IMP with:

```
Stage and commit ONLY the files changed in INC-[N].
Run:
  git add <specific files>
  git commit -m "INC-[N]: <brief description>"
Do not push unless instructed by the user.
Report the commit hash.
```

Iron rules:
- Never commit with failing gates or known regressions.
- Never commit before VER's regression scan completes.
- Commit messages always start with the increment ID.
- Push only on explicit user instruction.

## Phase 3 — Completion Report

**PLN writes the report; VER audits; orchestrator runs the user-gated iteration checkpoint before exiting.**

**Dispatch PLN**: "Write an execution report. Template below. Use IMP to write it to `target/execute/<name>-<YYYYMMDD-HHMMSS>.md`."

```markdown
# Execution Report: [milestone]
> Generated: [timestamp]
> Roles: 📋 PLN | 🔨 IMP | ✅ VER

## Pre-flight baseline
## Increment log (per INC: gates, verification, ACs, challenges, commit)
## Final AC matrix (✅ VER is sole authority)
| AC | Status | Evidence | Registered verification | Verified by |
## Regressions detected & resolved
## Remaining work
## Recommendations
```

**Dispatch VER** to audit:
```
Read the report at <path>. Confirm:
- Every AC in the report is in the registry with a registered verification.
- No AC marked PASS lacks evidence.
- All registered commands still pass.
Output: signoff or list of corrections.
```

Loop until VER signs off.

### 3c. Iteration checkpoint — user gate

After VER signs off the execution report, the orchestrator invokes a user-gated checkpoint before exiting the skill. This closes the explore↔execute loop: verification results flow back to the user, who decides what happens next.

**Escape hatch**: if `HARNESS_DISABLE_CHECKPOINT=1` is set, skip the checkpoint entirely — the skill exits after Phase 3b signoff. For CI / automation contexts where user interaction is impossible.

**Default behavior**: call `AskUserQuestion` with exactly three options:

- **(a) Enter next iteration via `/explore`** — verification revealed a spec gap or new strategic question; want to iterate on the bet itself.
- **(b) Fix-forward in current iteration** — verification revealed implementation issues but the spec is sound; want another `/execute` cycle on the same criteria.
- **(c) Accept and exit** — all ACs passed, no further iteration needed.

If the user picks **(a)**, prompt them for **at least one sentence** describing "what must change in the next iteration." This text (the user's typed rationale) is appended to `.iteration-<N+1>/decision-log.md` so the next `/explore` session inherits the reason for re-entering the loop. Do not accept a Y/N or empty reply — the freetext entry is the whole point of the gate (prevents rubber-stamping per SKP's "gate fatigue" concern from the explore session).

If the user picks **(b)** or **(c)**, no freetext is required; the skill records the choice in the report and exits.

In all cases, log the chosen option and (if (a)) the freetext to the Phase 3 report appendix.

---

## Failure Protocols

| Failure | Flow |
|---------|------|
| Build failure   | VER detects → IMP fixes → VER re-runs gates |
| Test failure    | VER reports → PLN decides (real bug vs outdated test) → IMP fixes → VER re-verifies |
| Regression      | VER detects → ALL STOP → PLN decides fix/revert → IMP acts → VER clears full registry |
| Role disagreement | Criteria text is the tiebreaker. Ambiguous criteria → STOP, ask user |

---

## Anti-patterns

- ❌ Orchestrator inlining IMP/PLN/VER work instead of dispatching subagents.
- ❌ Bypassing the gate hook by trying `Edit`/`Write` directly (the hook will exit 2).
- ❌ IMP marking its own ACs as passed.
- ❌ VER writing production code.
- ❌ PLN skipping VER's audit of the report.
- ❌ Any role saying "it probably works" without evidence.
- ❌ Implementing multiple increments before VER verifies.
- ❌ Proceeding past a VER STOP signal.
- ❌ Creative exploration beyond the criteria (→ exit and use `/explore`).
- ❌ VER passing an AC without registering a verification method.
- ❌ Running regression checks without consulting `.harness/verification-registry.json`.
- ❌ Registering "manual-check" when an automated verification is feasible.
- ❌ Writing production code before Phase 1.5's verification corpus is materialized and confirmed failing.
- ❌ VER softening, skipping, or rewriting a `.harness/verifications/` file to make an increment pass. Tests are adversarial by design — if they're wrong, raise to PLN.
- ❌ A `.harness/verifications/ac-<id>/` bundle that covers only the happy path. Adversarial + edge are mandatory when feasible.
- ❌ IMP modifying `.harness/verifications/` during an implementation dispatch. That directory is only touched during Phase 1.5 (or an explicit PLN-approved harness revision).

## Transition Rules

- Criteria **ambiguous** → PLN pauses, orchestrator asks user.
- **Better approach** discovered mid-increment → note in log, suggest `/explore` after current increment.
- **All ACs pass** → VER signs off, PLN writes report, exit skill.
