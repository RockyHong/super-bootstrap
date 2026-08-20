# bench/todo-board — golden test for the mechanical board renderer

Test surface for [`skills/todo/assets/render-board.py`](../../plugins/super-bootstrap/skills/todo/assets/render-board.py),
the zero-dispatch executor of [`shared/classify-actionable.md`](../../plugins/super-bootstrap/shared/classify-actionable.md)
+ the todo agent's rank/render protocol. An edit to the classification spec, the
scaffolds, or the script re-runs this bench (`bash bench/todo-board/run.sh`).

- `fixture/` — a mini project root: 13 cards + a test queue covering every spec
  branch (raw · surface verdict · surface verdict ruled by a later approved Design ·
  surface verdict plus an unrelated Amendment · Amendment-only · auto-fix derive ·
  unapproved Design · executing with Progress · review suppressed by a queue
  back-pointer · harness pre-filter · hard block · hard-blocked Discuss row (held
  out of the body, counted in the footer) · user-blocker override · non-canonical
  file).
- `fixture-empty/` — substrate present, no cards (empty-state render).
- `fixture-allblocked/` — two cards mutually hard-blocked: zero body rows, yet the
  board must still disclose them (`pending unblock: 2`), never the empty state.
- `expected/` — goldens for all six modes plus the empty and all-blocked states, pinned to
  `--date 2026-08-14`.

One known accepted divergence from a cold agent render: the soft-coupling
*direction* cell is mechanically normalized (the row declaring the shared path
in a Design/Plan block is upstream — the spec's literal reading); a cold agent
may judge the same edge semantically. Every other cell is pinned equivalent by
these goldens.
