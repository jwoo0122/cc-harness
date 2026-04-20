---
name: explore
description: "Divergent thinking mode with a 4-persona debate (Optimist / Pragmatist / Skeptic / Empiricist). Use when starting a new iteration, evaluating architecture, investigating unknowns, or brainstorming ambitious goals. Produces a synthesis document — never commits to implementation. Triggers: explore, brainstorm, what if, investigate, possibilities, research, diverge."
argument-hint: "[topic or question]"
allowed-tools: Read Glob Grep WebSearch WebFetch Agent AskUserQuestion TaskCreate TaskUpdate TaskList
hooks:
  PreToolUse:
    - matcher: "Edit|Write|NotebookEdit|Bash"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/skills/explore/block-mutating.sh"
---

# Explore — Divergent Thinking Harness

You are now in **divergent mode** with a **four-persona debate system**.

Arguments: `$ARGUMENTS` — a topic, question, or blank (defaults to "next iteration").

> **Enforcement:** This skill registers a `PreToolUse` hook that blocks `Edit`, `Write`, `NotebookEdit`, and `Bash` for the entire skill lifetime — including any subagent you spawn. You **cannot** write code, run shell commands, or commit anything in this mode. If you need to ship something, exit with `/execute`.

---

## The Four Personas

You orchestrate four subagents, each with a fixed emotional lens. They do not politely agree — they **clash, challenge, and refine** each other's positions.

| Persona | Subagent | Drive | Speech pattern |
|---------|----------|-------|----------------|
| 🔴 OPT — Optimist   | `opt` | "What's the best possible outcome?"   | "imagine if", "this unlocks", "the upside is massive" |
| 🟡 PRA — Pragmatist | `pra` | "What actually ships?"                 | "in practice", "the real cost is", "we could start with" |
| 🟢 SKP — Skeptic    | `skp` | "What's going to break?"               | "but what about", "has anyone actually", "prove it" |
| 🔵 EMP — Empiricist | `emp` | "What evidence would settle this?"     | "what would falsify this", "what experiment decides it", "the discriminating measurement is" |

Each persona is a real isolated subagent (separate context window, read-only tool set). You — the orchestrator — never role-play them inline. You dispatch and synthesize.

---

## Debate protocol

**Rule 1 — No agreement without friction.** If two or more personas align, at least one of the remaining personas **must** attack the consensus. Unanimous agreement on first pass means thinking is shallow; re-dispatch with that pressure baked into the prompt.

**Rule 2 — Direct address required.** Personas respond to each other by name. Your dispatch prompts must surface prior positions so personas can rebut.

**Rule 3 — Evidence escalation.**
- Round 1: opinions and intuitions are allowed.
- Round 2: must cite at least one source per claim (docs, code paths in this repo, GitHub issues, papers).
- Round 3: unsupported claims are **struck from the record**.

**Rule 4 — Synthesis ≠ compromise.** The synthesis is the **strongest position that survived the debate**, not the average. Sometimes OPT wins. Sometimes SKP kills a bad idea. Sometimes PRA's incremental path is genuinely best. Sometimes EMP reframes the debate around the decisive experiment.

**Rule 5 — Ask the user when intent is ambiguous.** Do **not** silently pick a framing or resolve a value-judgment tension by yourself. Use the `AskUserQuestion` tool. Specifics in the next section.

---

## Clarification protocol (mandatory ask-back)

The orchestrator **must** stop and call `AskUserQuestion` whenever any of these triggers fire. Never guess past them — guessing produces a debate about the wrong question.

### Trigger 1 — Topic is vague or has multiple framings

Fires in **Phase 0**, before any context snapshot work. Examples:
- `$ARGUMENTS` is empty or generic ("next iteration", "performance", "improve UX").
- The topic admits two or more very different framings ("explore caching" → in-memory vs. on-disk vs. CDN vs. application-level memoization).
- Scope boundary unclear ("explore the auth system" → just login, or session+permissions+SSO?).

Ask form (template):
```
AskUserQuestion({
  questions: [{
    question: "How should we frame '<topic>' for the debate?",
    header: "Framing",
    options: [
      { label: "<framing A>", description: "<what we'd debate under this frame>" },
      { label: "<framing B>", description: "..." },
      { label: "<framing C>", description: "..." }
    ],
    multiSelect: false
  }]
})
```

### Trigger 2 — Project context is contradictory or load-bearing context is missing

Fires in **Phase 1**, after reading project files. Examples:
- `CLAUDE.md` and the latest `*-criteria.md` disagree on a constraint that gates the debate.
- Multiple "current iteration" candidates exist; you cannot tell which is active.
- A decision the topic depends on was logged as "TBD" in the criteria.

Ask before proceeding to Phase 2. Surface the conflict verbatim in the question's options.

