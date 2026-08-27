# bench/todo-board — golden test for the mechanical board renderer

Test surface for [`skills/todo/assets/render-board.py`](../../plugins/super-bootstrap/skills/todo/assets/render-board.py),
the zero-dispatch executor of [`shared/classify-actionable.md`](../../plugins/super-bootstrap/shared/classify-actionable.md)
+ the todo agent's rank/render protocol. An edit to the classification spec, the
scaffolds, or the script re-runs this bench (`bash bench/todo-board/run.sh`).

- `fixture/` — a mini project root: 13 cards + a test queue (entries in the shape
  `test-queue-skeleton.md` § Entry shape ships) covering every spec
  branch (raw · surface verdict · surface verdict ruled by a later approved Design ·
  surface verdict plus an unrelated Amendment · Amendment-only · auto-fix derive ·
  unapproved Design · executing with Progress · review suppressed by a queue
  back-pointer · harness pre-filter · hard block · hard-blocked Discuss row (held
  out of the body, counted in the footer) · wait override (user arm) · non-canonical
  file).
- `fixture-empty/` — substrate present, no cards (empty-state render).
- `fixture-allblocked/` — two cards mutually hard-blocked: zero body rows, yet the
  board must still disclose them (`pending unblock: 2`), never the empty state.
- `fixture-extwait/` — one card whose approved Design rules the aim to be a wait on an
  external party: the wait override's external arm — a `Decide` row naming the party,
  Drainable 0, never a `Start execute`.
- `fixture-actor/` — two origin-only cards carrying the scale module's `Actor:` fact
  field (`external` / `author`), no wait keyword in their prose: the actor override —
  a `Decide` row naming the mover, Drainable 0, never a `Triage`.
- `fixture-outward/` — one plain drainable card plus a `docs/outward.md` holding two
  entries (one with an `Owning card:` back-pointer): the outward group — its own
  need-me table, `unblocks` from the owning card, the card's own `Triage` row still
  drainable.
- `fixture-venue/` — the scale module wired: a `.claude/rules/venue-map.md`
  copied from the shipped skeleton (the compare reads its tables, so prose
  rewordings upstream leave this green), plus cards exercising the wired lane split
  (`agents/todo.md` § Lane split) — raw → **T** drainable · `Stochastic: llm` →
  **P** probe · review-stage `Test-feel: manual` → **U** device (its intent is
  still `Cloud`, so the group can only come from the venue) · review-stage
  `Test-feel: e2e` → **S** drainable · review-stage `Stochastic: llm` with no
  `Test-feel` → **P** probe (the verify phase reads `Stochastic` when no
  `Test-feel` decides it) ·
  `surface` verdict and `Actor: author` →
  decide (intent `Discuss` wins over venue) · triaged `Test-feel: manual` → **T**
  drainable (a modality field gates only its own phase, and verify is not the
  next phase here).
- `fixture-venue-edited/` — the same cards under a map whose Venues table differs
  from the skeleton by one cell: identical board, plus the `# note:` stderr line.
- `fixture-nosubstrate/` — a pre-substrate repo: `docs/work/README.md` present but
  without the ID high-water line, plus one non-card file. The board emits the single
  substrate row (the literal `agents/todo.md` § Stale scaffold mandates) and keeps
  the per-file `not a card` row beside it, Drainable 0 — never the empty state.
- `fixture-queue-table/` — one card plus a `docs/test-queue.md` whose `## Pending`
  holds a markdown table instead of `### ` entries: the board parses zero entries
  and says so on the `# note:` stderr channel. Its golden appends both stderr
  lines (`# note:` and `# sources:`) to the board.
- `expected/` — goldens for all six modes plus the empty, all-blocked, external-wait,
  actor, outward, wired-map, pre-substrate, and unparseable-queue states, pinned to `--date 2026-08-14`.

One known accepted divergence from a cold agent render: the soft-coupling
*direction* cell is mechanically normalized (the row declaring the shared path
in a Design/Plan block is upstream — the spec's literal reading); a cold agent
may judge the same edge semantically. Every other cell is pinned equivalent by
these goldens.
