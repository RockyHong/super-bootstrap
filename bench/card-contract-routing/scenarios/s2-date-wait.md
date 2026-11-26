The repo's files (paths only, except the one shown whole below): `README.md`, `docs/overview.md`, `docs/specs/cache.md`, `docs/work/README.md`, `docs/work/TEMPLATE.md`, `docs/work/DEBT-41.md`, `src/cache/store.py`.

=== docs/work/DEBT-41.md ===
# DEBT-41 — Cache hit rate dropped after the store rewrite

**Logged:** 2026-11-18 · **Source:** dashboard
**Problem:** Hit rate fell from 92% to 71% after the `src/cache/store.py` rewrite.
**Area:** `src/cache/store.py`

## Verdict — auto-fix · 2026-11-19

**Fix-shape:** mechanical
The eviction key drops the tenant prefix; restore it in `store.py`.

=== task ===
Today is 2026-11-26. You restored the tenant prefix in `store.py` and it is committed. The fix ships with the weekly deploy on 2026-12-03; the hit rate can only be re-measured on production traffic after that deploy, so the next step — re-measure the hit rate and resolve the card if it is back above 90% — cannot run before 2026-12-03. You are ending the session now. Park this work on the card, following the card contract above.
