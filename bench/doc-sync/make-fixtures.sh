#!/usr/bin/env bash
# Reconstruct both fixture trees under .fixtures/ (gitignored). Idempotent —
# re-running rebuilds from scratch. Zero LLM calls.
#
#   f1-d3161f3  coverage fixture: plain worktree at d3161f3, the mattpocock
#               coexistence-runbook commit. Nothing to patch — the tree is the
#               commit's own post-image, which is what the arms judge.
#   f2-runB     stability fixture: base a3418fe + the Run-B revision of
#               slug_gap_hint, recovered from the session store. Not in git.
#
# See README.md § Fixtures for provenance and the two reconstruction caveats.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$HERE" rev-parse --show-toplevel)"
FIX="$HERE/.fixtures"
F1="$FIX/f1-d3161f3"
F2="$FIX/f2-runB"

drop() {
  [ -e "$1" ] || return 0
  git -C "$ROOT" worktree remove --force "$1" >/dev/null 2>&1 || rm -rf "$1"
}

mkdir -p "$FIX"

echo "== f1: worktree at d3161f3 =="
drop "$F1"
git -C "$ROOT" worktree add --detach "$F1" d3161f3 >/dev/null 2>&1 || {
  echo "FAIL: could not create f1 worktree" >&2; exit 1; }
[ -f "$F1/docs/specs/mattpocock-coexistence.md" ] || {
  echo "FAIL: f1 tree missing the runbook" >&2; exit 1; }
echo "   ok  $F1"

echo "== f2: worktree at a3418fe + Run-B hunks =="
drop "$F2"
git -C "$ROOT" worktree add --detach "$F2" a3418fe >/dev/null 2>&1 || {
  echo "FAIL: could not create f2 worktree" >&2; exit 1; }
# Run B's test block is not recorded verbatim in the session store; the shipped
# block at c7f5ce9 matches its stated shape (ten assertions over four fixtures).
git -C "$F2" checkout c7f5ce9 -- tests/doc-links.test.sh || {
  echo "FAIL: could not stage f2 test file" >&2; exit 1; }
git -C "$F2" apply "$HERE/parts/f2-runB-doc-links.patch" || {
  echo "FAIL: could not apply the Run-B patch" >&2; exit 1; }
# Decontamination: at a3418fe the tree carries docs/work/GAP-069.md — the card
# that specifies this very read-out, container hypothesis and all — plus
# GAP-070. Both are card-lifecycle files the gate exempts by construction, so
# they are outside every arm's scan scope; only step 4's unlinked-line grep
# could reach them, and what it would find there is the experiment's own
# premise. Removed. README.md § Decontamination records this.
rm -f "$F2/docs/work/GAP-069.md" "$F2/docs/work/GAP-070.md"
echo "   ok  $F2  (GAP-069/GAP-070 stripped — see README § Decontamination)"

echo "== f2 self-check: Run B's own recorded verification =="
# Run B's dispatch prompt claims 53 passed / 0 failed. If the reconstruction is
# faithful the suite reproduces it.
out="$(cd "$F2" && bash tests/doc-links.test.sh 2>&1 | tail -1)"
echo "   $out"
case "$out" in
  *"53 passed, 0 failed"*) echo "   ok  matches Run B's recorded figure" ;;
  *) echo "   WARN: does not match Run B's recorded '53 passed, 0 failed'" >&2 ;;
esac

echo "DONE"
