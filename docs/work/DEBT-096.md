# DEBT-096 — harness-bootstrap sync accepts a `test-queue.md` skeleton header over rows the board cannot parse

**Logged:** 2026-08-27 · **Source:** consumer pilot sync report (2.34.2 → 2.40.0, GAP-064 / OUT-001 tail) — anomaly 4
**Problem:** On the drifted-header-over-filled-entries branch, [`harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md) § 2b accepted the `docs/test-queue.md` skeleton header while the consumer's existing rows — a table shape it had declined the skeleton for at 2.34.2 — were carried verbatim under `## Pending`. [`render-board.py`](../../plugins/super-bootstrap/skills/todo/assets/render-board.py) parses only `### ` entries in that section, so `/super-bootstrap:todo` reports `test-queue (0 entries)` while two rows exist: the sync passed silently and left a container the board reads as empty. Neither the sync-report row nor the board says the rows are unparseable.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2b scale-module drift check (test-queue row) · [`assets/scale/test-queue-skeleton.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/test-queue-skeleton.md) § Entry shape · `todo/assets/render-board.py` test-queue parser
**Prior:** Have the header-drift row on a filled container also compare the carried entries against the skeleton's entry shape and surface a `rows not in entry shape → board reads 0` note (offer reshape / declined), rather than accepting the header alone; alternatively the board prints a `# note:` when a `## Pending` section holds non-`### ` content.
**Test-feel:** manual
**Stochastic:** llm
**Blast:** pkg
