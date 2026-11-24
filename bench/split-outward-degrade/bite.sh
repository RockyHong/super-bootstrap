#!/usr/bin/env bash
# bite.sh — shows each of score.sh's assertions failing on a hand-driven violating run, and the baseline
# passing. Zero LLM calls.
# Usage: bash bench/split-outward-degrade/bite.sh <scratch-dir>
set -u
scratch="${1:?usage: bite.sh <scratch-dir>}"
here="$(cd "$(dirname "$0")" && pwd)"
scale="$here/../../plugins/super-bootstrap/skills/harness-bootstrap/assets/scale"
mkdir -p "$scratch"
scratch="$(cd "$scratch" && pwd)"
o="$scratch/o.txt"
ok='The outward split did not run: python3 is needed to split docs/outward.md into docs/outward/; install it and re-run the sync.'
fresh() { fx="$scratch/$1"; bash "$here/make-fixture.sh" "$fx" >/dev/null; cd "$fx" || exit 2; }
queue() { cp "$scale/test-queue-skeleton.md" docs/test-queue.md; }
score() { cd "$scratch" || exit 2; bash "$here/score.sh" "$o" "$fx"; }

echo "== baseline (all pass)"; fresh base; queue; printf '%s\n' "$ok" > "$o"; score
echo "== (a) README placed by Missing -> write"; fresh readme; queue; mkdir -p docs/outward
cp "$scale/outward-readme-skeleton.md" docs/outward/README.md; printf '%s\n' "$ok" > "$o"; score
echo "== (a)(b) hand split"; fresh hand; queue; mkdir -p docs/outward
printf '# OUT-001 — x\n' > docs/outward/OUT-001.md; rm docs/outward.md; printf '%s\n' "$ok" > "$o"; score
echo "== (b) flat file edited"; fresh edited; queue; printf '\nnote\n' >> docs/outward.md; printf '%s\n' "$ok" > "$o"; score
echo "== (c) no install / re-run named"; fresh noprereq; queue
printf 'The split did not run because python3 is not installed. Nothing placed.\n' > "$o"; score
echo "== (d) sync halted at the split"; fresh halted; printf '%s\n' "$ok" > "$o"; score
