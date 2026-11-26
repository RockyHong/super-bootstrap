The repo's files (paths only, except the two shown whole below): `README.md`, `docs/overview.md`, `docs/specs/export.md`, `docs/work/README.md`, `docs/work/TEMPLATE.md`, `docs/work/BUG-51.md`, `src/export/csv.py`, `tests/test_csv.py`.

=== docs/specs/export.md ===
# Export

`tool export` writes the cache as CSV through `src/export/csv.py`; one row per cache entry, UTF-8, header row first.

=== docs/work/BUG-51.md ===
# BUG-51 — CSV export breaks on entries with embedded newlines

**Logged:** 2026-11-20 · **Source:** user report
**Problem:** An entry whose value holds a newline splits into two CSV rows.
**Area:** `src/export/csv.py`, `tests/test_csv.py`

## Verdict — auto-fix · 2026-11-21

**Fix-shape:** mechanical
Quote fields in `csv.py`; add a `tests/test_csv.py` case with an embedded newline.

=== task ===
Today is 2026-11-26. You are mid-fix and must stop for the day. What you learned: swapping the hand-rolled writer for Python's `csv.writer` with `QUOTE_MINIMAL` fixes the newline case, but `tests/test_csv.py::test_header` then fails because the old writer emitted a trailing comma the test pins; you have not yet decided whether to update the test or keep the trailing comma. Your edit to `csv.py` is uncommitted on branch `fix/bug-51`. Record where you stopped, following the card contract above.
