#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
SCRIPT="$(repo_root)/.harness/scripts/call-codex.sh"
scratch=$(mk_scratch ac-B.4-adv)
trap "cleanup_scratch $scratch" EXIT
cp "$HERE/../_shared/codex-stub/codex" "$scratch/codex"
chmod +x "$scratch/codex"
export PATH="$scratch:$PATH"
export OPENAI_API_KEY="sk-faketest0000000000000000000000000000000000000000"
export CODEX_STUB_MODE=ok

SECRETS=(
  "sk-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  "AIzaSyABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  "ghp_abcdefghijklmnopqrstuvwxyz0123456789AB"
)
{
  echo "please analyze"
  for s in "${SECRETS[@]}"; do echo "token: $s"; done
} >"$scratch/prompt"

# Run and capture stderr + any files the script may have written under
# .harness/logs/ or similar.
ROOT="$(repo_root)"
LOG_SNAPSHOT_BEFORE=$(mk_scratch ac-B.4-adv-logs-before)
if [[ -d "$ROOT/.harness/logs" ]]; then cp -R "$ROOT/.harness/logs"/* "$LOG_SNAPSHOT_BEFORE/" 2>/dev/null || true; fi
"$SCRIPT" <"$scratch/prompt" >"$scratch/out" 2>"$scratch/err" || true

# 1) stderr must not echo any secret verbatim.
for s in "${SECRETS[@]}"; do
  if grep -q -F "$s" "$scratch/err"; then
    fail "secret leaked to stderr: $s"
  fi
done
# 2) No file under .harness/logs/ written during this run may contain secrets.
if [[ -d "$ROOT/.harness/logs" ]]; then
  while IFS= read -r logf; do
    # only check files newer than script start (approx: modified < 60s ago)
    if [[ $(find "$logf" -newermt "$(date -v-60S '+%F %T' 2>/dev/null || date -d '60 seconds ago' '+%F %T')" 2>/dev/null) == "$logf" ]]; then
      for s in "${SECRETS[@]}"; do
        if grep -q -F "$s" "$logf"; then
          fail "secret persisted in log file: $logf"
        fi
      done
    fi
  done < <(find "$ROOT/.harness/logs" -type f 2>/dev/null)
fi
# 3) Stdout MAY contain the stub's fixed "ok" — but not the raw secret.
for s in "${SECRETS[@]}"; do
  if grep -q -F "$s" "$scratch/out"; then
    fail "secret echoed on stdout (pure passthrough) — stdout must be response only, not prompt echo"
  fi
done
pass "AC-B.4 adversarial"
