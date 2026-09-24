# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two positional args back to the `fmt_money(cents, currency, locale)` contract; closure: one call site in one leaf module (`reports/dunning.py`), no signature or contract change, plus one new unit test.

### Repro (pinned)

"A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`."

Reproduces through `tally.reports.dunning.letter(account)` for an `Account` with `currency="GBP"`, `locale="en_GB"`, `past_due_cents=31240`, `days_past_due >= 15`, `closed=False`: the `{amount}` slot renders `en_GB 312.40`.

### Root cause (verified)

- **Prior falsified.** `GBP` is still in `SYMBOLS` — `tally/money.py:16` `"GBP": "£"` — and `tests/test_money.py:11` asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. `fmt_money` is correct for the correct call. Git history holds one commit (`13559f7 tally 0.9.2`), so it shows no "locale refactor".
- **Actual mechanism.** `tally/reports/dunning.py:45` passes the arguments in the wrong order: `fmt_money(account.past_due_cents, account.locale, account.currency)`. The contract at `tally/money.py:76` is `fmt_money(cents, currency, locale)`. For the reported account, `currency="en_GB"` and `locale="GBP"` go in:
  - `money.py:81` `SEPARATORS.get("GBP", …)` misses, so it falls back to en_US `(",", ".")`.
  - `money.py:82-83` `SYMBOLS.get("en_GB")` is `None`, so the prefix becomes `"en_GB "`, the unknown-code fallback.
  - `31240` becomes `"312.40"`, and the output is **`en_GB 312.40`**. That matches the screenshot exactly.
- **Surface.** Dunning letters. The module docstring at `dunning.py:1` says "customer-facing past-due notices, sent by email and post". `{amount}` appears in all three templates (`reminder`, `second_notice`, `final_notice`), so every stage is affected. `dunning.py:46` (`fee`) uses the correct order.
- **Scope is wider than the card suggests.** The swap hits every dunning letter, not only GBP/en_GB: a USD/en_US account renders `en_US 312.40`, and a de_DE account also loses its separators. The card's "No other reports" does not narrow the defect.
- **Family sweep.** Every other customer-facing `fmt_money` caller uses the correct `(cents, currency, locale)` order: `api/handlers.py:14,16,28,37`, `exports/csv_export.py:24-25`, `exports/json_export.py:16-23`, `exports/pdf_export.py:19-25`, `notify.py:10,11,18`. `cli.py:21`, `reports/aging.py:28`, and `reports/summary.py:10-18` omit locale (default en_US), but they are internal or ops output (`aging.py:1` "internal, finance", `summary.py:1` "internal") and cannot produce a locale-code prefix. So the defect is a single instance, and the fix covers the whole family.
- **Suggested fix.** At `dunning.py:45`, change the call to `fmt_money(account.past_due_cents, account.currency, account.locale)`. Keyword arguments (`currency=…, locale=…`) would guard against a repeat, which is the implementer's call.

### Files (fix surface)

- `tally/reports/dunning.py:45` — swap the argument order (the fix).
- `tests/` — new dunning test, e.g. `tests/test_dunning.py`. No dunning test exists today (only `test_engine.py` and `test_money.py`). All files are native to this repo, with no provenance markers, so no upstream route is needed.

### Doc Impact

None. Confirmed unchanged after reading: the `money.py` docstring already states the correct contract, and README.md describes dunning letters without format detail. `docs/decisions.md` has no closed forks, and there is no overlapping open card (BUG-001 concerns refunds).

### Test Strategy: unit

Build `Account(account_id="A1", name="X", email="", currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due=20)`. Assert that `letter(acct)` contains `£312.40` and does not contain `en_GB`. The test fails before the fix and passes after. Adding a de_DE/EUR case (e.g. `past_due_cents=123456` giving `€1.234,56`) also covers the separator half of the swap.
