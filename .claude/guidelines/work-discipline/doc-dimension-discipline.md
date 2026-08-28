# Doc Dimension Discipline — State XOR History

A prose doc or section owns one **dimension**: *state* (what is true now) or
*history* (a dated chronicle of what was decided when), never both. Mix them and
every sentence forces the reader to ask "true now, or a past record I'm
mis-trusting as current?" — dimension pollution. This is the
**doc-dimension-ssot** axiom (state XOR history sharpens single-source-of-truth's
clear-pillars) expressed as a work-moment predicate.

This file owns the **classify + audit predicate** — how to tell a doc's dimension
and what pollution looks like. Sibling artifacts cite it and add the action: the
emit rule (`.claude/rules/dimension-discipline.md`) classifies-before-propagating
at writing time; `check-docs-consistency` flags the pollution at audit time. The
predicate lives here; the action lives with each.

## Classify — state vs history

- **State-SSOT** — what is true *now*. Kept current by overwriting stale facts in
  place. Overview, techstack, architecture, backlog rows, status fields.
- **History-SSOT** — a timeline / decision chronicle: what was decided when, why,
  prior values. Append-only. Git (log + commit messages) is the canonical home —
  free, drift-proof.

## Route — where each dimension goes

1. **State → overwrite in place.** The state-SSOT carries truth-now; on change,
   replace the stale fact, don't append a "was X, now Y" note.
2. **History → git.** A hand-maintained "what happened when" prose chronicle is a
   derivative of git (maintaining it by hand edits the derivative — SSOT
   violation). Drop it. Where a rationale is genuinely expensive to reconstruct
   from diffs, a one-line pointer to the commit beats re-prosing it. A history
   doc the repo does keep declares `dimension: history` in its leading YAML
   frontmatter — the commit door's doc-sync scan keys on it to leave the doc's
   rows out of scope while still checking its links.
3. **Binding past decision → present-tense constraint.** A decision made earlier
   that still *binds* future work is a live constraint, not a record. State it
   present-tense in the state-SSOT, stripped of when/why-decided. "Refinement is
   deferred behind the port" — not "on <date> we decided to defer refinement
   because…".
4. **When-checked → git.** A "last checked on date" stamp reads as freshness
   metadata, but the datum is historical — git commit metadata is its drift-proof
   home; an in-body copy is a parallel truth that goes stale on the next overwrite.
   The standing decay note plus git cover freshness; the body carries no date. A
   version-bound pin ("valid as of vX.Y") is the exception — it bounds the fact's
   validity, so it is substantive state, not a date stamp.
5. **Ticket IDs → chronicle homes.** A ticket-ID reference (`BUG-##` / `DEBT-##`
   / any tracker prefix) in a durable doc is when/why-decided provenance leaking
   into state — record the decided behavior or policy present-tense; the deciding
   card is git log's to serve. Ticket refs belong in the chronicle homes by
   design: history-dimension docs (decision logs) and temporal work-tracking
   files (cards, handoffs — their origin provenance fields).

## Audit predicate — pollution shapes

A doc shows dimension pollution when any holds:

1. **Chronicle crawl-in** — timestamps / "was X, now Y" / ticket-ID refs ("per
   `DEBT-###` …") / decision-dated prose accumulating in a persistent state-SSOT
   doc.
2. **Stale workspace doc** — a vaporizable / status doc gone out-of-date against
   the reality it claims to track.
3. **State leak into history** — a history / decision-timeline doc carrying
   persistent or cross-dimension knowledge that belongs in a state-SSOT home.

## Boundary

Applies to authored prose docs (overview, techstack, architecture, backlog,
READMEs) wherever the project keeps them — not harness MDs (skills / agents /
rules carry their own no-precedent discipline). Consumer artifacts cite this file
by path; the predicate lives here only.
