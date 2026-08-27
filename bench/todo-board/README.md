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
- `fixture-actor-retired/` — two origin-only cards still carrying the retired
  `Actor:` fact field (`external` / `author`), no wait keyword in their prose: the
  field is inert — both classify by their thread state (`Triage` rows, Drainable 2)
  and each draws a `# note:` naming the leftover. Its goldens append both stderr
  lines (`# note:` and `# sources:`) to the board.
- `fixture-outward/` — one card plus a `docs/outward/` folder holding three entry
  threads beside its standing `README.md`: the outward-owned wall, the `Waiting on`
  split and **latest block leads**. `OUT-002` (waiting on `author`, carrying an
  `Owning card:` back-pointer) and `OUT-001` (origin waiting on the font vendor, an
  `## Amendment` re-pointing it to `author`) render under **Outward — your move**,
  `OUT-003` (waiting on a platform team, origin only) under **Outward — waiting on
  others** — so `OUT-001`'s group can only come from the appended block, never the
  origin. The owned card is held out of the body in both modes (Drainable 0,
  `pending unblock: 1`) while the entry's own `unblocks 1` stays the leverage
  signal, and the folder's `README.md` is skipped silently.
- `fixture-outward-legacy/` — the same card beside a lingering flat
  `docs/outward.md` (the retired one-file form): the legacy branch renders the board
  byte-for-byte as the flat form always did AND names the sync that splits it. Its
  golden appends both stderr lines (`# note:` and `# sources:`) to the board. Two
  further cases run off this fixture. `split-outward` copies it to a temp root and
  runs [`assets/scale/split-outward.py`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/split-outward.py)
  over it against the shipped README skeleton (a temp skeleton carrying the same
  high-water line shape stands in while the skeleton is not on disk), pinning the
  migration: the produced set is `README.md` + one `OUT-###.md` per chunk, the README
  carries the flat header's consumed ID (`OUT-002`), `OUT-002.md` is byte-identical
  to `fixture-outward/`'s, the flat file is gone and the re-render is `# note:`-free.
  `split-outward-refuse` puts a flat file back beside the live folder: the script
  refuses rather than overwriting.
- `fixture-venue/` — the scale module wired: a `.claude/rules/venue-map.md`
  copied from the shipped skeleton (the compare reads its tables, so prose
  rewordings upstream leave this green), plus cards exercising the wired lane split
  (`agents/todo.md` § Lane split) — raw → **T** drainable · `Stochastic: llm` →
  **P** probe · review-stage `Test-feel: manual` → **U** device (its intent is
  still `Cloud`, so the group can only come from the venue) · review-stage
  `Test-feel: e2e` → **S** drainable · review-stage `Stochastic: llm` with no
  `Test-feel` → **P** probe (the verify phase reads `Stochastic` when no
  `Test-feel` decides it) · `surface` verdict → decide (intent `Discuss` wins
  over venue) · triaged `Test-feel: manual` → **T**
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
  retired-actor, outward, legacy-flat-outward, wired-map, pre-substrate, and
  unparseable-queue states, pinned to `--date 2026-08-14`. The two `split-outward`
  cases assert properties of a temp root instead of a golden — the split writes into
  a copy, so there is nothing stable to byte-compare but the entry file it produces.

One known accepted divergence from a cold agent render: the soft-coupling
*direction* cell is mechanically normalized (the row declaring the shared path
in a Design/Plan block is upstream — the spec's literal reading); a cold agent
may judge the same edge semantically. Every other cell is pinned equivalent by
these goldens.
