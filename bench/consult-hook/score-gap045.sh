#!/usr/bin/env bash
# GAP-045 Phase 4 — mechanical scoring over one tier's raw runs (*.jsonl).
# Usage: RUNS_DIR=<runs-root>/<model> bash bench/consult-hook/score-gap045.sh
# Emits one TSV row per run: id, set, arm, consulted (any guideline read —
# Read or shell), keyed_hit (keyed doc read), n_guideline_reads, webfetch, num_turns,
# duration_ms, cost_usd, input_tokens (fresh, non-cache), rep (replicate; 0 = unsuffixed).
# Answer quality is NOT scored here — blind judge is a separate step; this
# script also dumps each run's final answer to $RUNS/answers/<id>__<arm>.txt
# with no arm-identifying content beyond the filename (strip nothing — judge
# gets the text only).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
RUNS="${RUNS_DIR:-$ROOT/runs-gap045/sonnet}"
PROBES="$ROOT/probes-gap045.jsonl"
mkdir -p "$RUNS/answers"

printf 'id\tset\tarm\tconsulted\tkeyed_hit\tn_gl_reads\twebfetch\tnum_turns\tduration_ms\tcost_usd\tinput_tokens\trep\n'

for f in "$RUNS"/*.jsonl; do
  base="$(basename "$f" .jsonl)"
  stem="$base"
  rep=0
  case "$stem" in *__r[0-9]*) rep="${stem##*__r}"; stem="${stem%__r[0-9]*}" ;; esac
  id="${stem%__*}"
  arm="${stem##*__}"
  probe="$(jq -c --arg id "$id" 'select(.id==$id)' "$PROBES")"
  [ -n "$probe" ] || continue
  set_="$(jq -r '.set' <<<"$probe")"
  keyed="$(jq -r '.keyed_neighbor // empty' <<<"$probe" | sed 's|.*/||')"

  # A doc read is a Read call or a shell call (cat/head/sed) naming the doc —
  # opus reads catalog docs via Bash cat; a Read-only count scores those as misses.
  reads="$(jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | select(.name=="Read" or .name=="Bash" or .name=="PowerShell") | (.input.file_path // .input.command // "")' "$f" 2>/dev/null | grep -i 'guidelines' || true)"
  n_reads="$(grep -c . <<<"$reads" || true)"
  [ -n "$reads" ] && consulted=1 || consulted=0
  keyed_hit=0
  if [ -n "$keyed" ] && grep -qi "$keyed" <<<"$reads"; then keyed_hit=1; fi
  webfetch="$(jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | select(.name=="WebFetch" or .name=="WebSearch") | .name' "$f" 2>/dev/null | grep -c . || true)"

  meta="$(jq -r 'select(.type=="result") | [.num_turns, .duration_ms, .total_cost_usd, .usage.input_tokens] | @tsv' "$f" 2>/dev/null | head -1)"
  [ -n "$meta" ] || meta=$'\t\t\t'

  jq -r 'select(.type=="result") | .result // empty' "$f" > "$RUNS/answers/${base}.txt" 2>/dev/null || true

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$set_" "$arm" "$consulted" "$keyed_hit" "$n_reads" "$webfetch" "$meta" "$rep"
done
