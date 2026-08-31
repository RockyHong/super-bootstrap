#!/usr/bin/env bash
# GAP-069 read-out — 15 headless arms over two fixtures.
#
#   fixture 1 (d3161f3 replay, coverage axis)   cold x3 · warm x3 · opus x3
#   fixture 2 (techstack Run B, stability axis) cold x3 · warm x3
#
# Every arm runs the same inlined-scanner container; only the container framing
# (cold dispatch vs warm gateway-inline) and, for the opus row, the tier move.
# The pinned doc-sync-scan agent rejects a call-site model override, so no arm
# dispatches it — GAP-058 precedent, recorded in README.md § Container.
#
#   ./run.sh --dry-run     validate everything, invoke `claude` zero times
#   ./run.sh               run all 15 arms, sequential
#   ./run.sh f1-cold       run one arm's three repeats
#
# Raw stream-json per arm lands in runs/<fixture>__<arm>__r<N>.jsonl (+ .err).
# Scoring is human, against SCORING.md. Decontamination:
# ../consult-hook/bench-decontamination.md — cited, not hoisted.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIX="$HERE/.fixtures"
RUNS="$HERE/runs"
SETTINGS="$HERE/arm-settings.json"
N="${N:-3}"
DRY=0
ONLY=""

for a in "$@"; do
  case "$a" in
    --dry-run|-n) DRY=1 ;;
    -*) echo "unknown flag: $a" >&2; exit 2 ;;
    *) ONLY="$a" ;;
  esac
done

# arm := <label> <fixture-dir> <prompt-file> <model>
ARMS="
f1-cold|f1-d3161f3|f1-cold.txt|sonnet
f1-warm|f1-d3161f3|f1-warm.txt|sonnet
f1-opus|f1-d3161f3|f1-cold.txt|opus
f2-cold|f2-runB|f2-cold.txt|sonnet
f2-warm|f2-runB|f2-warm.txt|sonnet
"

# ---------------------------------------------------------------- preflight --
fail=0
note() { printf '   %s\n' "$*"; }
bad()  { printf '   FAIL: %s\n' "$*" >&2; fail=1; }

echo "== preflight =="

bash "$HERE/assemble-prompts.sh" >/dev/null 2>&1 \
  && note "prompts rebuilt from parts/" || bad "assemble-prompts.sh failed"

if bash "$HERE/check-key-absence.sh" >/dev/null 2>&1; then
  note "answer key absent from every arm prompt"
else
  bad "answer key leaked into an arm prompt — run ./check-key-absence.sh"
fi

for d in f1-d3161f3 f2-runB; do
  if [ -d "$FIX/$d" ]; then note "fixture present: $d"
  else bad "fixture missing: $d — run ./make-fixtures.sh"; fi
done

# f2's tree is reconstructed, not a commit — assert the Run-B revision is the
# one actually on disk, not the shipped single-awk form.
f2sh="$FIX/f2-runB/plugins/super-bootstrap/skills/commit/assets/doc-links.sh"
if [ -f "$f2sh" ] && grep -q 'for line in \$SLUG_TABLE' "$f2sh" \
   && grep -q "tr -d '\\\\000-\\\\177'" "$f2sh"; then
  note "f2 tree carries the Run-B revision (loop + all-ASCII early return)"
else
  bad "f2 tree is not the Run-B revision — re-run ./make-fixtures.sh"
fi

# f1's tree is a plain commit — assert it, cheaply.
f1head="$(git -C "$FIX/f1-d3161f3" rev-parse --short HEAD 2>/dev/null)"
[ "$f1head" = "d3161f3" ] && note "f1 tree at d3161f3" \
  || bad "f1 tree HEAD is '$f1head', expected d3161f3"

[ -f "$SETTINGS" ] && note "arm settings: $SETTINGS" || bad "arm-settings.json missing"

command -v claude >/dev/null 2>&1 && note "claude on PATH" || bad "claude not on PATH"
command -v jq >/dev/null 2>&1 && note "jq on PATH (scoring convenience)" \
  || note "jq absent — raw jsonl still lands, scoring reads it by hand"

[ "$fail" -eq 0 ] || { echo "preflight FAILED" >&2; exit 1; }
echo "   preflight OK"

# ------------------------------------------------------------------- plan ----
echo
echo "== plan =="
total=0
while IFS='|' read -r label dir prompt model; do
  [ -n "${label:-}" ] || continue
  [ -z "$ONLY" ] || [ "$ONLY" = "$label" ] || continue
  for r in $(seq 1 "$N"); do
    total=$((total + 1))
    printf '   %-8s r%s  model=%-7s cwd=%s  prompt=%s\n' \
      "$label" "$r" "$model" "$dir" "$prompt"
  done
done <<EOF
$ARMS
EOF
echo "   $total arms"
[ "$total" -gt 0 ] || { echo "no arms selected: '$ONLY'" >&2; exit 2; }

if [ "$DRY" -eq 1 ]; then
  echo
  echo "DRY RUN — no claude invocation made. Command shape per arm:"
  echo "   cd <fixture> && claude -p \"\$(cat <prompt>)\" \\"
  echo "        --model <model> --settings $SETTINGS \\"
  echo "        --disallowedTools Bash Write Edit NotebookEdit WebFetch WebSearch Task Agent \\"
  echo "        --output-format stream-json --verbose > runs/<arm>.jsonl 2> runs/<arm>.jsonl.err"
  exit 0
fi

# -------------------------------------------------------------------- run ----
mkdir -p "$RUNS"
{
  echo "date: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "claude: $(claude --version 2>&1 | head -1)"
  echo "repo HEAD: $(git -C "$HERE" rev-parse --short HEAD)"
  echo "N per arm: $N"
  echo
  echo "-- device hooks (~/.claude/settings.json) --"
  cat "$HOME/.claude/settings.json" 2>/dev/null | sed -n '/"hooks"/,$p' | head -80
  echo
  echo "-- device hook files --"
  ls -1 "$HOME/.claude/hooks" 2>/dev/null
  echo
  echo "-- arm settings sets disableAllHooks; the list above is recorded anyway,"
  echo "   per bench-decontamination.md channel 3 (record-and-compare floor) --"
} > "$RUNS/ENV.txt"
echo "   env recorded -> $RUNS/ENV.txt"

n=0
while IFS='|' read -r label dir prompt model; do
  [ -n "${label:-}" ] || continue
  [ -z "$ONLY" ] || [ "$ONLY" = "$label" ] || continue
  for r in $(seq 1 "$N"); do
    n=$((n + 1))
    out="$RUNS/${label}__r${r}.jsonl"
    echo "[$n/$total] $label r$r ($model) -> $out"
    # </dev/null: claude inherits stdin and would otherwise drain the ARMS
    # heredoc feeding the outer while-read, ending the loop after one label.
    ( cd "$FIX/$dir" && claude -p "$(cat "$HERE/prompts/$prompt")" \
        --model "$model" \
        --settings "$SETTINGS" \
        --disallowedTools Bash Write Edit NotebookEdit WebFetch WebSearch Task Agent \
        --output-format stream-json --verbose \
        < /dev/null > "$out" 2> "$out.err" )
    echo "        exit=$? lines=$(wc -l < "$out" 2>/dev/null | tr -d ' ')"
  done
done <<EOF
$ARMS
EOF

echo "DONE — $n arms in $RUNS/. Score by hand into SCORING.md."
