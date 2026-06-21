---
paths:
  - "docs/**/*.md"
  - "README.md"
description: "Fires on read of a prose doc. Classify its dimension (state vs history) before propagating — the emit half of doc-dimension discipline. Predicate in work-discipline/doc-dimension-discipline.md."
---

# Dimension Discipline — Classify Before You Propagate

Before editing a prose doc, classify what it owns: **state** (what is true now —
overwrite stale facts in place) or **history** (a dated chronicle of what was
decided when — append-only, git's job, not prose).

Author to the doc's dimension: state-SSOT overwrites to truth-now; a binding past
decision states present-tense as a live constraint, stripped of when/why-decided;
verification stamps (last-checked dates) stay; genuine chronicle routes to git.

**Tripwire — the artifact is the trap.** If the doc you are about to edit ALREADY
mixes dimensions (timestamps crawling into a state-SSOT, a chronicle leaking
current constraints), do NOT follow its pattern. STOP and surface:

- **what** — the mixed section + which dimension leaked
- **expected** — the clean single-dimension shape
- **options** — overwrite to state-now · extract chronicle to git · keep (with reason)

Full classify + route + audit predicate in
`.claude/guidelines/work-discipline/doc-dimension-discipline.md`.
