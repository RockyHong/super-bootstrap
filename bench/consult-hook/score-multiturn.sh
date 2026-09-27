#!/usr/bin/env bash
# DEBT-122 — turn-indexed mechanical scoring over one tier's multi-turn sessions.
# Usage: RUNS_DIR=<runs-root>/<model> bash bench/consult-hook/score-multiturn.sh
# Input: run-multiturn.py raw files <script>__<arm>[__r<rep>].jsonl; turns are
# delimited by the driver-written {"type":"bench_turn","turn":k,"id":...} lines.
# Emits one TSV row per turn: session, turn, id, set, arm, consulted (any
# guideline read — Read or shell), keyed_hit (keyed doc read), n_gl_reads,
# input_tokens (fresh, non-cache, that turn's result.usage), cache_creation_tokens
# + cache_read_tokens (same usage — the per-turn re-injection cost of arm (a)
# lands in cache_creation, not in fresh input), cost_usd (that
# turn's share: result.total_cost_usd is session-cumulative, so the delta from
# the prior turn), duration_ms, rep (replicate; 0 = unsuffixed).
# Doc-access rule identical to score-gap045.sh. Dumps each turn's final answer
# to $RUNS/answers/<script>__<arm>[__r<rep>]__t<k>.txt.
# Summary to stderr, per arm: pooled keyed recall on consult turns >= 2, TN on
# no-consult turns >= 2 (turn 1 is the injection turn, identical across arms),
# mean fresh input_tokens and mean cache_creation_tokens per turn (all turns).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
RUNS="${RUNS_DIR:-$ROOT/runs-multiturn/sonnet}"
PROBES="$ROOT/probes-gap045.jsonl"
mkdir -p "$RUNS/answers"
# jq on Windows emits CRLF; strip CR so ids/fields compare and join cleanly
jq() { command jq "$@" | tr -d '\r'; }

rows=""
hdr=$'session\tturn\tid\tset\tarm\tconsulted\tkeyed_hit\tn_gl_reads\tinput_tokens\tcache_creation_tokens\tcache_read_tokens\tcost_usd\tduration_ms\trep'
printf '%s\n' "$hdr"

for f in "$RUNS"/*.jsonl; do
  [ -e "$f" ] || continue
  base="$(basename "$f" .jsonl)"
  stem="$base"
  rep=0
  case "$stem" in *__r[0-9]*) rep="${stem##*__r}"; stem="${stem%__r[0-9]*}" ;; esac
  session="${stem%%__*}"
  arm="${stem#*__}"

  # tag every event with the turn of the last bench_turn marker seen
  ann="$(jq -nc 'foreach inputs as $e ({t:0,id:null,e:null};
           if $e.type=="bench_turn" then {t:$e.turn,id:$e.id,e:null} else .e=$e end;
           select(.e!=null))' "$f" 2>/dev/null)"
  turns="$(jq -r 'select(.type=="bench_turn") | "\(.turn)\t\(.id)"' "$f" 2>/dev/null)"
  prev_cost=0
  while IFS=$'\t' read -r k id; do
    [ -n "$k" ] || continue
    probe="$(jq -c --arg id "$id" 'select(.id==$id)' "$PROBES")"
    [ -n "$probe" ] || continue
    set_="$(jq -r '.set' <<<"$probe")"
    keyed="$(jq -r '.keyed_neighbor // empty' <<<"$probe" | sed 's|.*/||')"
    tev="$(jq -c --argjson k "$k" 'select(.t==$k) | .e' <<<"$ann")"

    # A doc read is a Read call or a shell call (cat/head/sed) naming the doc —
    # opus reads catalog docs via Bash cat; a Read-only count scores those as misses.
    reads="$(jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | select(.name=="Read" or .name=="Bash" or .name=="PowerShell") | (.input.file_path // .input.command // "")' <<<"$tev" 2>/dev/null | grep -i 'guidelines' || true)"
    n_reads="$(grep -c . <<<"$reads" || true)"
    [ -n "$reads" ] && consulted=1 || consulted=0
    keyed_hit=0
    if [ -n "$keyed" ] && grep -qi "$keyed" <<<"$reads"; then keyed_hit=1; fi

    res="$(jq -c 'select(.type=="result")' <<<"$tev" | head -1)"
    if [ -n "$res" ]; then
      meta="$(jq -r --argjson pc "$prev_cost" '[.usage.input_tokens, (.usage.cache_creation_input_tokens // 0), (.usage.cache_read_input_tokens // 0), (((.total_cost_usd // 0) - $pc) * 1e7 | round / 1e7), .duration_ms] | @tsv' <<<"$res")"
      prev_cost="$(jq -r '.total_cost_usd // 0' <<<"$res")"
      jq -r '.result // empty' <<<"$res" > "$RUNS/answers/${base}__t${k}.txt"
    else
      meta=$'\t\t'
    fi

    row="$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' "$session" "$k" "$id" "$set_" "$arm" "$consulted" "$keyed_hit" "$n_reads" "$meta" "$rep")"
    printf '%s\n' "$row"
    rows+="$row"$'\n'
  done <<<"$turns"
done

# summary — cols: 2 turn, 4 set, 5 arm, 6 consulted, 7 keyed_hit, 9 input_tokens, 10 cache_creation_tokens
printf '%s' "$rows" | awk -F'\t' '
  NF < 14 { next }
  { arms[$5] = 1; nt[$5]++; tok[$5] += $9; cct[$5] += $10 }
  $2 >= 2 && $4 == "consult"    { cc[$5]++; hit[$5] += $7 }
  $2 >= 2 && $4 == "no-consult" { nc[$5]++; if ($6 == 0) tn[$5]++ }
  END {
    print "== summary (turns >= 2 for recall/TN; tokens over all turns) =="
    for (a in arms)
      printf "%s\tkeyed_recall=%d/%d\tTN=%d/%d\tmean_fresh_input_tokens=%.1f\tmean_cache_creation_tokens=%.1f (n=%d turns)\n",
        a, hit[a], cc[a], tn[a], nc[a], (nt[a] ? tok[a] / nt[a] : 0), (nt[a] ? cct[a] / nt[a] : 0), nt[a]
  }' >&2
