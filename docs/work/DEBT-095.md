# DEBT-095 — todo board: the Uncategorized table's "Why ambiguous" cell escapes the sheet width budget

**Logged:** 2026-08-27 · **Source:** sheet-columns change (commit `907a325`) — the ID + 60-char Action budget covers every board table except Uncategorized, whose reason cell is left at full length
**Problem:** [`render-board.py`](../../plugins/super-bootstrap/skills/todo/assets/render-board.py) renders the Uncategorized table with the reason text verbatim — `UNCAT_REASON` is ~130 chars and the substrate-absent notice ~160 chars — so on the TUI's fixed-width grid the whole row wraps into several lines, the one shape the sheet change removed from every other table. The reason carries a routing instruction (`New cards route through /super-bootstrap:log`), so a plain 60-char cut would drop the actionable part.
**Area:** `plugins/super-bootstrap/skills/todo/assets/render-board.py` (`UNCAT_REASON`, the substrate-absent `uncat.append`, the Uncategorized `table(...)` call) · `assets/scaffolds.md` § Sheet columns ("Uncategorized excepted") · `bench/todo-board/expected/*` goldens carrying an Uncategorized row
**Prior:** Shorten the two reason strings to a one-line pointer (`not a card — see docs/work/README.md § Routing`) and bring the table under the same width budget; or render Uncategorized as a list below the tables instead of a table.
**Test-feel:** unit
**Blast:** local
