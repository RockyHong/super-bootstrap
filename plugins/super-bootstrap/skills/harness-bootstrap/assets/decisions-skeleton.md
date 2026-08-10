# Decisions

> **History-dimension doc.** Owns *closed forks / rejected directions* across every domain — tech, product, business, design. Append-only: entries are added, never edited to "now".
>
> **Annotating a closed row — additive only.** A row may be annotated in place when its answer is later overturned, or when one of its grounds dies while the verdict stands. One bound, verifiable by reading: **existing row text is never deleted or reworded.** The later answer prefixes the `Because` cell and the superseded text follows verbatim behind `Original rejection, preserved:` / `Original deferral, preserved:`; a ground that has since died gets a sentence appended naming what moved and what still carries the verdict; the `Ref` cell appends, never replaces. An edit that overwrites, restates, or wording-syncs existing text is not an annotation — leave the row as it stands and let git log hold the correction.
>
> **Lands here** — a direction genuinely evaluated and **closed** that (a) left **no diff** (road-not-taken, wall foreseen — git can't hold what was never committed) AND (b) would otherwise be re-proposed.
>
> **Does NOT land here:**
> - Committed change history (what changed / when / why-of-a-change) → **git log + commit messages**.
> - A past decision that still **binds** current work → present-tense constraint in the state doc it governs (`docs/techstack.md`, `docs/overview.md`), stripped of when/why-decided.
> - A closure obvious from current state → no entry.
>
> **Checked at triage** (`CLAUDE.md` § Development Workflow) before any route or design is proposed — a closed fork surfaces *before* it is re-walked. Routing rule in `CLAUDE.md` § Doc Sync.

## Closed Forks

<!-- Newest first. One fork per row. Keep terse — the closing reason, not a narrative. Domain ∈ tech | product | business | design. -->

| Domain | Rejected direction | Because | Ref |
|---|---|---|---|
