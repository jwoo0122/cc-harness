# Codex peer-model integration

`/explore` and `/execute` cross models on purpose: the persona seats that do adversarial work run on the **Codex peer model**, dispatched as a peer subagent (`codex:codex-rescue`), while the generative seats stay on Claude. The goal is structural — a single model grading its own output shares blindspots; a peer model does not.

This replaces the iter-4 subprocess wrapper (`call-codex.sh`) and the provider allow-list it required. Codex now participates through the same subagent dispatch channel the Claude seats use.

## Persona mapping

| Skill | Seat | Model | Dispatch |
|-------|------|-------|----------|
| `/explore` | 🔴 OPT | Claude | `Agent(subagent_type: "opt", ...)` |
| `/explore` | 🟡 PRA | Claude | `Agent(subagent_type: "pra", ...)` |
| `/explore` | 🟢 SKP | **Codex** | `Agent(subagent_type: "codex:codex-rescue", prompt: <codex-skp-prompt.md section>)` |
| `/explore` | 🔵 EMP | Claude | `Agent(subagent_type: "emp", ...)` |
| `/execute` | 📋 PLN | Claude | `Agent(subagent_type: "pln", ...)` |
| `/execute` | 🔨 IMP | Claude | `Agent(subagent_type: "imp", ...)` |
| `/execute` | ✅ VER (phases 0, 1-review, 2a, 2d, 3) | **Codex** | `Agent(subagent_type: "codex:codex-rescue", prompt: <codex-ver-prompt.md section>)` |
| `/execute` | 🧑‍⚖️ Adversarial reviewer (end of Phase 1) | **Codex** | `Agent(subagent_type: "codex:codex-rescue", prompt: <codex-adversarial-review-prompt.md>)` |

The Codex seats chosen — SKP, VER, adversarial reviewer — are the ones whose job is to find fault in Claude's output (synthesis in `/explore`, plan and implementation in `/execute`). Keeping those seats on a different model is the point.

## Prompt templates

All Codex dispatches use self-contained templates, because Codex subagent dispatches start cold:

- `skills/_shared/codex-skp-prompt.md` — Skeptic persona (opening / rebuttal / final defense / Phase 4 annotation)
- `skills/_shared/codex-ver-prompt.md` — Verifier role (baseline / plan review / verification design / verdict / report audit)
- `skills/_shared/codex-adversarial-review-prompt.md` — end-of-Phase-1 plan review

Each file defines a persona charter block and one section per duty station. The orchestrator substitutes `{{variables}}` and passes the result as the `prompt` argument of the Codex dispatch.

## Adversarial review round

`/execute` Phase 1 ends with a dedicated round not present in iter-4:

1. PLN produces a plan.
2. IMP reviews for buildability.
3. Codex-VER reviews for verifiability.
4. If 2 or 3 raise concerns, PLN revises; loop.
5. Once 2 and 3 accept, dispatch `codex:codex-rescue` with the adversarial review template. Its charter is to find holes — goal coverage, ordering, scope leakage, hidden assumptions, failure-mode coverage, size honesty.
6. PASS → enter Phase 2. FAIL → re-dispatch PLN with findings; repeat the whole Phase 1 chain. Attempt cap 3, then escalate via `AskUserQuestion`.

Why a separate round on top of Codex-VER's verifiability review? Verifiability asks "can this be tested?" — adversarial review asks "will this actually work?" Different gates, same model, different prompts.

## Failure and fallback

Codex subagent dispatch can fail: subagent returns an error, empty body, or a body that does not match the expected output shape. The fallback contract is seat-specific because the seats have different criticality:

| Seat | On Codex error |
|------|----------------|
| Codex-SKP (`/explore`) | Fall back to `Agent(subagent_type: "skp-fallback", ...)`. Annotate synthesis: `Debate mode: mono-model (SKP fallback at <round>)`. |
| Codex-VER (`/execute`) | Fall back to `Agent(subagent_type: "ver-fallback", ...)` for that one call. Annotate run log / Phase 3 report: `VER: Claude fallback at <phase>`. |
| Adversarial reviewer (`/execute`) | **Do not fall back to Claude.** Annotate run log: `Adversarial review: Codex dispatch failed`. Proceed to Phase 2 without blocking — adversarial review is additive assurance, and a Claude self-adversarial pass is exactly the failure mode the round exists to avoid. |

Fallback annotations are mandatory. A silent fallback is a regression on the cross-model premise, and users need to see which runs were weakened.

The `skp-fallback` and `ver-fallback` subagents (`agents/skp-fallback.md`, `agents/ver-fallback.md`) hold the same charter as the Codex seats. They exist so the skill can still finish when the Codex peer is unavailable — not as a substitute for the cross-model design.

## Hook discipline

The `PreToolUse` hooks (`skills/execute/gate-mutating.sh`, `skills/explore/block-mutating.sh`) enforce tool access at the subagent level:

- `/execute` gate: only `agent_type=imp` can use `Edit` / `Write` / `NotebookEdit`. Bash is outside the matcher — Codex-VER's internal Bash (for running gates and verifications) does not reach the gate.
- `/explore` block: Edit / Write / NotebookEdit / Bash blocked for every caller **except** Bash is permitted for Codex peer subagents (`agent_type` starting with `codex:` or `codex-`). Codex needs internal Bash to execute; Claude personas do not.

The iter-4 provider allow-list (`skills/_shared/_provider-allowlist.sh`) is gone. It existed to let the orchestrator `Bash` the `call-codex.sh` wrapper from hooks that would otherwise block Bash. With peer-subagent dispatch the orchestrator never shells out to Codex — it uses the Agent tool — so the allow-list has no remaining job.

## Prerequisites for the Codex seats

- The `codex:codex-rescue` subagent must be available in the session. Check with `/codex:setup` if `Agent(subagent_type: "codex:codex-rescue", ...)` errors with "unknown subagent".
- Codex CLI must be installed and authenticated where the Claude Code runtime executes. Installation / auth is outside the scope of this harness — fix it once, then the peer dispatch works across every skill run.

If the peer is not reachable at all, every dispatch to it will fall back (or, in the adversarial review case, skip). The skill still runs — just in the weaker mono-model state, annotated as such.

## Why not also run PLN / OPT / PRA / EMP on Codex?

Out of scope for this iteration. The current design puts Codex where it breaks self-confirmation most — failure-mode seats (SKP), verdict seats (VER), and the adversarial gate. Putting additional generative seats on Codex is a debate-diversity experiment, not a structural fix, and belongs behind a dedicated measurement (e.g., correlated-error metrics) rather than a flag.