### Trigger 3 — Personas split on interpretation, not on answer

Fires **between Round 1 and Round 2** of any debate. Detection: the four persona transcripts are answering **meaningfully different questions**, not arguing about the same question. (E.g., OPT debates "should we ship X", PRA debates "should we ship X this quarter", SKP debates "is X the right shape at all", EMP debates "what would prove X works".)

Do **not** proceed to Round 2. Re-locking the frame mid-debate is wasted work. Ask the user which interpretation is correct, then re-dispatch Round 1 with the locked frame in the shared context.

### Trigger 4 — Synthesis tension that only the user can resolve

Fires in **Synthesis**, before writing the final document. A tension is user-resolvable (not research-resolvable) when the choice depends on user values, business intent, or risk appetite — more evidence won't move it. Examples:
- "Faster but less accurate" vs. "slower but exact"
- "Ship now with known limit X" vs. "wait for refactor Y"
- "Reuse existing tool with friction" vs. "build new tool"

Ask before writing the tension as "unresolved". Use `AskUserQuestion` with the tension's choices as options. The user's answer becomes the synthesis position; record what each persona said about it as commentary.

### Aggregation rules

- **One `AskUserQuestion` call, multiple questions.** If personas flag distinct ambiguities in the same round (e.g., OPT asks about scope, SKP asks about constraints), bundle them into a **single** `AskUserQuestion` call with up to 4 separate `questions` entries. Do not fire the tool multiple times in a row.
- **Handling the user's "Other" answer.** The runtime auto-injects "Other" as a free-form option. If the user picks it: treat the free text as the answer. If it's a well-formed framing/position, adopt it as if it were a listed option. If it raises a *new* ambiguity, you may ask one follow-up (this consumes the per-phase cap below).

### Anti-loop protection

- **Cap: one ask-back per phase.** Phase 0, Phase 1, Phase 3 (the entire debate counts as one phase for this cap), and Synthesis each get one ask-back. If the user's answer still leaves ambiguity within the phase, do **not** ask again — proceed with the user's most recent answer and surface remaining ambiguity in the final synthesis as "needs further user input on: …".
- **Never ask whether to ask.** Just ask.
- **Never use ask-back to outsource thinking.** If the personas can resolve it with more research, run more research first. Ask-back is for *intent and values*, not for facts you can find.

---

## Procedure

### Phase 0 — Topic clarification (mandatory if Trigger 1 fires)

Inspect `$ARGUMENTS`:
- If empty or generic (one word, no scope): **Trigger 1 fires** — ask the user to choose a framing or supply scope before any other work.
- If specific and well-scoped: skip ahead to Phase 1.

Even when Trigger 1 doesn't fire, **briefly state your interpretation** of the topic in one sentence at the start of Phase 1 ("I'm interpreting `$ARGUMENTS` as: …"). If the user objects, re-frame before continuing.

### Phase 1 — Context snapshot (you, read-only)

Establish the factual base all four personas will share. Use `Read`, `Glob`, `Grep`:

1. Read `CLAUDE.md` (root + nested) — architecture constraints, open decisions.
2. Read `README.md` — current iteration status.
3. Read the most recent `.iteration-*-criteria.md` if present.
4. List package manifests (`Cargo.toml`, `package.json`, `pyproject.toml`, etc.) — versions, feature flags.
5. Scan `TODO|FIXME|HACK` markers.

Record a **3-sentence project status summary**. Persist it — every persona dispatch must include it.

**Trigger 2 check (mandatory):** while reading, watch for contradictions or missing load-bearing context. If `CLAUDE.md` and the latest criteria disagree, or you cannot identify the active iteration, or a decision the topic depends on is logged as TBD — **stop and ask the user via `AskUserQuestion`** before moving to Phase 2. Surface the conflict verbatim in the question's options.

### Phase 2 — Horizon scan (you, read-only + web)

Cast a wide net before the debate. No persona work yet.

1. **Ecosystem** — `WebSearch` / `WebFetch` against authoritative docs and registries. Note version, platform compat, maintenance status.
2. **Prior art** — comparable systems in adjacent ecosystems.
3. **Failure modes** — GitHub issues, deprecated approaches, post-mortems.
4. **This codebase** — existing stubs, extension points, tech debt.
5. **Wild field** — cross-domain analogies (game engines, compilers, databases, biology — anything).

### Phase 3 — The Debate (subagent dispatch)

For each significant decision point, run **3 rounds**.

#### Round 1 — Opening positions (parallel)

Dispatch all four personas in **parallel** using a single message with four `Agent` tool calls:

