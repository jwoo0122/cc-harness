# Multi-provider PLN dispatch (iter-4, experimental)

> iter-4 seeded infra to dispatch the `/execute` Phase 1 PLN planning call through OpenAI Codex CLI as an alternative to the default Claude `pln` subagent. This document covers setup, usage, failure modes, and the iter-5 roadmap.

## Overview

cc-harness `/execute` orchestrates 3 roles (PLN, IMP, VER). By default all three run as Claude subagents (via the Claude Code `Agent` tool). The fundamental limitation: **persona-prompts on the same underlying model share correlated blindspots** — diverse personas ≠ diverse reasoning when they all sample from the same neural network.

Iter-4 introduces a **minimum-viable multi-provider escape hatch**: PLN (Phase 1 planning only) can be dispatched through OpenAI Codex CLI when `HARNESS_PLN_PROVIDER=codex` is set. All other roles remain Claude-only this iteration (see [iter-5 roadmap](#iter-5-roadmap)).

## Usage

### Prerequisites

1. **OpenAI Codex CLI installed**: `codex --version` must succeed.
2. **`OPENAI_API_KEY` exported**: a valid OpenAI API key with Codex access.
3. cc-harness plugin installed (you already have it if you're running `/execute`).

### Enabling Codex dispatch for Phase 1 PLN

Before launching `/execute`:

```bash
export HARNESS_PLN_PROVIDER=codex
# Optional — override timeout (default 60s)
export HARNESS_CODEX_TIMEOUT=90
```

Then invoke `/execute <criteria-file>` normally. The orchestrator will route Phase 1 PLN dispatch through `.harness/scripts/call-codex.sh` instead of the Claude pln subagent.

### Disabling (default)

Unset the env var or set `HARNESS_PLN_PROVIDER=claude`:

```bash
unset HARNESS_PLN_PROVIDER
# or
export HARNESS_PLN_PROVIDER=claude
```

Orchestrator uses the traditional `Agent(subagent_type: "pln", ...)` path.

## Failure modes

The Codex dispatch is **loud-fail** — no silent fallback. Failure modes:

### Preflight exit 2
`⚠ Codex preflight failed: <reason>` on stderr. Reasons:
- `codex binary not found on PATH (install Codex CLI or set PATH)` — install Codex CLI or adjust PATH.
- `OPENAI_API_KEY env var is not set` — export a valid key.
- `OPENAI_API_KEY looks invalid (length N < 20)` — use a real API key, not a placeholder.

On preflight exit 2, orchestrator **MUST** emit `⚠ PLN Codex dispatch failed (rc=2); falling back to Claude subagent` on stderr and continue with Claude PLN.

### Timeout exit 3
`⚠ Codex exceeded HARNESS_CODEX_TIMEOUT=<N>s` on stderr. Default 60s. Override via `HARNESS_CODEX_TIMEOUT` env (integer seconds). Invalid values (0, negative, non-integer) rejected with `⚠ HARNESS_CODEX_TIMEOUT invalid: ...` + exit 2.

On exit 3, orchestrator falls back to Claude PLN with stderr warning (same contract as exit 2).

### Runtime failures (rc != 0, != 2, != 3)
Codex returned non-zero for other reasons (quota exceeded, API 4xx/5xx, malformed response). Orchestrator falls back to Claude with stderr warning.

### Parse-failure fallback
If Codex's output doesn't parse as a well-formed increment plan (missing INC entries, wrong file-count bullets, no "Coverage check" line), orchestrator falls back to Claude PLN with a parse-failure warning.

## Debug tips

- **Test the wrapper directly**: `printf 'hello' | HARNESS_CODEX_TIMEOUT=10 bash .harness/scripts/call-codex.sh`
- **Check the shared allowlist regex**: `source skills/_shared/_provider-allowlist.sh && echo "$HARNESS_PROVIDER_WHITELIST_REGEX"`. Commands not matching are blocked at hook layer.
- **Verify fallback triggers**: unset `OPENAI_API_KEY` and re-run — you should see the stderr warning AND Claude PLN proceeding normally.
- **Inspect verification registry**: `jq '.entries | keys[] | select(startswith("AC-D"))' .harness/verification-registry.json` lists the 4 registered D-ACs proving the wiring.

## Known limitations

- **Phase 1 only**: Phase 2d AC verdict cross-check remains Claude-only in iter-4. Codex can only observe Phase 1 planning; it has no visibility into gate runs, AC decisions, or regression scans.
- **No batched multi-provider orchestration**: one Codex call per Phase 1, not a per-persona mapping across OPT/PRA/SKP/EMP (those live in `/explore`, unchanged this iteration).
- **No correlated-error detection**: baseline variance experiment (AC-A) measures within-provider σ only. Provider diversity isn't proven by this setup — it's **instrumented** for future measurement.
- **Cost**: each `/execute` invocation with `HARNESS_PLN_PROVIDER=codex` makes one extra Codex API call at Phase 1. At ~2K input + 400 output tokens, marginal cost is ~$0.02-0.05/session (Gemini-pricing equivalent) — trivial at individual scale, worth budgeting for CI.

## iter-5 roadmap

Planned extensions:
1. **Codex (or other providers) in Phase 2d AC verdict cross-check** — remove the iter-4 pin.
2. **Per-persona mapping in `/explore`**: OPT / PRA / SKP / EMP could each get a different provider to maximize debate diversity (subject to correlated-error baseline measurements from AC-A).
3. **Gemini CLI support**: `skills/_shared/_provider-allowlist.sh` already whitelists `gemini`; a `call-gemini.sh` wrapper is the next production artifact.
4. **Correlated-error metric** (citation Jaccard per Lin et al. arXiv:2506.07962) — convert Phase 1 PLN outputs from multiple providers into an adversarial-similarity report.
5. **Fork octopus (claude-octopus)** — if provider orchestration grows beyond 2-3 providers, fork octopus's preflight + consensus-gate machinery rather than re-inventing it.
