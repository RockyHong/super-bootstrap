# Carry — GAP-064: pilot sync issues shipped as v2.41.0; migration tail still open

## Anchor

GAP-064 + OUT-001. Pilot (Magnetized Remake) synced 2.34.2 → 2.40.0, verdict `SYNC WITH ISSUES` — mechanism clean. The three producer findings are resolved on `main` (DEBT-096 `2770607` test-queue parser + note · DEBT-098 `5479fde` declined · DEBT-097 `7ae4935` stale-vs-fork hook copy-on-drift) and released as **v2.41.0** (tag pushed). Card + OUT-001 close only when the pilot migrates its author-moved cards (its DEBT-088).

## Read first

1. `docs/work/GAP-064.md` — last Progress block (`consumer pilot sync`).
2. `git log 2770607..7ae4935` — what shipped for the pilot's findings; `docs/work/GAP-065.md` (multi-root consult-check, the pilot's underlying need) · `DEBT-099.md` (worktree template `_comment`, deferred).
3. `docs/outward.md` — OUT-001 (tail = delete GAP-064).
4. Pilot (PRIVATE — read by path, never copy): `D:/Git/Games/Magnetized Remake/docs/work/DEBT-088.md`.

## State

`f5c26c0` (cards) pushed; `2770607` · `5479fde` · `7ae4935` (fixes) + `d9f4fe8` (release v2.41.0) pushed; `main == origin/main`. Installed plugin cache still 2.40.0 → `/plugin update super-bootstrap` + restart before the pilot sync. Platform finding (user-scope plugin pin overriding project-scope) → `/contribute` to claude-shape lore alongside the two from the jowagoko sync — not yet filed.

## Next step

1. Pilot repo: migrate its author-moved cards per its DEBT-088 → here: delete `docs/work/GAP-064.md` + OUT-001 via `/super-bootstrap:commit` (card-lifecycle exemption). Then this carry clears.
2. `/plugin update super-bootstrap` (→ 2.41.0) + restart; pilot re-runs `/super-bootstrap:harness-bootstrap` sync — the new hook path: its first sync after upgrade will raise fork prompts for its multi-root `consult-check-*` (no `placed` entry) — expected; pick `keep` until GAP-065 lands.
3. `/contribute` the plugin-scope-resolution lore (three platform findings now).

## Watch-outs

- PUBLIC repo; consumer specifics stay out of docs/tests/cards.
- Harness commits: audit → `git add` → `harness-audit-pretool.sh --stamp` → `git commit`, three separate calls; never stage `__pycache__`.
- `render-board.py` changes must keep `bench/todo-board/` goldens green.
- serve-freshness: `agent-model-pretool.sh` stale → `/resolve-claude-config` when convenient (unrelated).
