#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
ROOT="$(repo_root)"
SHARED="$ROOT/skills/_shared/_provider-allowlist.sh"
[[ -f "$SHARED" ]] || fail "shared allowlist missing"

providers=()
while IFS= read -r line; do
  providers+=("$line")
done < <(grep -oE '\b(codex|gemini|[a-z]{3,20})\b' "$SHARED" \
  | sort -u | grep -vE '^(bash|else|then|case|esac|fi|do|done|local|export|set|echo|cat|grep|awk|sed|if)$')

missing=()
for p in "${providers[@]}"; do
  if [[ "$p" =~ ^(sh|source|agent|tool|input|command|name|type)$ ]]; then continue; fi
  if [[ "$p" == "codex" && ! -x "$ROOT/skills/_shared/call-codex.sh" ]]; then
    missing+=("codex")
  fi
done
(( ${#missing[@]} == 0 )) || fail "providers listed but script missing: ${missing[*]}"
pass "AC-C.3 edge"
