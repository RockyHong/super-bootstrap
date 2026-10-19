# GAP-0cf5 — /super-bootstrap:merge has no batch mode for landing several autorun branches

**Logged:** 2026-10-20 · **Source:** device note from `magnetized-remake` (D:/Git/Games/Magnetized Remake, runway 5.2.0), 2026-10-17
**Problem:** Landing 4 DONE autorun branches (~59 commits behind base each) took ~45 min wall clock, ~4 min of it necessary. Every branch conflicted on the same mechanical line (a test-roster count in a dev-harness doc), one had a real code conflict. Branches landed serially: each landing changed base so the next re-conflicted, and each re-ran a full static lane (~4 min).
**Area:** `plugins/super-bootstrap/skills/merge/SKILL.md`; autorun landing flow
**Prior:** Batch mode through an integration branch/worktree off base: merge all N in order, gateway runs and commits each merge, only a judgment-grade conflict dispatches a resolver, one verify lane on the integrated tree, ff base once; a mechanical repeat resolves once, not N times. Related: BUG-szkd, BUG-g6at.
