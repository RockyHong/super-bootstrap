#!/usr/bin/env bash
# score.sh — assertions (a)-(e) over one run's final output and its fixture.
# Usage: bash bench/session-close-judgment/score.sh <out-file> <fixture-dir>
# Prints one PASS or FAIL line per assertion, each FAIL naming what it found, and exits 1 on any
# FAIL in (a)-(d). (e) gates across a wording's runs, so it prints PASS or MISS here and
# score-wording.sh counts it.
set -u
out="${1:?usage: score.sh <out-file> <fixture-dir>}"
fx="${2:?fixture dir}"
here="$(cd "$(dirname "$0")" && pwd)"
fails=0
fail() { echo "FAIL $1"; fails=$((fails + 1)); }

# One line per pick row: name<TAB>row text. A row runs from its `[name]` bullet to the next row,
# or to the first unindented non-bullet line.
rows() {
  tr -d '\r' < "$out" | awk '
    function flush() { if (name != "") print name "\t" text; name = ""; text = "" }
    {
      line = $0; probe = line
      sub(/^[ \t]*([-*]|[0-9]+\.)[ \t]+/, "", probe)
      if (probe != line) { gsub(/^\*+/, "", probe) }
      if (probe != line && probe ~ /^\[[^]]+\]/) {
        flush()
        name = probe; sub(/^\[/, "", name); sub(/\].*/, "", name)
        text = probe
        next
      }
      if (name != "" && (line ~ /^[ \t]/ || line == "")) { text = text " " line; next }
      flush()
    }
    END { flush() }'
}
all_rows="$(rows)"
named() { printf '%s\n' "$all_rows" | awk -F'\t' -v k="$1" 'tolower($1) ~ k'; }

# (a) the bounded in-repo finding is a fix-now row; the coined term is a register row, drafted.
fix_rows="$(named '^fix-now')"
log_rows="$(named '^log')"
a_ok=1
if ! printf '%s\n' "$fix_rows" | grep -q 'maintenance\.md' || ! printf '%s\n' "$fix_rows" | grep -q '14'; then
  fail "(a) no [fix-now] row names docs/maintenance.md with 14. Rows: $(printf '%s\n' "$all_rows" | cut -f1 | tr '\n' ' ')"
  a_ok=0
fi
if printf '%s\n' "$log_rows" | grep -q 'maintenance\.md'; then
  fail "(a) the seal-interval finding is routed to log: $(printf '%s\n' "$log_rows" | grep 'maintenance\.md' | cut -f2 | cut -c1-160)"
  a_ok=0
fi
[ "$a_ok" = 1 ] && echo "PASS (a) the seal-interval finding is a fix-now row"
# Non-gating: the door's judgment returned the coined term, drafted. This is the judge's recall.
if [ -n "$(named '^register')" ] && tr -d '\r' < "$out" | grep -Eqi '\*\*recovery ramp\*\*:'; then
  echo "INFO (a) register recall: hit"
else
  echo "INFO (a) register recall: miss"
fi

# (b) each log row states why it cannot finish now, by closure, investigation or ownership.
b_ok=1
for want in 'brindle-firmware|baud' 'humidity'; do
  if ! printf '%s\n' "$log_rows" | grep -Eqi "$want"; then
    fail "(b) no [log] row for the finding matching '$want'"
    b_ok=0
  fi
done
while IFS= read -r row; do
  [ -n "$row" ] || continue
  text="$(printf '%s\n' "$row" | cut -f2)"
  if ! printf '%s\n' "$text" | grep -Eqi '(^|[^a-z])own|(another|other|separate|different) repo|outside this repo|closure|propagat|investigat|unrelated read|root.cause'; then
    fail "(b) [log] row names no reason: $(printf '%s' "$text" | cut -c1-160)"
    b_ok=0
  fi
  if printf '%s\n' "$text" | grep -Eqi '(^|[^a-z])(context|tokens?|window)([^a-z]|$)'; then
    fail "(b) [log] row reasons by session load: $(printf '%s' "$text" | cut -c1-160)"
    b_ok=0
  fi
done <<ROWS
$log_rows
ROWS
[ "$b_ok" = 1 ] && echo "PASS (b) every log row names its reason"

# (c) an unearned return gets no move and no ask: a row whose subject is a general word or the
# homonym, or a line that asks or offers a ruling on a skip. A row's subject is its first sentence;
# later sentences, and commit and close rows, hold narration, which the INFO count below reports.
general='webhook|backoff|mqtt|local cache'
homonym="(^|[^A-Za-z])Hold([^a-z]|\$)|[\"'\`]hold[\"'\`]"
c_ok=1
move_rows="$(printf '%s\n' "$all_rows" | grep -Eiv '^(commit|close)' | cut -f2 | sed -e 's/\. .*$//')"
hit="$(printf '%s\n' "$move_rows" | grep -Ein "$general" | head -1 | cut -c1-160)"
if [ -n "$hit" ]; then fail "(c) row for a general word: $hit"; c_ok=0; fi
hit="$(printf '%s\n' "$move_rows" | grep -En "$homonym" | head -1 | cut -c1-160)"
if [ -n "$hit" ]; then fail "(c) row for the homonym 'Hold': $hit"; c_ok=0; fi
hit="$(tr -d '\r' < "$out" | grep -Ein 'recommend[^.]*skip|skip[^.]*recommend|lean[^.]*skip|skip[^.]*lean|not worth|no need to (register|link|log)' | head -1 | cut -c1-160)"
if [ -n "$hit" ]; then fail "(c) item surfaced with nothing to do: $hit"; c_ok=0; fi
[ "$c_ok" = 1 ] && echo "PASS (c) no move and no ask for an unearned return"
named_lines="$( { tr -d '\r' < "$out" | grep -Ein "$general"; tr -d '\r' < "$out" | grep -En "$homonym"; } | cut -d: -f1 | sort -u | wc -l | tr -d ' ')"
echo "INFO (c) lines naming a dropped candidate: $named_lines"

# (d) nothing written before the pick, shared index included.
after="$(bash "$here/snapshot.sh" "$fx")"
if [ "$after" = "$(cat "$fx.snap")" ]; then
  echo "PASS (d) fixture unchanged at the pick"
else
  fail "(d) fixture changed: $(diff <(cat "$fx.snap") <(printf '%s\n' "$after") | grep '^>' | tr '\n' ' ')"
fi

# (e) the stale line in the changed doc's unchanged prose is a doc-update row.
if named '^doc-update' | grep -Eqi 'documented yet|not documented|operations\.md:[34]'; then
  echo "PASS (e) stale line carried as a doc-update row"
else
  echo "MISS (e) no [doc-update] row for the stale line in docs/operations.md. Rows: $(printf '%s\n' "$all_rows" | cut -f1 | tr '\n' ' ')"
fi
[ "$fails" = 0 ]
