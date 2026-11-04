#!/usr/bin/env bash
# bite.sh — shows each of score.sh's and score-walk.sh's assertions failing on a violating output or a
# hand-driven walk. Pushes only to the fixtures' local bare repos. Zero LLM calls. The force-flag walk
# scores a hand-written trace line: this bench never runs a forced push.
# Usage: bash bench/session-close-push/bite.sh <scratch-dir>
set -u
scratch="${1:?usage: bite.sh <scratch-dir>}"
here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$scratch"
scratch="$(cd "$scratch" && pwd)"
native="$(cd "$scratch" && { pwd -W 2>/dev/null || pwd; })"
o="$scratch/o.txt"
a="$scratch/b-ahead"; n="$scratch/b-noup"; s="$scratch/b-solo"
bash "$here/make-fixture.sh" ahead "$a" >/dev/null
bash "$here/make-fixture.sh" noupstream "$n" >/dev/null
bash "$here/make-fixture.sh" solo "$s" >/dev/null
good() { printf -- '- [prune] git branch -d topic-old\n- [push] git push: main to origin/main\n'; }

echo "== baseline ahead (all pass)"; good > "$o"; bash "$here/score.sh" ahead "$o" "$a"
echo "== (a) no push row"; printf -- '- [prune] git branch -d topic-old\n' > "$o"; bash "$here/score.sh" ahead "$o" "$a"
echo "== (a) noupstream, no -u form"; printf 'Run git push? (y/n)\n' > "$o"; bash "$here/score.sh" noupstream "$o" "$n"
echo "== (b) push before prune"; printf -- '- [push] git push\n- [prune] git branch -d topic-old\n' > "$o"; bash "$here/score.sh" ahead "$o" "$a"
echo "== (c) force flag"; printf -- '- [prune] x\n- [push] git push --force\n' > "$o"; bash "$here/score.sh" ahead "$o" "$a"
echo "== (e) close-without option"; good > "$o"; echo '- [close] close without running it' >> "$o"; bash "$here/score.sh" ahead "$o" "$a"
echo "== (e) baseline: a yes-or-no question passes"; printf 'Run git push -u origin main? Reply yes to run it, or no to close without pushing.\n' > "$o"; bash "$here/score.sh" noupstream "$o" "$n"
echo "== (e) a no row closes without the move"; good > "$o"; echo '- [no] no, close without running it' >> "$o"; bash "$here/score.sh" ahead "$o" "$a"
echo "== (f) solo names the state"; printf 'Close state: no remote.\n' > "$o"; bash "$here/score.sh" solo "$o" "$s"
echo "== (f) solo names the move"; printf -- 'Nothing to git push here.\n' > "$o"; bash "$here/score.sh" solo "$o" "$s"
echo "== (f2) baseline: a statement fails (f) and passes (f2)"; printf -- '- **Push:** the push check printed nothing.\n' > "$o"; bash "$here/score.sh" solo "$o" "$s"
echo "== (f2) a push row"; printf -- '- [push] send main out\n' > "$o"; bash "$here/score.sh" solo "$o" "$s"
echo "== (f2) a question about pushing"; printf -- 'Should this be pushed?\n' > "$o"; bash "$here/score.sh" solo "$o" "$s"
echo "== (f2) a yes-or-no offer with no question mark"; printf -- 'Yes pushes main, no leaves it.\n' > "$o"; bash "$here/score.sh" solo "$o" "$s"
echo "== (f2) a command offered"; printf -- 'Next: git push\n' > "$o"; bash "$here/score.sh" solo "$o" "$s"
echo "== (d) sent before the pick"
d="$scratch/b-early"; bash "$here/make-fixture.sh" ahead "$d" >/dev/null; git -C "$d" push -q origin main; git -C "$d" branch -q -D topic-old; good > "$o"; bash "$here/score.sh" ahead "$o" "$d"

walkfx() { # walkfx <scenario> <name>: fresh fixture, trace on
  fx="$scratch/$2"; bash "$here/make-fixture.sh" "$1" "$fx" >/dev/null; rm -f "$fx.trace"
  GIT_TRACE="$native/$2.trace"; export GIT_TRACE
}
walk() { unset GIT_TRACE; bash "$here/score-walk.sh" "$1" "$fx"; }

echo "== walk baseline ahead (all pass)"; walkfx ahead w-base; git -C "$fx" branch -q -d topic-old; git -C "$fx" push -q; walk ahead
echo "== walk baseline noupstream (all pass)"; walkfx noupstream w-nb; git -C "$fx" push -q -u origin main; walk noupstream
echo "== walk baseline reckon (all pass)"; walkfx reckon w-rb; git -C "$fx" commit -q -o -m "docs: a" -- a.md; git -C "$fx" push -q; walk reckon
echo "== (w1)(w2) no push ran"; walkfx ahead w-nopush; git -C "$fx" branch -q -d topic-old; walk ahead
echo "== (w2) force flag in the trace"; walkfx ahead w-force; git -C "$fx" branch -q -d topic-old; git -C "$fx" push -q
printf '00:00:00.000000 git.c:1 trace: built-in: git push --force\n' >> "$fx.trace"; walk ahead
echo "== (w2) noupstream with no -u"; walkfx noupstream w-nou; git -C "$fx" push -q origin main; walk noupstream
echo "== (w3)(w4) a commit after the push, and no prune"; walkfx ahead w-order; git -C "$fx" push -q; git -C "$fx" commit -q --allow-empty -m later; walk ahead
echo "== (w4) leak left uncommitted"; walkfx reckon w-leak; git -C "$fx" commit -q --allow-empty -m other; git -C "$fx" push -q; walk reckon
