# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: fix is a positional-argument swap back to the `fmt_money(cents, currency, locale)` contract, no judgment involved; closure: one call site in one leaf module (`tally/reports/dunning.py`), no consumer or signature change

### Repro (pinned)

> A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`.

Equivalent: `letter(Account(account_id=…, name=…, email=…, currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due=15))` → body contains `en_GB 312.40`.

### Root cause (verified)

The card's Prior is false. `tally/money.py:16` has `"GBP": "£"` in `SYMBOLS`, and `tests/test_money.py:11` asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. Excluded as a cause theory; the formatter is correct.

The defect is in `tally/reports/dunning.py:45`, the dunning letter `{amount}` field:
`fmt_money(account.past_due_cents, account.locale, account.currency)`. The locale and currency arguments are swapped relative to the `fmt_money(cents, currency, locale)` signature (`money.py:76`). As a result:
- `currency="en_GB"`: `SYMBOLS.get("en_GB")` is None, so `money.py:83` takes the unknown-code fallback, and the prefix becomes `"en_GB "`.
- `locale="GBP"`: it isn't in `SEPARATORS`, so `money.py:81` falls back to the `en_US` separators, which match en_GB (`,` `.`), so the digits look normal.
- Output: `en_GB 312.40`. That matches the screenshot character for character, and no other path produces a locale code as a prefix.

So the surface is the **dunning letter** (email and post, per the `dunning.py:1` docstring), specifically the `{amount}` placeholder in all three stages (reminder, second_notice, final_notice). The `{fee}` line (`dunning.py:46`) has the correct argument order.

Family sweep (every `fmt_money` call site): the other customer-facing callers pass `(cents, currency, locale)` in the right order: `notify.py:10,11,18`, `api/handlers.py:14,16,28,37`, `exports/pdf_export.py:19-25`, `exports/json_export.py:16-23`, `exports/csv_export.py:24,25`. `reports/summary.py`, `reports/aging.py`, and `cli.py` omit the locale and default to en_US separators. They are ops/internal outputs and can't produce a locale-code prefix, so they are outside this defect's family. The only instance is `dunning.py:45`.

Obvious fix: `dunning.py:45` becomes `fmt_money(account.past_due_cents, account.currency, account.locale)`. Keyword arguments (`currency=…, locale=…`) would also guard against this happening again.

### Files (fix surface)

- `tally/reports/dunning.py:45` — swap arguments back to (cents, currency, locale)
- `tests/test_dunning.py` (new) — failing repro: GBP/en_GB account, past-due 31240, 15 days → `letter()` contains `£312.40` and not `en_GB`
- Provenance: `tally/` is native to this repo. No import markers or manifest; the fix stays local.

### Doc Impact

none — confirmed unchanged after read. `README.md:7` names dunning letters as a customer-facing surface, which is still accurate. `docs/decisions.md` has no closed forks.

### Test Strategy: unit
