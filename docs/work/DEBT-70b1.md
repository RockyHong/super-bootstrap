# DEBT-70b1 — session-close pick rows and predicate route 5 stay under their stated pass conditions

**Logged:** 2026-11-04 · **Source:** DEBT-h3p5 build, two wording rounds (`bench/session-close-moves/` README Findings); DEBT-xs75 RED (`bench/dimension-predicate-audit/` README Findings)
**Problem:** Both builds stopped at their round budget with these unmet:
- `(p5)` 0 of 3 on `full`: picks nest their commits under one `[commit]` row where `session-close` says one row per commit. All walks land the partition, so this is row shape only. Open: accept a nested partition, or hold the text.
- `(p2)` 5 of 6: one `full` run's resolve row reads "the two doc-update rows above state it" instead of carrying the edit, so that outcome can be declined apart from the resolve.
- Stale row in `bench/session-close-judgment/`: `(e)` 2 of 3 on the second round, 3 of 3 on the first. Three runs cannot separate this from variance.
- `dimension-predicate.md` route 5: one of 3 arm runs keeps the status pointer, on text the edit did not change; the control flagged it 3 of 3.
- No reading: park drafts in the judgment, ledger-clear and park as sole writing moves, a path two changes touch, a declined row, the hunk-grain lane per part, a close with only a fix-now move (no RED). The Skill-tool loading order stays with the device case in `docs/test-queue.md`.
**Area:** `plugins/super-bootstrap/skills/session-close/SKILL.md` step 3 and step 4; `plugins/super-bootstrap/skills/commit/SKILL.md` § Session-close entries; `plugins/super-bootstrap/skills/check-docs-consistency/assets/dimension-predicate.md`

## Design — 2026-11-04

User's ruling, in the session that shipped v5.8.1. Verbatim: 「session-close幾乎不太希望出現commit (除非真的有漏)，抓漏的不應該有巢狀這麼多commit」; 「"[ ] 全部不做"拿掉，沒意義」; 「spike直接改main workspace最後積一大堆最後一次commit，我覺得本身是anti pattern」; 「push本身就是根據repo形狀要偵測要不要做的。如果是有remote的，就做，沒有Remote就不用問」, and not mentioned at all without one.

- **Commit in flow.** Commits land at each verified unit; an approval a commit needs is asked there, never deferred to the close.
- **The close catches leaks.** A commit row appears only for work left uncommitted, normally one commit on one row. "One row per commit" goes. The door's §5 split and per-part readback stay as a guard, with no pick shape built on them. A large leak is named plainly as left uncommitted and the user decides; on that reading the close may point once at the spike route.
- **Spike route.** Iterative or spike work branches out, commits in flow and merges when settled. A route row in `CLAUDE.md` and its shipped skeleton, no hook.
- **Push by repo shape.** A remote exists and the branch is ahead of its upstream or has none → a push row in the pick, run after merge. No remote → no row and no mention, the close state's "no remote" line included. The commit door itself still never pushes.
- **No "close without running" row.** Esc covers it. A single detected move is asked in prose, and a yes runs it.
- `(p5)` is void. `(p2)` and the other origin bullets stay open at lower priority.

## Amendment — 2026-11-04 · user ruling on the first redesign round

Option A, on the user's "your lean". The commit move stays one row, normally one commit. A leak that truly mixes unrelated changes says so on that row in one clause ("splits into 2 commits"), and the door's §5 splits it. First-round reading that forced this: with one row and no such clause, `full` landed 1, 1, 1 commits mixing unrelated changes, against 4, 3, 3 on the control. The spike pointer on a large leak goes (0 of 3, and the route row itself passed).

## Progress — 2026-11-04

Landed from the redesign: commit in flow, the spike route row, the close's single commit row with a "splits into N commits" clause, push by repo shape, no close-without row. `full` lands 3, 3, 3 commits with unrelated changes apart. Push walks against a local bare repo pass, and a push row with no remote is gone after the condition was reworded (`single` 3 of 3; the other no-remote scenarios were not rerun after that fix). `bench/session-close-push/` and `bench/session-close-moves/` README Findings hold the tables.

Open after two rounds, budget spent:
- `(f)` no mention with no remote: 0 of 3 across two wordings. Runs write "Remote: none, so there is nothing to push." Prose has not held this, and a mechanism is the next step: a detect script whose empty output leaves the model nothing to narrate, or a Stop-side check.
- `(p7)` leak named as left uncommitted 2, 2, 1 of 3; `(p8)` on `large` 1 of 3 (a nested list follows the clause); `(p11)` lone move stated with no question, 1 of 3 on the last `single` runs.
- One-off misses: `(b)` on `ahead` 2 of 3, `(w3)` 14 of 15, `(p3)` README on `fixnow` 1 of 3, the register row 2 of 3.
- `(e)` on `noupstream` 2 of 3 is the scorer's own fix missing a `**`-led line, not a wording failure.
- No reading: spike route from an ambient `CLAUDE.md`, its commit-in-flow and merge limbs, push against a real remote or a rejected push, a declined row.
- `bench/session-close-push/make-fixture.sh` and `bench/commit-push/make-fixture.sh` run `git commit` in scratch fixtures through a script; check this against the commit-channel intent.
