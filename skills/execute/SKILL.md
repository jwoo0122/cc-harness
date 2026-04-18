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
  📋 PLN ──── defines scope ────► 🔨 IMP ──── code ────► ✅ VER
    ▲                                ▲                       │
    │         challenges             │       challenges      │
    ◄────────────────────────────────┤◄──────────────────────┘
    │                                │                       ▲
    │         challenges             │       challenges      │
    └────────────────────────────────►───────────────────────►┘

  No role marks its own output as correct.
  VER never writes code. IMP never says "AC passed". PLN never runs tests.
```

---

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

#### 2c. VER runs verification

**Dispatch VER** based on what changed:
- Unit-level changes → run the test suite
- UI/renderer changes → invoke project-specific verification skills if available
- API changes → integration tests

VER must produce a **registrable verification** for each AC: a specific, reproducible command. "I eyeballed it" is not registrable.

#### 2d. VER checks ACs

**Dispatch VER**:

```
For each AC in scope of INC-[N], output:
| AC     | Status  | Evidence (specific proof) | Registrable verification (strategy + command + files + description) |
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

### Phase 3 — Completion Report (PLN writes, VER audits)

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

## Transition Rules

- Criteria **ambiguous** → PLN pauses, orchestrator asks user.
- **Better approach** discovered mid-increment → note in log, suggest `/explore` after current increment.
- **All ACs pass** → VER signs off, PLN writes report, exit skill.
