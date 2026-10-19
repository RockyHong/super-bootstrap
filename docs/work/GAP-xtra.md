# GAP-xtra — No step regenerates derived state in a worktree after syncing base, before verify

**Logged:** 2026-10-20 · **Source:** device note from `magnetized-remake` (D:/Git/Games/Magnetized Remake, runway 5.2.0), 2026-10-17
**Problem:** After `git merge <base>` in an autorun worktree, verification went red because base had added new `class_name` scripts and the worktree's git-ignored generated class cache (Godot) did not know them; the consumer's own docs say to run a headless `--import` after new class scripts. Nothing in the autorun / merge flow says derived caches must be regenerated after syncing base — a stale derived cache gives a false RED (reverse direction of the nested-worktree false-green case).
**Area:** `plugins/super-bootstrap/skills/autorun/`; `plugins/super-bootstrap/skills/merge/SKILL.md`
**Prior:** A consumer-declared, per-repo command (engine import, codegen, lockfile install) run before the verify lane, pointing at the consumer's harness doc; no hardcoded tool.
