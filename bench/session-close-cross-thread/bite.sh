#!/usr/bin/env bash
# bite.sh — shows each of score.sh's assertions failing on a violating output. Zero LLM calls.
# Usage: bash bench/session-close-cross-thread/bite.sh <scratch-dir>
set -u
scratch="${1:?usage: bite.sh <scratch-dir>}"
here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$scratch"
scratch="$(cd "$scratch" && pwd)"
o="$scratch/o.txt"; fx="$scratch/b-fx"
bash "$here/make-fixture.sh" "$fx" >/dev/null
good() { printf -- '- [triage] **GAP-tg01**: run /super-bootstrap:triage GAP-tg01; GAP-an02 posted the recap, efb759d archived the sheet.\n'; }

echo "== baseline (all pass)"; good > "$o"; bash "$here/score.sh" "$o" "$fx"
echo "== (x1) no triage row"; printf 'Moves: nothing to do.\n' > "$o"; bash "$here/score.sh" "$o" "$fx"
echo "== (x2) target resolved"; printf -- '- [resolve] **GAP-tg01**: delete docs/work/GAP-tg01.md.\n' > "$o"; bash "$here/score.sh" "$o" "$fx"
echo "== (x3) a decoy resolved"; { good; printf -- '- [resolve] **GAP-dc04**: delete docs/work/GAP-dc04.md.\n'; } > "$o"; bash "$here/score.sh" "$o" "$fx"
echo "== (x4) decoy triage rows count"; { good; printf -- '- [triage] **DEBT-dc03**: seed-swap words match.\n- [triage] **GAP-dc05**: tally sheet words match.\n'; } > "$o"; bash "$here/score.sh" "$o" "$fx"
echo "== (x5) written before the pick"; good > "$o"; rm "$fx/docs/work/GAP-tg01.md"; bash "$here/score.sh" "$o" "$fx"
