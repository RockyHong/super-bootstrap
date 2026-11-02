# DEBT-h3p5 — session-close's one pick still leaks: narration, row drift, register recall, unproven post-pick path

**Logged:** 2026-11-03 · **Source:** GAP-cdrv build (`bench/session-close-judgment/` README Findings) and its cold audit
**Problem:** The pre-pick judgment shipped with these open:
- A close still narrates dropped candidates in a block ahead of the pick ("Door judgment dropped, no row", "Checks that need no pick"), in most arm runs. Prose moved this both ways against stale-row recall; no wording passed both.
- Register recall: the `recovery ramp` row appears in 13 of 15 arm runs, control 3 of 3, so a small regression is not excluded. The miss sits in the door's § Scan step 8.
- Stale recall stays 2 of 3 on the first readings, where the judge returned no candidate at all.
- Row drift: labels such as `[commit-1]`, a named "terminology-no-op" row that does not exist, an "or delete" fork with a recommendation on a doc-update row, an invented `_Avoid_` alias the diff never used.
- `session-close` says fix-now folds into the close commit; the door's §5 says unrelated changes split. All arm runs proposed two commits.
- A resolve move carries no outcome edit, though the volatile-item route says an item's outcome lands in the doc on resolve.
- `close-commit` never ran end to end, and the bench embeds the door's text ahead of the pick, so it does not measure the ordering. The device case in `docs/test-queue.md` is the check.
**Area:** `plugins/super-bootstrap/skills/session-close/SKILL.md` step 3b and pick; `plugins/super-bootstrap/skills/commit/SKILL.md` § Session-close entries; `plugins/super-bootstrap/agents/doc-sync-scan.md` § Scan step 8
