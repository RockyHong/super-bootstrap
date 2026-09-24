# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two positional args back to the signature order, no judgment; closure: one call site in `tally/reports/dunning.py` plus one new unit test, no contract or doc change

### Repro (pinned)

"A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`."

Code-level repro: `dunning.letter(Account(..., currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due>=15))` → body contains `en_GB 312.40`.

### Root cause (verified)

- **The card's prior is false.** `tally/money.py:16` still has `"GBP": "£"` in `SYMBOLS`, and `tests/test_money.py:11` already asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. So `fmt_money` is correct when it gets the right arguments. I did not use the prior as evidence.
- **The bug:** `tally/reports/dunning.py:45` calls `fmt_money(account.past_due_cents, account.locale, account.currency)`. That passes locale and currency in the wrong order. The signature at `tally/money.py:76` is `fmt_money(cents, currency, locale=...)`.
- **Why the symptom follows:**
  - `currency="en_GB"`, so `SYMBOLS.get("en_GB")` returns `None`, and line 83 falls back to the prefix `"en_GB "`.
  - `locale="GBP"` is not in `SEPARATORS`, so line 81 falls back to en_US separators (`,` / `.`).
  - `31240` cents therefore renders as `en_GB 312.40`, which matches the screenshot exactly.
- **Surface:** dunning letters, "customer-facing past-due notices, sent by email and post" (`dunning.py:1`). The `{amount}` placeholder appears in all three stages (reminder, second_notice, final_notice). The `{fee}` on line 46 uses the correct order and renders `£35.00`.
- **Family sweep:** I checked every `fmt_money` caller. `notify.py:10,11,18`, `api/handlers.py:14,16,28,37`, `exports/pdf_export.py:19-25`, `exports/json_export.py:16-23` and `exports/csv_export.py:24-25` all pass `(cents, currency, locale)` in the right order. `dunning.py:45` is the only swapped call.
- **Out of scope, not this symptom:** `cli.py:21`, `reports/aging.py:28` and `reports/summary.py:10-18` leave out `locale`. They render the correct symbol but always use en_US separators. That matters only for non-`.`-decimal locales, and these look like internal reports. It could be filed as a separate card if they turn out to reach customers.

### Files (fix surface)

- `tally/reports/dunning.py:45` — change to `fmt_money(account.past_due_cents, account.currency, account.locale)`. Keyword args (`currency=`, `locale=`) would also prevent this from happening again.
- `tests/` (new, e.g. `tests/test_dunning.py`) — failing repro: a GBP / en_GB account with `past_due_cents=31240` and `days_past_due=15` gives a `letter()` containing `£312.40` and not `en_GB`.
- Provenance: all files are native to this repo. There is no marker, manifest or serving-repo template.

### Doc Impact

none — confirmed unchanged after read (`README.md:7` only lists dunning letters as a formatting consumer; `docs/decisions.md` has no closed forks; no overlapping open card — BUG-001 is unrelated refund dedupe).

### Test Strategy: unit
