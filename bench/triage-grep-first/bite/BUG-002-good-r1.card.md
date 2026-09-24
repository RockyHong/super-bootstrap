# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two positional args back into the `fmt_money(cents, currency, locale)` order, no judgment; closure: one call site in one module, no signature or contract change, no other consumer affected

### Repro (pinned)

"A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter)."

Code-level repro: `Account(..., currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due>=15, closed=False)` → `dunning.letter(account)` contains `en_GB 312.40`.

### Root cause (verified)

**Card's Prior is false.** `tally/money.py:16` still maps `"GBP": "£"`, and `tests/test_money.py:11` asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. `fmt_money` is correct.

**Surface: the dunning letter** (`tally/reports/dunning.py`, the past-due notice sent by email and post). At `tally/reports/dunning.py:45`:

```python
amount=fmt_money(account.past_due_cents, account.locale, account.currency),
```

The last two arguments are in the wrong order. The signature is `fmt_money(cents, currency, locale)` (`money.py:76`). With `locale="en_GB"`, `currency="GBP"`:
- `SYMBOLS.get("en_GB")` → `None`, so `prefix = "en_GB "` (`money.py:82-83`, the unknown-code fallback)
- `SEPARATORS.get("GBP", en_US)` → `(",", ".")` (`money.py:81`)
- result `"en_GB 312.40"`, which matches the screenshot exactly.

The next line (`:46`, `fee=`) uses the correct order, so the defect is limited to `{amount}`. `{amount}` appears in all three templates (`reminder`, `second_notice`, `final_notice`), so every dunning letter to every account has the bug. Non-GBP accounts show it too: each renders `{locale} {amount}` with en_US separators (e.g. a de_DE/EUR account gets `de_DE 1,234.56`). One report so far likely means few accounts are past due, not that the bug is narrow.

**Family sweep:** checked all other `fmt_money` callers that get the account locale, and all pass `(cents, currency, locale)` correctly: `api/handlers.py:14,16,28,37`, `notify.py:10,11,18`, `exports/pdf_export.py:19-25`, `exports/json_export.py:16-23`, `exports/csv_export.py:24,25`. Callers with no locale (`cli.py:21`, `reports/summary.py`, `reports/aging.py`) are internal ops output. They use the default locale, render the right symbol, and cannot produce `{locale} {amount}`, so they are out of scope.

### Files (fix surface)

- `tally/reports/dunning.py:45`: change to `fmt_money(account.past_due_cents, account.currency, account.locale)`. Using keyword args (`currency=…, locale=…`) at `:45-46` would prevent the same swap from recurring.
- `tests/test_dunning.py` (new): regression test. A GBP/en_GB account with `past_due_cents=31240` and `days_past_due=15` must produce a `letter()` containing `£312.40` and not `en_GB`. Also cover a `second_notice` stage (days ≥ 45) so `{fee}` is exercised.
- Provenance: all touched paths are native to `tally/`. No import marker or manifest found, so this is a local edit.

### Doc Impact

None. README.md line 7 describes dunning letters generically, and `docs/decisions.md` has no closed forks. Confirmed unchanged after read. No open card overlaps this one (BUG-001 is about refund posting).

### Test Strategy: unit
