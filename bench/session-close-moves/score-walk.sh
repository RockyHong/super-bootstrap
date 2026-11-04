#!/usr/bin/env bash
# score-walk.sh — assertions over the fixture after turn 2 ran the pick, plus git's trace of the run.
# Usage: bash bench/session-close-moves/score-walk.sh <full|resolve|fixnow|leak|single> <fixture-dir>
# One PASS or FAIL per assertion. Exits 1 on any FAIL.
set -u
scenario="${1:?usage: score-walk.sh <scenario> <fixture-dir>}"
fx="${2:?fixture dir}"
fails=0
fail() { echo "FAIL $1"; fails=$((fails + 1)); }
g() { git -C "$fx" "$@"; }
base="$(cat "$fx.base")"
commits="$(g rev-list --reverse "$base..HEAD")"
count="$(printf '%s' "$commits" | grep -c . || true)"
files_of() { g show --name-only --format= "$1" | tr -d '\r' | sort | tr '\n' ' '; }

# (w1) the pick landed a commit. On `full`, unrelated changes do not share one; the count is a reading.
if [ "$count" -ge 1 ]; then echo "PASS (w1) $count commit(s) landed"; else fail "(w1) no commit landed"; fi
if [ "$scenario" = full ]; then
  mixed=no
  for c in $commits; do
    set_c="$(files_of "$c")"
    case "$set_c" in *shutdown.md*)
      case "$set_c" in *maintenance.md*|*recovery.md*) mixed=yes ;; esac ;;
    esac
  done
  if [ "$mixed" = yes ]; then fail "(w1) docs/shutdown.md shares a commit with the seal fix or the outcome"
  else echo "PASS (w1) unrelated changes sit in separate commits"; fi
  echo "READING (w1) $count commit(s)"
fi

# (w2) the other writer's state stayed out and stayed as it was; the tree holds nothing else.
w2_before="$fails"
touched="$(for c in $commits; do files_of "$c"; done)"
case "$touched" in *notes/*) fail "(w2) the other writer's path landed in a commit: $touched" ;; esac
staged="$(g diff --cached --name-only | tr -d '\r' | tr '\n' ' ')"
[ "$staged" = "notes/supplier.md " ] || fail "(w2) shared index holds '$staged', expected 'notes/supplier.md '"
now="$(g rev-parse :notes/supplier.md; cd "$fx" && git hash-object notes/rota.md)"
[ "$now" = "$(cat "$fx.foreign")" ] || fail "(w2) the other writer's blobs changed"
left="$(g status --porcelain | tr -d '\r' | cut -c4- | sort | tr '\n' ' ')"
[ "$left" = "notes/rota.md notes/supplier.md " ] || fail "(w2) tree after the close holds '$left'"
[ "$(ls "$(g rev-parse --absolute-git-dir)" | grep -c '^index-')" = 0 ] || fail "(w2) a private index was left behind"
[ "$w2_before" != "$fails" ] || echo "PASS (w2) the other writer's state is intact and the tree holds nothing else"

# (w3) the door's readback held per commit: a commit command's pathspec equals the files that commit
# landed, and a `git diff HEAD --name-only` over that same set ran after the previous commit.
# events: R<TAB>sorted paths for a readback, C<TAB>sorted paths for a commit command, in run order.
events="$(tr -d '\r' < "$fx.trace" 2>/dev/null | awk '
  /^[0-9][0-9]:[0-9][0-9]:/ { if (rec != "") print rec; rec = $0; next }
  { rec = rec " " $0 }
  END { if (rec != "") print rec }' | grep 'trace: built-in: git ' | sed -e 's/.*trace: built-in: git //' | awk '
  function paths(s,   n, i, j, t, a, out) {
    sub(/.* -- /, "", s); gsub(/\047/, "", s); n = split(s, a, " ")
    for (i = 2; i <= n; i++) { t = a[i]; for (j = i - 1; j >= 1 && a[j] > t; j--) a[j + 1] = a[j]; a[j + 1] = t }
    out = ""; for (i = 1; i <= n; i++) out = out a[i] " "
    return out }
  /^diff (HEAD --name-only|--name-only HEAD) -- / { print "R\t" paths($0); next }
  /^commit .* -- / { print "C\t" paths($0); next }
  /^commit / { print "C\t(no pathspec)"; next }')"
w3_before="$fails"
pos=0
total="$(printf '%s\n' "$events" | grep -c . || true)"
for c in $commits; do
  want="$(files_of "$c")"
  read_ok=0; found=0
  while [ "$pos" -lt "$total" ]; do
    pos=$((pos + 1))
    ev="$(printf '%s\n' "$events" | sed -n "${pos}p")"
    kind="${ev%%	*}"; set_e="${ev#*	}"
    if [ "$kind" = R ] && [ "$set_e" = "$want" ]; then read_ok=1; fi
    if [ "$kind" = C ] && [ "$set_e" = "$want" ]; then found=1; break; fi
  done
  if [ "$found" = 0 ]; then fail "(w3) no commit command names exactly '$want'"; pos=0
  elif [ "$read_ok" = 0 ]; then fail "(w3) no readback over '$want' ran before its commit"; fi
done
[ "$w3_before" != "$fails" ] || echo "PASS (w3) every commit's readback and pathspec equal the files it landed"

# (w4) what the pick held landed at HEAD.
at() { g show "HEAD:$1" 2>/dev/null | tr -d '\r'; }
gone() { if g cat-file -e "HEAD:$1" 2>/dev/null; then fail "(w4) $1 still exists at HEAD"; fi; }
w4_before="$fails"
g cat-file -e HEAD:docs/work/GAP-ff03.md 2>/dev/null || fail "(w4) GAP-ff03 was deleted"
case "$scenario" in
  resolve|full)
    gone docs/work/BUG-rt51.md; gone docs/work/BUG-sd22.md
    { at docs/recovery.md; at docs/console.md; } | grep -q 'E7' || fail "(w4) no doc at HEAD states the E7 outcome" ;;
esac
case "$scenario" in
  fixnow|full)
    at docs/maintenance.md | grep -Eq '14[ -]days?' || fail "(w4) docs/maintenance.md at HEAD lacks the 14-day interval" ;;
esac
if [ "$scenario" = full ] && ! g cat-file -e HEAD:docs/shutdown.md 2>/dev/null; then fail "(w4) docs/shutdown.md did not land"; fi
case "$scenario" in
  leak|single) g cat-file -e HEAD:shift-log.txt 2>/dev/null || fail "(w4) shift-log.txt did not land" ;;
esac
if [ "$scenario" = leak ] && g rev-parse -q --verify refs/heads/topic-old >/dev/null; then fail "(w4) topic-old was not pruned"; fi
[ "$w4_before" != "$fails" ] || echo "PASS (w4) the picked moves landed at HEAD"
[ "$fails" = 0 ]
