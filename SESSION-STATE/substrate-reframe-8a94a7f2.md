# Carry — work-tracking substrate reframe

## Anchor

Owner reframed the tracking substrate mid-Wave-2: ledger/thread-shaped, root
ticket append-only with a breadcrumb for each reframe, per-item folder+file
instead of one `backlog.md`. Deep discussion deliberately deferred to a cold
session — this session was heavy (Wave 1 build + cold audit + triage).

## Read first

1. `docs/work/triage/DEBT-034-notes.md` — the discussion's entry point. Maps
   three refusal loops and the full propagation closure.
2. `docs/backlog.md` — `GAP-047` (the reframe), `BUG-022` (third refusal loop).

## State

Wave 1 shipped and pushed — DEBT-037, DEBT-021, DEBT-038, BUG-019, GAP-037
resolved across five commits. Board at 16 open rows.

Wave 2 (write-once disposal) opened and stopped at its decision point.
`/super-bootstrap:triage DEBT-034` returned a `surface` verdict that re-aimed
the card: the defect is that the backlog states row immutability while naming
no one who may amend a live row. Its four options (A split by evidence grade /
B write the amendment clause now / C verdict artifact as amendment site /
D delete-and-re-log) were put to the owner and **not answered** — the reframe
arrived instead and may dissolve the question.

## Next step

Cold-open the substrate discussion from `GAP-047`. It plausibly subsumes
DEBT-034, DEBT-036, DEBT-022, DEBT-027 — check that before treating any of the
four as independent work.

## Watch-outs

- The DEBT-034 verdict falsified two of that card's own claims, including its
  citation of `docs/decisions.md` — the fork it cites records the opposite.
  Read the verdict, not the card's Prior.
- The remaining Wave grouping from this session's board read: B write-once
  (DEBT-034→036) · C dispatch cost (DEBT-027→022→023→030) · D fire-moment
  gates (GAP-045→046) · E single-call (BUG-020, GAP-042, GAP-044, BUG-021,
  BUG-022) · F parked (GAP-038 retire candidate, DEBT-035 blocked on the
  mattpocock adoption decision).
- `docs/work/triage/` was created this session — it had zero live instances
  before, which matters to option C above.
