# BUG-wnav — Autorun defers doc-sync to a merge step that never runs it

**Logged:** 2026-11-24 · **Source:** docs-consistency scan 2026-11-24 (`.review/docs-consistency-2026-11-24.md`), via `/super-bootstrap:triage-report`
**Problem:** Four docs say an autorun worktree commit defers doc-sync "to the merge boundary" (`commit/SKILL.md:23`, `:74`; `autorun/SKILL.md:50`; `harness.md:60`), but `merge/SKILL.md` carries no doc-sync or commit-door step, so autorun-landed work gets no doc-sync (scope per docs-consistency scan 2026-11-24, unconfirmed)
**Area:** `plugins/super-bootstrap/skills/merge/SKILL.md` (`--batch`), `skills/commit/SKILL.md`, `skills/autorun/SKILL.md`, `skills/harness-bootstrap/assets/harness.md`
**Prior:** Either add a doc-sync pass to `merge --batch` or restate the contract; `bench/commit-deferred-verify` holds the prior deferred-mode measurement.
