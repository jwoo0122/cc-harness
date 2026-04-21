# Multi-provider PLN dispatch

`/execute` orchestrates three roles (PLN, IMP, VER). By default all three run as Claude subagents. Persona prompts on the same underlying model share correlated blindspots — diverse prompts aren't diverse reasoning if every seat samples from the same weights.

This doc covers a minimum-viable escape hatch: the Phase 1 PLN planning call can be routed through OpenAI's Codex CLI.

## Usage

### Prerequisites

1. **Codex CLI installed.** `codex --version` must succeed.
2. **`OPENAI_API_KEY` exported.** A valid key with Codex access.
3. cc-harness plugin installed (you already have it if `/execute` is available).

### Enable Codex for Phase 1 PLN

Before launching `/execute`:

```bash
export HARNESS_PLN_PROVIDER=codex
# Optional — override timeout (default 60s)
export HARNESS_CODEX_TIMEOUT=90
```

Then invoke `/execute <args>` normally. The orchestrator routes Phase 1 PLN through `skills/_shared/call-codex.sh` instead of dispatching the Claude `pln` subagent.

### Disable (default)

```bash
unset HARNESS_PLN_PROVIDER
# or
export HARNESS_PLN_PROVIDER=claude
```

Orchestrator uses the traditional `Agent(subagent_type: "pln", ...)` path.

## Failure modes — loud-fail, no silent fallback

### Preflight exit 2

`⚠ Codex preflight failed: <reason>` on stderr. Reasons:

- `codex binary not found on PATH (install Codex CLI or set PATH)`
- `OPENAI_API_KEY env var is not set`
- `OPENAI_API_KEY looks invalid (length N < 20)`

On preflight exit 2, the orchestrator **MUST** emit `⚠ PLN Codex dispatch failed (rc=2); falling back to Claude subagent` on stderr and continue with Claude PLN.

### Timeout exit 3

`⚠ Codex exceeded HARNESS_CODEX_TIMEOUT=<N>s` on stderr. Default 60s. Override via `HARNESS_CODEX_TIMEOUT` (positive integer seconds). Invalid values are rejected with `⚠ HARNESS_CODEX_TIMEOUT invalid: ...` + exit 2. Orchestrator falls back to Claude PLN.

### Runtime failures (rc ≠ 0, ≠ 2, ≠ 3)

Quota exceeded, API 4xx/5xx, malformed response. Orchestrator falls back to Claude PLN with a stderr warning.

### Parse failures

If Codex's output doesn't parse as a well-formed increment plan (missing INC entries, wrong file-count bullets, no "Coverage check" line), orchestrator falls back to Claude PLN with a parse-failure warning.

## Debug tips

- **Test the wrapper directly:** `printf 'hello' | HARNESS_CODEX_TIMEOUT=10 bash skills/_shared/call-codex.sh`
- **Check the shared allowlist regex:** `source skills/_shared/_provider-allowlist.sh && echo "$HARNESS_PROVIDER_WHITELIST_REGEX"`. Commands not matching are blocked at the hook layer.
- **Verify fallback triggers:** unset `OPENAI_API_KEY` and re-run — you should see the stderr warning AND Claude PLN proceeding normally.

## Known limitations

- **Phase 1 only.** Phase 2d verdict cross-check remains Claude-only. Codex observes planning, not verification.
- **No per-persona provider mapping in `/explore`.** Persona diversification across providers is not yet wired up.
- **No correlated-error detection.** Provider diversity isn't proven by this setup — it's instrumented for future measurement.
- **Cost.** Each `/execute` invocation with `HARNESS_PLN_PROVIDER=codex` makes one extra Codex API call at Phase 1. Trivial at individual scale; worth budgeting for CI.

## Extensions on deck

1. Codex (or other providers) in the Phase 2d verdict cross-check.
2. Per-persona provider mapping in `/explore`: OPT / PRA / SKP / EMP could each get a different provider to widen debate diversity.
3. Gemini CLI support: `skills/_shared/_provider-allowlist.sh` already whitelists `gemini`; a `call-gemini.sh` wrapper is the next step.
4. Correlated-error metric (citation Jaccard per Lin et al. arXiv:2506.07962) — turn multi-provider Phase 1 outputs into an adversarial-similarity report.
