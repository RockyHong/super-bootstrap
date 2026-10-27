---
paths:
  - "docs/**/*.md"
  - "README.md"
  - "plugins/*/README.md"
description: "Fires on read of a prose doc. Classify its dimension (state vs history) and author to it before propagating — classify, route, dimension: history declaration, mixed-doc tripwire and mixed-dimension shapes."
---

# Dimension Discipline — Classify Before You Propagate

Before editing a prose doc, classify its dimension — **state** (true now) or
**history** (a dated chronicle) — and author to that dimension. A doc or section
owns one dimension, never both.

## Classify

- **State** — what is true *now*. Kept current by overwriting stale facts in
  place. Overview, techstack, architecture, backlog rows, status fields.
- **History** — a timeline or decision chronicle: what was decided when, why,
  prior values. Append-only. Git (log + commit messages) is its default home.

Classified history → declare it in the doc's leading YAML frontmatter:

```yaml
---
dimension: history
---
```

The commit door's doc-sync scan keys on this field: it leaves the doc's rows out
of the stale-doc scope and still checks its links.

## Route

1. **State → overwrite in place.** Replace the stale fact; add no "was X, now Y"
   note.
2. **History → git.** A hand-maintained "what happened when" chronicle restates
   git — drop it. Where a rationale is expensive to reconstruct from diffs, a
   one-line pointer to the commit beats re-prosing it. A history doc the repo
   keeps carries `dimension: history` (above).
3. **Binding past decision → present-tense constraint.** A past decision that
   still binds future work is a live constraint. State it present-tense in the
   state doc it governs, stripped of when/why-decided: "Refinement is deferred
   behind the port" — not "on <date> we decided to defer refinement because…".
4. **When-checked → git.** A "last checked on <date>" stamp belongs in git commit
   metadata; keep the date out of the body. A version-bound pin ("valid as of
   vX.Y") is substantive state — it bounds the fact's validity — and stays.
5. **Ticket IDs → chronicle homes.** A durable doc records the decided behavior
   or policy present-tense, never the card that decided it (`BUG-##`, `DEBT-##`,
   any tracker prefix). Ticket refs belong in history-dimension docs (decision
   logs) and temporal work-tracking files (cards, handoffs — their provenance
   fields); git log serves the rest.

## Tripwire — the artifact is the trap

If the doc you are about to edit ALREADY mixes dimensions, do not follow its
pattern. STOP and surface:

- **what** — the mixed section + which dimension leaked
- **expected** — the clean single-dimension shape
- **options** — overwrite to state-now · extract chronicle to git · keep (with reason)

Mixed-dimension shapes:

1. **Chronicle crawl-in** — timestamps, "was X, now Y", ticket-ID refs ("per
   `DEBT-###` …") or decision-dated prose accumulating in a state doc.
2. **Stale workspace doc** — a status doc gone out of date against the reality it
   claims to track.
3. **State leak into history** — a history or decision-timeline doc carrying
   current knowledge that belongs in a state doc.

## Scope

Applies to authored prose docs (overview, techstack, architecture, backlog,
READMEs). Harness files (skills, agents, rules) carry their own discipline.
Whole-surface audit for these shapes: `/super-bootstrap:check-docs-consistency`.
