# Carry — GAP-064: pilot sync returned WITH ISSUES; producer findings carded, migration tail still open

## Anchor

GAP-064 + OUT-001. Pilot (Magnetized Remake) synced 2.34.2 → 2.40.0, verdict `SYNC WITH ISSUES` — mechanism clean, issues carded here as DEBT-096 / 097 / 098. Card + OUT-001 close only when the pilot migrates its author-moved cards (its DEBT-088).

## Read first

1. `docs/work/GAP-064.md` — last Progress block (`consumer pilot sync`).
2. `docs/work/DEBT-096.md` · `DEBT-097.md` · `DEBT-098.md` — raw, un-triaged; pickup via `/super-bootstrap:todo` → `/super-bootstrap:triage`.
3. `docs/outward.md` — OUT-001 (tail = delete GAP-064).
4. Pilot (PRIVATE — read by path, never copy): `D:/Git/Games/Magnetized Remake/docs/work/DEBT-088.md`.

## State

Cards + GAP-064 Progress landed as `f5c26c0`, pushed to `origin/main`. Platform finding (user-scope plugin pin overriding project-scope) → `/contribute` to claude-shape lore alongside the two from the jowagoko sync — not yet filed.

## Next step

1. Pilot repo: migrate its author-moved cards per its DEBT-088 → here: delete `docs/work/GAP-064.md` + OUT-001 via `/super-bootstrap:commit` (card-lifecycle exemption). Then this carry clears.
2. Triage DEBT-096..098 at pickup; DEBT-098 is doc-only on a shipped skeleton (harness edit → `load-harness-principles` pre / `audit-harness-edits` post, dogfood `.claude/rules/venue-map.md` in the closure, `render-board.py` cell compare must stay equal).
3. `/contribute` the plugin-scope-resolution lore (three platform findings now).

## Watch-outs

- PUBLIC repo; consumer specifics stay out of docs/tests/cards.
- Harness commits: audit → `git add` → `harness-audit-pretool.sh --stamp` → `git commit`, three separate calls; never stage `__pycache__`.
- `render-board.py` changes must keep `bench/todo-board/` goldens green.
- serve-freshness: `agent-model-pretool.sh` stale → `/resolve-claude-config` when convenient (unrelated).
