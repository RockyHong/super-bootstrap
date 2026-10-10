#!/usr/bin/env bash
# L1 unit tests for new-id.sh — the ID generator behind /super-bootstrap:log (GAP-101).
# Targets the PLUGIN ASSET (source of truth).
#
# Contract pinned here:
#   - `new-id.sh <CAT>...` prints one `{CAT}-xxxx` per argument, in order; xxxx = 4 chars
#     from 0-9a-z minus i l o u, at least one letter; IDs distinct within one call.
#   - CAT outside BUG DEBT GAP OUT PARK, or no argument -> exit 1 (stderr names the arg / usage).
#   - A candidate already present in a docs/work or docs/outward file name, a `### PARK-`
#     heading of docs/parked.md, tracked file content, or a commit message is redrawn.
#   - Outside a git repo the git-based checks are skipped silently.
#   - NEW_ID_DRAWS (test-only) forces the candidate suffixes, consumed in order.
#
# Usage: bash tests/new-id.test.sh
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
NID="${NEW_ID:-$REPO/plugins/super-bootstrap/skills/log/assets/new-id.sh}"  # override = bite-check a mutant

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok: $1"; }
bad() { fail=$((fail+1)); echo "  FAIL: $1"; }
show() { printf '%s\n' "$1" | sed 's/^/        /'; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -f "$NID" ] || { echo "  FAIL: asset missing: $NID"; echo; echo "RESULT: 0 passed, 1 failed"; exit 1; }

# run <dir> <args...>; candidate suffixes come from $DRAWS (NEW_ID_DRAWS)
DRAWS=""
run() { local d="$1"; shift; out="$(cd "$d" && NEW_ID_DRAWS="$DRAWS" bash "$NID" "$@" 2>"$TMP/err")"; rc=$?; err="$(cat "$TMP/err")"; }

PLAIN="$TMP/plain"; mkdir -p "$PLAIN"   # not a git repo

echo "== new-id: shape, order, alphabet =="
DRAWS=""
run "$PLAIN" BUG DEBT GAP OUT PARK
exp_re='^(BUG|DEBT|GAP|OUT|PARK)-[0-9a-hjkmnp-tv-z]{4}$'
if [ "$rc" -eq 0 ] && [ "$(printf '%s\n' "$out" | grep -cE "$exp_re")" -eq 5 ] \
   && [ "$(printf '%s\n' "$out" | cut -d- -f1 | paste -sd, -)" = "BUG,DEBT,GAP,OUT,PARK" ]; then
  ok "one ID per arg, in order, suffix in the 32-char alphabet"
else
  bad "one ID per arg, in order, suffix in the 32-char alphabet (rc=$rc)"; show "$out"; show "$err"
fi

echo "== new-id: at least one letter (random, 200 draws) =="
args=(); for _ in $(seq 1 200); do args+=(GAP); done
run "$PLAIN" "${args[@]}"
if [ "$rc" -eq 0 ] && [ "$(printf '%s\n' "$out" | wc -l)" -eq 200 ] \
   && ! printf '%s\n' "$out" | grep -qE '^GAP-[0-9]{4}$'; then
  ok "no all-digit suffix among 200 random draws"
else
  bad "no all-digit suffix among 200 random draws (rc=$rc)"; show "$(printf '%s\n' "$out" | grep -E '^GAP-[0-9]{4}$' | head -3)"
fi

echo "== new-id: forced all-digit draw is skipped =="
DRAWS="1234 5678 12a4"
run "$PLAIN" GAP
if [ "$rc" -eq 0 ] && [ "$out" = "GAP-12a4" ]; then
  ok "all-digit draws skipped, next letter-bearing draw used"
else
  bad "all-digit draws skipped, next letter-bearing draw used (rc=$rc)"; show "$out"; show "$err"
fi

echo "== new-id: distinct within one call =="
DRAWS="ab12 ab12 cd34"
run "$PLAIN" GAP GAP
if [ "$rc" -eq 0 ] && [ "$out" = "$(printf 'GAP-ab12\nGAP-cd34')" ]; then
  ok "duplicate draw redrawn; batch IDs distinct"
