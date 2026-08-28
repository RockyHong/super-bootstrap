---
paths:
  - "docs/**/*.md"
  - "README.md"
  - "plugins/*/README.md"
description: "Fires on read of a prose doc. Classify its dimension (state vs history) and author to it before propagating. Full predicate in work-discipline/doc-dimension-discipline.md."
---

# Dimension Discipline — Classify Before You Propagate

Before editing a prose doc, classify its dimension — **state** (true now) or
**history** (a dated chronicle) — and author to that dimension. One thing reads
as history but stays: a still-binding past decision states present-tense as a live
constraint. A "last-checked" date is not an exception — its home is git commit
metadata, not the body (a version-bound pin like "valid as of vX.Y" is a
substantive fact, not a date stamp). A ticket-ID reference (`BUG-##` / any
tracker prefix) is chronicle too — a durable doc records the decided behavior,
never the card that decided it; ticket refs belong in history-dimension docs and
temporal work-tracking files (their provenance fields), git log holds the rest.

Classified history → declare it in the doc's leading YAML frontmatter, `dimension: history`.

**Tripwire — the artifact is the trap.** If the doc you are about to edit ALREADY
mixes dimensions (timestamps crawling into a state-SSOT, a chronicle leaking
current constraints), do NOT follow its pattern. STOP and surface:

- **what** — the mixed section + which dimension leaked
- **expected** — the clean single-dimension shape
- **options** — overwrite to state-now · extract chronicle to git · keep (with reason)

Full classify + route + audit predicate in
`.claude/guidelines/work-discipline/doc-dimension-discipline.md`.
