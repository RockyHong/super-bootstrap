#!/usr/bin/env bash
# L1 unit tests for closed-forks.sh — the source resolver behind /super-bootstrap:log
# step 2's Closed-forks gate. Targets the PLUGIN ASSET (source of truth).
#
# Contract pinned here:
#   - present → exit 0, a header line with the row count, one `[domain] direction
#     (ref: ref)` line per data row (Because cell dropped), a checklist line.
#   - file absent → exit 0, `— absent` outcome: a resolved state, distinct from unread.
#   - empty table (the shipped skeleton) → exit 0, 0 rows.
#   - heading renamed / missing column / row that does not split → exit 1, stderr
#     names docs/decisions.md and the cause.
#   - GFM escaped pipe `\|` inside a cell is cell text, not a separator (the
#     handling chosen for this repo's own two `\|` rows — parse, not rewrite).
#
# Usage: bash tests/closed-forks.test.sh
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
CF="${CLOSED_FORKS:-$REPO/plugins/super-bootstrap/skills/log/assets/closed-forks.sh}"  # override = bite-check a mutant

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok: $1"; }
bad() { fail=$((fail+1)); echo "  FAIL: $1"; }
show() { printf '%s\n' "$1" | sed 's/^/        /'; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -f "$CF" ] || { echo "  FAIL: asset missing: $CF"; echo; echo "RESULT: 0 passed, 1 failed"; exit 1; }

mkrepo() { mkdir -p "$TMP/$1/docs"; cat > "$TMP/$1/docs/decisions.md"; }
run() { out="$(cd "$TMP/$1" && bash "$CF" 2>"$TMP/err")"; rc=$?; err="$(cat "$TMP/err")"; }

HEAD_BLOCK='# Decisions

> History-dimension doc.

## Closed Forks

<!-- Newest first. Domain ∈ tech | product | business | design. -->

| Domain | Rejected direction | Because | Ref |
|---|---|---|---|'

echo "== closed-forks: present — one line per row, Because dropped =="
printf '%s\n%s\n%s\n' "$HEAD_BLOCK" \
  '| tech | Ship a Python port | Long reason SECRET-BECAUSE text. | `docs/techstack.md` |' \
  '| design | Merge triage into log | Capture must stay cheap. | GAP-001 |' | mkrepo present
run present
if [ "$rc" -eq 0 ] \
   && printf '%s\n' "$out" | grep -qxF '[tech] Ship a Python port (ref: `docs/techstack.md`)' \
   && printf '%s\n' "$out" | grep -qxF '[design] Merge triage into log (ref: GAP-001)' \
   && printf '%s\n' "$out" | grep -qF '2 rows' \
   && ! printf '%s\n' "$out" | grep -qF 'SECRET-BECAUSE'; then
  ok "present: rc 0, 2 projected rows, row count printed, Because dropped"
else
  bad "present: rc 0, 2 projected rows, row count printed, Because dropped (rc=$rc)"; show "$out"; show "$err"
fi
if printf '%s\n' "$out" | grep -qF 'collides: <row>' && printf '%s\n' "$out" | grep -qF 'no collision'; then
  ok "present: checklist names the two per-entry outcomes"
else
  bad "present: checklist names the two per-entry outcomes"; show "$out"
fi

echo "== closed-forks: absent — resolved, distinct, exit 0 =="
mkdir -p "$TMP/absent/docs"
run absent
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qE '§ Closed Forks — absent$' \
   && ! printf '%s\n' "$out" | grep -qF 'rows'; then
  ok "absent: rc 0, prints the absent outcome, no row count"
else
  bad "absent: rc 0, prints the absent outcome, no row count (rc=$rc)"; show "$out"; show "$err"
fi

echo "== closed-forks: empty table (shipped skeleton) — 0 rows, exit 0 =="
mkdir -p "$TMP/skel/docs"
cp "$REPO/plugins/super-bootstrap/skills/harness-bootstrap/assets/decisions-skeleton.md" "$TMP/skel/docs/decisions.md"
run skel
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qF '0 rows'; then
  ok "skeleton: rc 0, 0 rows"
else
  bad "skeleton: rc 0, 0 rows (rc=$rc)"; show "$out"; show "$err"
fi

echo "== closed-forks: heading renamed — fail loud, file named =="
printf '%s\n%s\n' "$(printf '%s' "$HEAD_BLOCK" | sed 's/^## Closed Forks$/## Rejected Directions/')" \
  '| tech | X | Y | Z |' | mkrepo renamed
run renamed
if [ "$rc" -ne 0 ] && printf '%s' "$err" | grep -qF 'docs/decisions.md' \
   && printf '%s' "$err" | grep -qF '## Closed Forks'; then
  ok "renamed heading: non-zero exit, stderr names docs/decisions.md + the heading"
else
  bad "renamed heading: non-zero exit, stderr names docs/decisions.md + the heading (rc=$rc)"; show "$out"; show "$err"
fi

echo "== closed-forks: heading only inside a fence — not a heading =="
cat > "$TMP/fenced.md" <<'EOF'
# Decisions

```
## Closed Forks
| Domain | Rejected direction | Because | Ref |
|---|---|---|---|
| tech | X | Y | Z |
```
EOF
mkrepo fenced < "$TMP/fenced.md"
run fenced
if [ "$rc" -ne 0 ] && printf '%s' "$err" | grep -qF 'docs/decisions.md'; then
  ok "fenced heading: non-zero exit (a fenced line is not the section)"
