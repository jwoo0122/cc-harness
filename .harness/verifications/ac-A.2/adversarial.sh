#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../_shared/lib.sh"
IN="$(repo_root)/.harness/experiments/baseline-variance/inputs"
# bash-3.2-compatible replacement for `mapfile -t files < <(...)`
files=()
while IFS= read -r line; do
  files+=("$line")
done < <(find "$IN" -maxdepth 1 -type f | sort)
(( ${#files[@]} >= 3 )) || fail "need >=3 files for diversity check"
hashes=()
while IFS= read -r line; do
  hashes+=("$line")
done < <(shasum -a 256 "${files[@]}" | awk '{print $1}')
uniq_hashes=$(printf '%s\n' "${hashes[@]}" | sort -u | wc -l | tr -d ' ')
(( uniq_hashes == ${#files[@]} )) || fail "duplicate corpus files detected (hash collision)"
tmp=$(mk_scratch ac-A.2)
trap "cleanup_scratch $tmp" EXIT
: >"$tmp/tops"
for f in "${files[@]}"; do
  tr '[:space:][:punct:]' '\n' <"$f" | awk 'length($0)>=5' \
    | tr '[:upper:]' '[:lower:]' \
    | grep -vE '^(about|would|there|their|which|where|these|those|other|after|could|should|still|being)$' \
    | sort | uniq -c | sort -rn | head -1 | awk '{print $2}' >>"$tmp/tops"
done
distinct_tops=$(sort -u "$tmp/tops" | wc -l | tr -d ' ')
(( distinct_tops >= 2 )) || fail "topic mono-culture: all corpus files share top keyword"
pass "AC-A.2 adversarial (distinct tops=$distinct_tops)"
