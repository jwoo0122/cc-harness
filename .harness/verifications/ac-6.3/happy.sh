#!/usr/bin/env bash
set -euo pipefail
source "$(git rev-parse --show-toplevel)/.harness/verifications/_shared/lib.sh"

ROOT="$(repo_root)"
F="$ROOT/README.md"
[[ -f "$F" ]] || fail "README.md missing"

MAX=0
MAXLABEL=""

while IFS= read -r startline; do
  ln="${startline%%:*}"
  next="$(awk -v start="$ln" 'NR>start && /^## / {print NR; exit}' "$F" || true)"
  if [[ -z "$next" ]]; then next=$(wc -l < "$F"); fi
  span=$(( next - ln ))
  if (( span > MAX )); then MAX=$span; MAXLABEL="heading@L$ln"; fi
done < <(grep -nE '^##+[[:space:]]+(Install|Use it|Usage)\b' "$F" || true)

while IFS= read -r hit; do
  ln="${hit%%:*}"
  start=$(awk -v L="$ln" 'NR<=L && /^[[:space:]]*$/ {last=NR} END {print last+1}' "$F")
  end=$(awk -v L="$ln" 'NR>=L && /^[[:space:]]*$/ {print NR; exit}' "$F")
  [[ -z "$end" ]] && end=$(wc -l < "$F")
  span=$(( end - start ))
  if (( span > MAX )); then MAX=$span; MAXLABEL="slashcmd@L$ln"; fi
done < <(grep -nE '/plugin (marketplace add|install)' "$F" || true)

ok "largest install-block span = $MAX lines ($MAXLABEL) (limit 15)"

if (( MAX > 15 )); then
  fail "install block exceeds 15 lines ($MAX @ $MAXLABEL)"
fi
pass "ac-6.3 happy PASS (max=$MAX)"