else
  bad "duplicate draw redrawn; batch IDs distinct (rc=$rc)"; show "$out"; show "$err"
fi

echo "== new-id: bad arguments =="
DRAWS=""
run "$PLAIN" BUG FOO
if [ "$rc" -eq 1 ] && printf '%s' "$err" | grep -qF 'FOO' && [ -z "$out" ]; then
  ok "unknown category: exit 1, stderr names it, nothing printed"
else
  bad "unknown category: exit 1, stderr names it, nothing printed (rc=$rc)"; show "$out"; show "$err"
fi
run "$PLAIN"
if [ "$rc" -eq 1 ] && printf '%s' "$err" | grep -qi 'usage'; then
  ok "no argument: exit 1 with usage"
else
  bad "no argument: exit 1 with usage (rc=$rc)"; show "$err"
fi

echo "== new-id: guard sources force a redraw =="
G="$TMP/g"; mkdir -p "$G/docs/work" "$G/docs/outward"
(
  cd "$G" && git init -q . && git config user.email t@t && git config user.name t \
  && : > docs/work/GAP-k7f3.md \
  && : > docs/outward/OUT-k7f3.md \
  && printf '# Parked\n\n### PARK-k7f3 - thing\n' > docs/parked.md \
  && printf 'see BUG-c3c3 here\n' > docs/note.md \
  && git add docs/note.md && git commit -q -m 'add note' \
  && git commit -q --allow-empty -m 'fix: DEBT-p4q8 closed' \
  && git checkout -q -b other && git commit -q --allow-empty -m 'wip: GAP-r5r5 on side branch' \
  && git checkout -q -
) >/dev/null 2>&1

DRAWS="k7f3 k7f4"; run "$G" GAP
if [ "$rc" -eq 0 ] && [ "$out" = "GAP-k7f4" ]; then ok "guard: live card file name"; else bad "guard: live card file name (rc=$rc)"; show "$out"; show "$err"; fi
DRAWS="k7f3 k7f5"; run "$G" OUT
if [ "$rc" -eq 0 ] && [ "$out" = "OUT-k7f5" ]; then ok "guard: outward file name"; else bad "guard: outward file name (rc=$rc)"; show "$out"; show "$err"; fi
DRAWS="k7f3 k7f6"; run "$G" PARK
if [ "$rc" -eq 0 ] && [ "$out" = "PARK-k7f6" ]; then ok "guard: ### PARK- heading in docs/parked.md"; else bad "guard: ### PARK- heading in docs/parked.md (rc=$rc)"; show "$out"; show "$err"; fi
DRAWS="c3c3 c3c4"; run "$G" BUG
if [ "$rc" -eq 0 ] && [ "$out" = "BUG-c3c4" ]; then ok "guard: tracked file content (git grep)"; else bad "guard: tracked file content (git grep) (rc=$rc)"; show "$out"; show "$err"; fi
DRAWS="p4q8 p4q9"; run "$G" DEBT
if [ "$rc" -eq 0 ] && [ "$out" = "DEBT-p4q9" ]; then ok "guard: commit message"; else bad "guard: commit message (rc=$rc)"; show "$out"; show "$err"; fi
DRAWS="r5r5 r5r6"; run "$G" GAP
if [ "$rc" -eq 0 ] && [ "$out" = "GAP-r5r6" ]; then ok "guard: commit message on another branch (--all)"; else bad "guard: commit message on another branch (--all) (rc=$rc)"; show "$out"; show "$err"; fi

echo "== new-id: outside a git repo the git checks are skipped silently =="
mkdir -p "$PLAIN/docs/work"; : > "$PLAIN/docs/work/GAP-k7f3.md"
DRAWS="k7f3 k7f4"; run "$PLAIN" GAP
if [ "$rc" -eq 0 ] && [ "$out" = "GAP-k7f4" ] && [ -z "$err" ]; then
  ok "non-git dir: file-name guard still works, no stderr noise"
else
  bad "non-git dir: file-name guard still works, no stderr noise (rc=$rc)"; show "$out"; show "$err"
fi

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
