# BUG-g6at — merge's rebase strategy fails on autorun branches still checked out by their worktree, and reports it as a conflict

**Logged:** 2026-10-20 · **Source:** device note from `jowagoko` (D:/Git/Podcast/jowagoko, autorun 5.2.0), 2026-10-20 run
**Problem:** `/super-bootstrap:merge` §4 picks rebase + ff for a 1-commit branch. On an autorun branch, `git rebase main autorun/x` fails with `fatal: 'autorun/x' is already used by worktree at …` — the sheet-phase worktree still checks the branch out. The conflict doctrine then aborts and reports a conflict that does not exist.
**Area:** `plugins/super-bootstrap/skills/merge/SKILL.md` §1 / §4; autorun worktree teardown order
**Prior:** Default `autorun/*` to `--no-ff` (teardown after merge), or detect branches occupied in `git worktree list` at §1 and go no-ff; report branch-occupied separately from conflict. Related: GAP-0cf5, BUG-szkd.
