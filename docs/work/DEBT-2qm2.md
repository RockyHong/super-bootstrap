# DEBT-2qm2 — `doc-sync-harness-cochange` (a2) counts a deferral phrase in a non-recommended option

**Logged:** 2026-11-09 · **Source:** GAP-drwb post-audit runs (commit `16616ce`), session-close of the same session
**Problem:** `bench/doc-sync-harness-cochange/score.sh` (a2) failed run `d1` on "Acknowledge ep-prep as accurate for now and leave it for a separate harness edit." That line is the description of an alternative AskUserQuestion option ("Row 1 only"). The recommended option landed `ep-prep` this round. (a2) reads every line that names `ep-prep`, so an offered alternative reads as the run deferring the item.
**Area:** `bench/doc-sync-harness-cochange/score.sh` (a2), `bench/doc-sync-harness-cochange/bite.sh`
**Prior:** Score (a2) on the recommended path only (prose rows plus the first / recommended option of the ask), then re-bite.