else
  bad "fenced heading: non-zero exit (rc=$rc)"; show "$out"; show "$err"
fi

echo "== closed-forks: row that does not split — fail loud, row named =="
printf '%s\n%s\n%s\n' "$HEAD_BLOCK" \
  '| tech | fine row | reason | ref |' \
  '| design | Split on a | bare pipe | reason | ref |' | mkrepo badrow
run badrow
if [ "$rc" -ne 0 ] && printf '%s' "$err" | grep -qF 'docs/decisions.md' \
   && printf '%s' "$err" | grep -qF 'Split on a'; then
  ok "bad row: non-zero exit, stderr names docs/decisions.md + the offending row"
else
  bad "bad row: non-zero exit, stderr names docs/decisions.md + the offending row (rc=$rc)"; show "$out"; show "$err"
fi

echo "== closed-forks: missing Rejected direction column — fail loud =="
printf '%s\n' '## Closed Forks' '' '| Domain | Direction | Because | Ref |' '|---|---|---|---|' \
  '| tech | X | Y | Z |' | mkrepo nocol
run nocol
if [ "$rc" -ne 0 ] && printf '%s' "$err" | grep -qF 'docs/decisions.md' \
   && printf '%s' "$err" | grep -qF 'Rejected direction'; then
  ok "missing column: non-zero exit, stderr names the file + the column"
else
  bad "missing column: non-zero exit, stderr names the file + the column (rc=$rc)"; show "$out"; show "$err"
fi

echo "== closed-forks: section with no table — fail loud =="
printf '%s\n' '## Closed Forks' '' 'Nothing here yet.' | mkrepo notable
run notable
if [ "$rc" -ne 0 ] && printf '%s' "$err" | grep -qF 'docs/decisions.md'; then
  ok "no table: non-zero exit, file named"
else
  bad "no table: non-zero exit, file named (rc=$rc)"; show "$out"; show "$err"
fi

echo "== closed-forks: escaped pipe \\| is cell text (handling: parse, not rewrite) =="
printf '%s\n%s\n' "$HEAD_BLOCK" \
  '| design | Ship a hook (PreToolUse `Edit\|Write`) | reason \| more | `hooks.md` |' | mkrepo escaped
run escaped
if [ "$rc" -eq 0 ] \
   && printf '%s\n' "$out" | grep -qxF '[design] Ship a hook (PreToolUse `Edit|Write`) (ref: `hooks.md`)'; then
  ok "escaped pipe: rc 0, row projects with the pipe restored inside its cell"
else
  bad "escaped pipe: rc 0, row projects with the pipe restored inside its cell (rc=$rc)"; show "$out"; show "$err"
fi

echo "== closed-forks: section ends at the next same-or-higher heading =="
printf '%s\n%s\n%s\n' "$HEAD_BLOCK" '| tech | Inside | r | x |' \
  '## Other' '' '| tech | Outside | r | x |' | mkrepo bounded
run bounded
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qF 'Inside' && ! printf '%s\n' "$out" | grep -qF 'Outside'; then
  ok "section bound: rows after the next ## heading are not read"
else
  bad "section bound: rows after the next ## heading are not read (rc=$rc)"; show "$out"; show "$err"
fi

echo "== closed-forks: CRLF file resolves the same =="
printf '%s\n%s\n' "$HEAD_BLOCK" '| tech | Crlf row | r | ref1 |' | sed 's/$/\r/' | mkrepo crlf
run crlf
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qxF '[tech] Crlf row (ref: ref1)'; then
  ok "crlf: rc 0, row projected without a trailing CR"
else
  bad "crlf: rc 0, row projected without a trailing CR (rc=$rc)"; show "$out"; show "$err"
fi

echo "== closed-forks: repo-root argument =="
out="$(cd "$TMP" && bash "$CF" "$TMP/present" 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qF '2 rows'; then
  ok "explicit repo-root: resolves the named repo"
else
  bad "explicit repo-root: resolves the named repo (rc=$rc)"; show "$out"
fi

echo "== closed-forks: this repo's real docs/decisions.md resolves =="
out="$(cd "$REPO" && bash "$CF" 2>&1)"; rc=$?
real_rows="$(awk '/^## Closed Forks/{on=1;next} on&&/^## /{exit} on&&/^\| *(tech|product|business|design) *\|/{n++} END{print n+0}' "$REPO/docs/decisions.md")"
got_rows="$(printf '%s\n' "$out" | grep -cE '^\[(tech|product|business|design)\] ')"
if [ "$rc" -eq 0 ] && [ "$got_rows" -eq "$real_rows" ] && [ "$real_rows" -gt 0 ]; then
  ok "real decisions.md: rc 0, $got_rows/$real_rows rows projected"
else
  bad "real decisions.md: rc 0, all rows projected (rc=$rc, got $got_rows of $real_rows)"; show "$(printf '%s\n' "$out" | tail -5)"
fi

echo "== closed-forks: asset dialect — no awk interval expression, no declare -A =="
if grep -nE '\{[0-9]+(,[0-9]*)?\}' "$CF" | grep -vE '^[0-9]+:[[:space:]]*#' >/dev/null; then
  bad "interval expression in asset:"; show "$(grep -nE '\{[0-9]+(,[0-9]*)?\}' "$CF")"
else
  ok "no interval expression"
fi
if grep -n 'declare -A' "$CF" >/dev/null; then bad "declare -A in asset"; else ok "no declare -A"; fi

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