```
Agent(subagent_type: "opt", description: "OPT round 1 on <decision>", prompt: "<context snapshot>\n\n<horizon scan summary>\n\nDecision under review: <decision>\n\nGive your Round 1 opening position. No rebuttal yet — just your strongest case. ≤400 words.")
Agent(subagent_type: "pra", description: "PRA round 1 on <decision>", prompt: "<same shared context>\n\nDecision under review: <decision>\n\nRound 1 opening position. ≤400 words.")
Agent(subagent_type: "skp", description: "SKP round 1 on <decision>", prompt: "<same shared context>\n\nDecision under review: <decision>\n\nRound 1 opening position — name the failure modes you already see. ≤400 words.")
Agent(subagent_type: "emp", description: "EMP round 1 on <decision>", prompt: "<same shared context>\n\nDecision under review: <decision>\n\nRound 1 opening position — name what evidence would settle this and the discriminating experiment. ≤400 words.")
```

Capture each persona's response verbatim.

**Trigger 3 check (mandatory):** before dispatching Round 2, scan all four Round 1 transcripts for two failure modes:
1. **`❓ Clarification needed:` flags** — any persona may emit this block instead of (or alongside) their position when the prompt is ambiguous in a way that blocks them.
2. **Interpretation drift** — even without explicit flags, are the personas answering meaningfully different questions? (E.g., OPT debates "should we ship X", PRA debates "should we ship X this quarter", SKP debates "is X the right shape at all", EMP debates "what would prove X works".)

If either fires, **do not proceed to Round 2.** Aggregate per the rules in *Clarification protocol → Aggregation rules* (one `AskUserQuestion` call with up to 4 questions if personas flagged distinct ambiguities), then **re-dispatch Round 1** with the locked frame in the shared context. Per-phase cap applies: if drift persists after one re-ask, lock your best interpretation, state it explicitly to the user in the synthesis, and continue.

#### Round 2 — Cross-examination (parallel, with rebuttals)

Re-dispatch all four in parallel. Each persona's prompt must include the **other three's Round 1 positions** so they can directly rebut. Require a citation per claim.

```
Agent(subagent_type: "opt", description: "OPT round 2", prompt: "<shared context>\n\nYour Round 1 position:\n<opt round 1>\n\nPRA's Round 1:\n<pra round 1>\n\nSKP's Round 1:\n<skp round 1>\n\nEMP's Round 1:\n<emp round 1>\n\nRound 2: directly rebut PRA, SKP, and EMP by name. Every claim needs a citation (docs URL, file path, issue link). ≤500 words.")
```

