# BUG-3acf — autorun worktree template allows none of the commit door's private-index commands, and OWNED_BY shows in the worktree's git status

**Logged:** 2026-10-20 · **Source:** side finding of BUG-6mp8's triage verdict (static read, not confirmed by a run)
**Problem:** `worktree-settings.local.json` has no allow row, in either shell, for the commit door's private-index lane (`GIT_INDEX_FILE=... git read-tree` and the follow-on staged-tree commands) or for a repo-declared Staged-Tree Verify command. The worktree's `OWNED_BY` file is not ignored inside the worktree, so `git status` lists it and the door's staged-tree verify starts. A headless `-p` worker cannot prompt, so its `/super-bootstrap:commit` is likely denied mid-door.
**Area:** `plugins/super-bootstrap/skills/autorun/assets/worktree-settings.local.json`; `plugins/super-bootstrap/skills/autorun/assets/parallel-worktrees.md` § Warm (`OWNED_BY`); `plugins/super-bootstrap/skills/commit/SKILL.md` private-index lane
**Prior:** Add allow rows for the door's private-index command forms, and keep `OWNED_BY` out of the worktree's status (ignore it, or place it outside the tree).

## Amendment — 2026-10-20 · BUG-6mp8 audit

The template has no `Bash(mv *)`, `Bash(rm *)` or `Bash(git rm *)` allow row, and the worker brief now routes the status-file rename and the card delete through Bash. Whether headless `acceptEdits` auto-approves those filesystem commands inside the worktree is unverified; a live `claude -p` check settles it alongside this card's private-index rows.
