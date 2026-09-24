# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swapping two positional arguments back into order, with no judgment involved; closure: one call site in one leaf module, no signature change, no other consumers affected, no docs to update.

### Repro (pinned)

> A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter).

This reproduces as a unit test: an `Account(currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due>=15, closed=False)` passed to `tally.reports.dunning.letter()` gives a body containing `en_GB 312.40`.

### Root cause (verified)

**The card's Prior is false.** `GBP` is still in `money.SYMBOLS` (`tally/money.py:16`, `"GBP": "£"`), and the existing test `tests/test_money.py:11` asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. `fmt_money` is correct.

**The defect is at the call site.** `tally/reports/dunning.py:45` passes the arguments in the wrong order:
`amount=fmt_money(account.past_due_cents, account.locale, account.currency)`. The signature is `fmt_money(cents, currency, locale)` (`money.py:76`). Tracing `fmt_money(31240, "en_GB", "GBP")`:
- `money.py:81`: `SEPARATORS.get("GBP", …)` misses and falls back to en_US `(",", ".")`, so the separators look normal.
- `money.py:82-83`: `SYMBOLS.get("en_GB")` returns `None`, so the prefix falls back to `f"{currency} "`, which is `"en_GB "`.
- `money.py:86-90`: `"en_GB"` is not in `ZERO_DECIMAL`, so the body is `"312.40"`.
- The result is `en_GB 312.40`, exactly what the customer saw.

**Surface:** dunning letters ("customer-facing past-due notices, sent by email and post", `dunning.py:1`). The `{amount}` placeholder appears in all three stage templates (reminder, second_notice, final_notice). The `fee` line on `dunning.py:46` has the correct order, which is why only the amount is wrong.

**Family sweep.** Every other `fmt_money` call site passes `(cents, currency, locale)` in the right order or omits locale: `notify.py:10,11,18`, `api/handlers.py:14,16,28,37` (`:37` uses `locale=` as a keyword), `exports/json_export.py:16-23`, `exports/csv_export.py:24-25`, `exports/pdf_export.py:19-25`, `reports/summary.py:10-18`, `reports/aging.py:28`, `cli.py:21`. None of them can put a locale in the currency slot, so the defect is limited to `dunning.py:45`. The callers that omit locale (summary, aging (internal finance), cli) only default to en_US separators. That is a different class of issue from this one and is not claimed here.

**Aim:** the claim is still valid against HEAD `13559f7`. No overlapping open card (BUG-001 is about refund posting and is unrelated). `docs/decisions.md` has no closed forks. The fix is a one-line argument swap.

### Files (fix surface)

- `tally/reports/dunning.py:45` — reorder to `fmt_money(account.past_due_cents, account.currency, account.locale)`. Keyword arguments (`currency=…, locale=…`) would also guard against another swap. Either way no change is needed outside this file.
- `tests/test_dunning.py` (new) — failing repro test: a GBP / `en_GB` account with `past_due_cents=31240`. Assert that `letter()` contains `£312.40` and does not contain `en_GB`. Optionally parametrize over the three stages (days 15 / 45 / 75).
- Provenance: all files are native to this repo; no copy markers or serving-repo templates were found.

### Doc Impact

None; confirmed after reading `README.md`, `docs/decisions.md` and `docs/work/README.md`. No doc describes dunning argument order or the Prior's `SYMBOLS` theory.

### Test Strategy: unit
