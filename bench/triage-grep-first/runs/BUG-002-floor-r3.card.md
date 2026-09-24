# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two positional args back to the signature order, no judgment; closure: one call site in one module, and `fmt_money` and every other caller stay unchanged

### Repro (pinned)

> A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`.

Surface isolated by trace (the crop did not show it): the dunning letter, `{amount}` field. Repro: `letter(Account(..., currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due=15))` → body contains `en_GB 312.40`.

### Root cause (verified)

- **Card prior falsified.** `tally/money.py:16` holds `"GBP": "£"`, and `tests/test_money.py:11` asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. `SYMBOLS` and `fmt_money` are correct. The prior was treated as a hypothesis to test and left out of the judgment.
- **Actual defect:** `tally/reports/dunning.py:45` calls `fmt_money(account.past_due_cents, account.locale, account.currency)`. The signature is `fmt_money(cents, currency, locale)` (`money.py:76`), so locale and currency land in each other's slots. The trace for this account:
  - `SYMBOLS.get("en_GB")` returns `None`, so `money.py:83` builds the prefix `"en_GB "`.
  - `SEPARATORS.get("GBP", …)` falls back to en_US `(",", ".")`.
  - The result is `"en_GB 312.40"`, an exact match for the screenshot. A de_DE/EUR account would render `de_DE 312.40`, so the defect hits every non-USD dunning letter.
- **Corroboration:** the next line, `dunning.py:46` (`fee=`), passes the arguments in the correct order. A `second_notice` letter therefore shows `en_GB 312.40` next to a correct `£35.00`. This fits "the only broken field is `{amount}`".
- **Family sweep:** every other customer-facing `fmt_money` caller passes `(cents, currency, locale)` in order: `api/handlers.py:14,16,28,37`, `notify.py:10,11,18`, `exports/csv_export.py:24,25`, `exports/json_export.py:16–23`, `exports/pdf_export.py:19–25`. The swap exists only at `dunning.py:45`.
- **Out of scope:** `cli.py:21`, `reports/aging.py:28` and `reports/summary.py:10–18` leave out `locale`, and aging/summary default to `currency="USD"`. These are operator-facing, a different output class, and cannot produce this symptom. They are not part of this fix.

### Files (fix surface)

- `tally/reports/dunning.py:45`: change the call to `fmt_money(account.past_due_cents, account.currency, account.locale)`. Keyword arguments (`currency=…, locale=…`) would guard against the same swap happening again. The file is native to this repo, with no import marker or serving source.
- `tests/`: new unit test for `dunning.letter`. There is no dunning test today; `grep dunning|letter(` finds only the module itself.

### Doc Impact

none — confirmed unchanged after read (`README.md`, `docs/decisions.md` (no closed forks), `money.py` docstring, which already states the correct signature)

### Test Strategy: unit

Failing-first test: build an `Account(currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due=45)`, then assert that `letter(account)` contains `£312.40` and does not contain `en_GB`. Add a de_DE/EUR case (`€312,40`) to cover the separator half of the swap.
