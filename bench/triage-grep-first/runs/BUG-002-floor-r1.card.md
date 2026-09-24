# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two positional arguments back to the order the signature declares, no judgment involved; closure: one call site in one module, no signature or contract change, no doc references it

### Repro (pinned)

"A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`."

Test case: `Account(currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due>=15, closed=False)` → `dunning.letter(account)` contains `en_GB 312.40`; expected `£312.40`.

### Root cause (verified)

- **The card's Prior is falsified.** `tally/money.py:16` still has `"GBP": "£"` in `SYMBOLS`, and `tests/test_money.py:11` asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. The formatter is correct.
- **The surface is dunning letters** (past-due notices sent by email and post; see the `tally/reports/dunning.py:1` docstring), in the `{amount}` field. All three stages use that field: reminder, second_notice, final_notice.
- **The bug is at `tally/reports/dunning.py:45`**: `fmt_money(account.past_due_cents, account.locale, account.currency)`. The signature is `fmt_money(cents, currency, locale=...)` (`money.py:76`), so the currency and locale arguments are swapped. Walking through `fmt_money` with currency=`"en_GB"` and locale=`"GBP"`:
  - `SYMBOLS.get("en_GB")` → `None`, so the prefix falls back to `"en_GB "` (`money.py:82-83`).
  - `SEPARATORS.get("GBP", en_US)` → `(",", ".")`.
  - The body is `312.40`, so the output is exactly `en_GB 312.40`, matching the screenshot.
- **The `{fee}` field on the next line (`dunning.py:46`) uses the correct order.** A second_notice letter would therefore show the wrong amount next to a correct fee.
- **Family sweep:** every other customer-facing `fmt_money` caller uses the order `(cents, currency, locale)`:
  - `notify.py:10,11,18`
  - `api/handlers.py:14,16,28,37`
  - `exports/pdf_export.py:19-25`
  - `exports/json_export.py:16-23`
  - `exports/csv_export.py:24-25`

  `dunning.py:45` is the only swapped call.
- **Out of scope, noted only:** `cli.py:21`, `reports/aging.py:28` and `reports/summary.py:10-18` omit the locale, so they always use en_US separators. They still render the currency symbol, so they don't cause this symptom, and they are internal reports rather than customer-facing ones.

### Files (fix surface)

- `tally/reports/dunning.py:45` — reorder to `fmt_money(account.past_due_cents, account.currency, account.locale)`. Using keyword args (`currency=`, `locale=`) would prevent this from happening again.
- `tests/test_dunning.py` (new) — a unit test that builds an `Account` (GBP / en_GB, `past_due_cents=31240`, `days_past_due=15` and `45`) and asserts `£312.40` appears in the letter and `en_GB` does not. For the second_notice stage, also assert the fee renders as `£35.00`.
- Provenance: the repo has one commit (`13559f7 tally 0.9.2`) and no import markers. Everything is local source.

### Doc Impact

None; confirmed unchanged after reading. `README.md:7` names dunning letters as a surface only. `docs/decisions.md` has no closed forks. No other open card overlaps: BUG-001 is about refund posting.

### Test Strategy: unit