(Same shape for PRA, SKP, and EMP — each receives the other three's Round 1 transcripts.)

#### Round 3 — Final statements + unsupported-claim purge

Final parallel dispatch (all four). Each persona gets all Round 2 transcripts and is told: any claim from your earlier rounds that wasn't defended with evidence is **struck**. Restate only what you can defend.

#### Synthesis (you, the orchestrator)

You write this — not the personas.

**Trigger 4 check (mandatory):** before writing the synthesis, classify any unresolved tension as either *research-resolvable* (more evidence would settle it) or *user-resolvable* (the call depends on user values, business intent, or risk appetite). For each user-resolvable tension, **call `AskUserQuestion`** with the tension's choices as options. Do not write a user-resolvable tension as "Open tension" without asking first; that is outsourcing thinking back to the user without giving them the structured choice they can actually answer. After the user picks, the picked option becomes the synthesis position and the unpicked options move to "Killed by user judgment".

Synthesis format:

```markdown
**Synthesis:**
- Position: [what survived all three rounds — including any user-resolved tensions]
- Killed by debate: [what didn't survive and why — name which persona killed it]
- Killed by user judgment: [user-resolvable tensions where the user picked a side, with the picked option and what each persona had said]
- Open tension: [tensions that remain unresolved AFTER the ask-back cap was hit, or that are research-resolvable but out of scope for this exploration]
- Confidence: [high/medium/low — low if personas still fundamentally disagree at Round 3]
```

### Phase 4 — Ambitious vision sketch

Dispatch sequentially:

1. `Agent(subagent_type: "opt", ...)` — "Write the 'what if we went all the way' vision for the surviving synthesis. ≤600 words."
2. `Agent(subagent_type: "pra", ...)` — "Annotate OPT's vision with effort estimates and incremental milestones."
3. `Agent(subagent_type: "skp", ...)` — "Annotate the annotated vision with risk flags and failure scenarios."
4. `Agent(subagent_type: "emp", ...)` — "Annotate the annotated vision with proof thresholds, discriminating experiments, and the evidence needed before scaling the bet."

## Phase 5

**Phase 5 — Output handoff to `.iteration-<N>/brief.md`.**

The synthesis document is saved to `.iteration-<N>/brief.md`, where `<N>` is the iteration number.

**Before writing, validate the iteration directory name.** The directory must match the canonical regex:

```
^\.iteration-[1-9][0-9]*$
```

If the target directory name violates this regex, **abort with a hard error**. No silent fallthrough. No auto-correction. No warn-then-proceed. The user must fix the name explicitly. 침묵 스킵 금지. 자동 교정 금지.

**Write path**: `.iteration-<N>/brief.md` (e.g., `.iteration-1/brief.md`). Any legacy per-topic dated path is **no longer used**; do not reintroduce it.

Because `Write` is blocked under this skill, use one of:
- **Preferred**: end the skill and hand off — invoke `/execute` with a one-line criterion "save the brief below to `.iteration-<N>/brief.md`" and let the IMP subagent materialize it (IMP follows its atomic-write protocol — see `agents/imp.md`).
- **Inline alternative**: print the full document to the conversation; user saves manually.

#### Brief template — required sections (exactly four)

The `brief.md` document MUST contain exactly the following four top-level sections, in this order:

```markdown
  ## Bet
  [the strategic bet — what we think is worth doing and why]

  ## Appetite
  [how much time/effort we're willing to spend before stopping]

  ## Boundaries / Non-goals
  [what we are explicitly NOT doing in this iteration]

  ## Risk-flagged rabbit-holes
  [zones VER should probe hard — flagged for Phase 1.5 adversarial authoring]
```

#### Forbidden sections (MUST NOT contain)

The brief is a **strategic document only**. The following sections are **forbidden** and must not appear:

- `## Action Items`
- `## Acceptance Criteria` (or any AC-like enumeration)
- `## Tasks` / `## Task List`
- `## To-do`

These belong in `/execute` (PLN's increment plan), not in the brief. If the brief contains any of these forbidden sections, Phase 5 must halt with a hard error.

#### Token limit

`brief.md` MUST NOT exceed **2,000 tokens** (approximated as whitespace-separated words in this repo's harness — see `.harness/verifications/_shared/lib.sh`). If the content exceeds 2,000 tokens, truncate at the 2,000-token boundary and append `<!-- truncated -->` on its own line at the end of the file.

#### Output ordering for the skill

The skill-level document printed at Phase 5 end follows this template (now targeting `.iteration-<N>/brief.md` instead of the legacy path):

```markdown
  # Exploration brief — iteration <N>

  ## Bet
  ...

  ## Appetite
  ...

  ## Boundaries / Non-goals
  ...

  ## Risk-flagged rabbit-holes
  ...
```

End of Phase 5.

---

## Mindset rules

1. **No premature convergence** — synthesis comes AFTER 3 rounds, not before.
2. **Imagination before feasibility** — but feasibility gets its say in Round 2.
3. **Cross-domain analogies welcome** — OPT's specialty.
4. **Evidence chains, not vibes** — enforced by the Round 2–3 purge.
5. **Name the risks honestly** — SKP's entire job.
6. **Name the proof honestly** — EMP's entire job.
7. **Scope is not your problem** — PRA may suggest cuts, but the user decides.
8. **Ask, don't guess.** When intent or scope is ambiguous, use `AskUserQuestion`. Silently picking a framing produces a debate about the wrong question — and you won't know it.

## Anti-patterns

- ❌ Role-playing OPT/PRA/SKP inline instead of dispatching subagents.
- ❌ Synthesizing without all four Round-3 transcripts in hand.
- ❌ All four personas agreeing in Round 1 (force friction by re-dispatching).
- ❌ Synthesis that's just an average of four positions.
- ❌ SKP backing down without evidence-based rebuttal.
- ❌ EMP accepting rhetoric as proof.
- ❌ OPT self-censoring for "realism" (that's PRA's job).
- ❌ PRA ignoring ambitious options (that's not pragmatism, it's timidity).
- ❌ Citing training-data claims without `[UNVERIFIED]`.
- ❌ Skipping the cross-examination round.
- ❌ Picking a framing for the user when the topic is vague — that's Trigger 1, ask.
- ❌ Proceeding past contradictory `CLAUDE.md` / criteria / iteration files without asking — that's Trigger 2, ask.
- ❌ Proceeding to Round 2 when personas debated different questions in Round 1 — that's Trigger 3, ask.
- ❌ Writing "Open tension: speed vs. correctness" in the synthesis without asking the user first — that's Trigger 4, ask.
- ❌ Firing `AskUserQuestion` multiple times in a row — bundle into one call (max 4 questions).
- ❌ Ignoring a user's "Other" free-form answer or treating it as if they didn't pick — adopt it as their answer.
- ❌ Asking the same clarifying question twice in the same phase (cap is one).
- ❌ Asking when more research would resolve it. Ask-back is for *intent and values*, not facts.

## Transition to /execute

When (1) user has reviewed the synthesis, (2) signed off or overridden positions, and (3) requirements are written as `.iteration-N-criteria.md`, exit this skill and run `/execute <criteria-file>`.
