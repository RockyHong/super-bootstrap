# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: restore two positional args to the `fmt_money(cents, currency, locale)` contract, no judgment; closure: one call site in one module, no other caller of `dunning.letter` / `letters` in repo, no contract change.

### Repro (pinned)

"A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`."

Reduced: `dunning.letter(Account(..., currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due=15))` → `{amount}` renders `en_GB 312.40`.

### Root cause (verified)

- **Card prior falsified.** `tally/money.py:16` holds `"GBP": "£"`; `tests/test_money.py:11` asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. `fmt_money` is correct. Prior excluded from judgment.
- **Mechanism:** `tally/reports/dunning.py:45` — `fmt_money(account.past_due_cents, account.locale, account.currency)` swaps locale and currency against signature `fmt_money(cents, currency, locale)` (`money.py:76`). Trace with `currency="en_GB"`, `locale="GBP"`:
  - `SEPARATORS.get("GBP", SEPARATORS["en_US"])` → `(",", ".")` (money.py:81)
  - `SYMBOLS.get("en_GB")` → `None` → prefix `"en_GB "` (money.py:82-83, unknown-code fallback)
  - body `312.40` → `"en_GB 312.40"` — exact match with the screenshot.
- **Surface:** dunning letters — `{amount}` slot of `reminder` / `second_notice` / `final_notice` ("customer-facing past-due notices, sent by email and post", dunning.py:1). Same function's `fee=` (dunning.py:46) uses correct order, so a `second_notice` shows wrong `{amount}` beside correct `{fee}`.
- **Reach beyond GBP:** swap hits every dunning recipient — `{amount}` always prints `"{locale} "` prefix + en_US separators (e.g. `de_DE 1,234.56` for EUR/de_DE). Fix scope unchanged.
- **Family sweep** (every `fmt_money` call site): notify.py:10,11,18 · api/handlers.py:14,16,28,37 · exports/csv_export.py:24,25 · exports/json_export.py:16,18,20,23 · exports/pdf_export.py:19,21,23,25 · dunning.py:46 — all correct `(cents, currency, locale)` order. cli.py:21, reports/summary.py:10-18, reports/aging.py:28 omit locale (en_US separators) — cannot yield a locale-code prefix, ops-internal output; outside this symptom class. dunning.py:45 is the sole swapped instance.

### Files (fix surface)

- `tally/reports/dunning.py:45` — reorder to `fmt_money(account.past_due_cents, account.currency, account.locale)` (keyword args optional hardening).
- `tests/test_dunning.py` (new; no dunning test exists) — GBP / en_GB account, `past_due_cents=31240`, `days_past_due=15` → letter contains `£312.40`, not `en_GB`. Fails on current code.
- Provenance: all files native to this repo (no import marker / manifest); no upstream route.

### Doc Impact

none — confirmed unchanged after read: README.md (lists dunning letters, no format claim), `money.py` docstring (describes correct contract), `docs/decisions.md` (no closed forks).

### Test Strategy: unit
