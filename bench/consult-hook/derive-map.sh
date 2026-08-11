#!/usr/bin/env bash
# GAP-045 Phase 0 — derive keyword→doc map from guideline index catalog tables.
# Mechanical extraction only (curated-signal constraint, spec § map derivation):
# terms = filename-stem phrase + distinctive stem tokens (len>=5, corpus df<=2)
# + backticked identifiers (len>=6) from the description cell; zero prose
# generated at derivation time.
# Usage: bash bench/derive-map.sh <index.md>... > bench/doc-map.tsv
# Output TSV per doc: <path> \t term1|term2|... \t <first-sentence why, <=140ch>
set -euo pipefail

rows=()
declare -A df

for index in "$@"; do
  dir="$(dirname "$index")"
  while IFS= read -r row; do
    [[ "$row" == \|* ]] || continue
    [[ "$row" == *---* ]] && continue
    # doc link = first same-dir .md link in the row (upstream links carry ../)
    file="$(grep -oE '\]\([a-z0-9-]+\.md\)' <<<"$row" | head -1 | sed 's/^](//; s/)$//' || true)"
    [ -n "$file" ] || continue
    # description = 2nd " | "-separated cell in both catalog shapes
    # (split on space-pipe-space so escaped \| inside backticks survives)
    why="$(awk -F' \\| ' '{print $2}' <<<"$row" | sed 's/^ *//; s/ *$//')"
    rows+=("${dir}"$'\x1f'"${file}"$'\x1f'"${why}")
    # corpus document-frequency of stem tokens (counted once per doc)
    unset seen; declare -A seen
    stem="${file%.md}"
    for tok in ${stem//-/ }; do
      [ -n "${seen[$tok]:-}" ] && continue
      seen[$tok]=1
      df[$tok]=$(( ${df[$tok]:-0} + 1 ))
    done
  done < "$index"
done

for r in "${rows[@]}"; do
  IFS=$'\x1f' read -r dir file why <<<"$r"
  why_short="$(sed 's/\. .*$/./' <<<"$why" | cut -c1-140)"
  stem="${file%.md}"
  phrase="${stem//-/ }"
  terms="$phrase"
  for tok in $phrase; do
    [ "${#tok}" -ge 5 ] && [ "${df[$tok]:-0}" -le 2 ] && terms="$terms|$tok"
  done
  while IFS= read -r bt; do
    [ "${#bt}" -ge 6 ] && terms="$terms|$(tr '[:upper:]' '[:lower:]' <<<"$bt")"
  done < <(grep -oE '`[^`]+`' <<<"$why" | tr -d '`' || true)
  terms="$(tr '|' '\n' <<<"$terms" | awk '!seen[$0]++' | paste -sd'|' -)"
  printf '%s\t%s\t%s\n' "$dir/$file" "$terms" "$why_short"
done
