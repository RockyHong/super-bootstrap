# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two positional args at one call site to match the existing `fmt_money(cents, currency, locale)` signature; closure: one function in one file (`dunning.letter`), no signature or contract change, sibling callers verified correct.

### Repro (pinned)

> A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter).

Unit repro: `letter(account)` with `currency="GBP"`, `locale="en_GB"`, `past_due_cents=31240`, `days_past_due>=15` → body contains `en_GB 312.40`; expected `£312.40`.

### Root cause (verified)

- **Card prior is false.** `tally/money.py:16` has `"GBP": "£"` in `SYMBOLS`, and `tests/test_money.py:11` asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. `fmt_money` is correct.
- **Surface: dunning letters** (`tally/reports/dunning.py`: "customer-facing past-due notices, sent by email and post"). At `tally/reports/dunning.py:45`, `amount=fmt_money(account.past_due_cents, account.locale, account.currency)` passes locale and currency in swapped order. The signature is `fmt_money(cents, currency, locale=DEFAULT_LOCALE)` (`money.py:76`).
- What happens: `currency="en_GB"`, so `SYMBOLS.get("en_GB")` is `None` and the code-fallback prefix `"en_GB "` is used (`money.py:82-83`). `locale="GBP"` is missing from `SEPARATORS`, so the en_US separators `(",", ".")` apply (`money.py:81`). The result is `en_GB 312.40`, which exactly matches the screenshot, including the separators. The literal locale string in the output identifies this call site; a missing-symbol bug would print `GBP 312.40` instead.
- `{amount}` appears in all three letter stages (reminder / second_notice / final_notice). Line 46 (`fee`) on the next line has the correct order.
- **Family sweep:** every other `fmt_money` caller passes `(cents, currency[, locale])` in the right order: `notify.py:10,11,18`, `api/handlers.py:14,16,28,37`, `exports/json_export.py:16-23`, `exports/csv_export.py:24-25`, `exports/pdf_export.py:19-25`. `cli.py:21`, `reports/aging.py:28` and `reports/summary.py:10-18` leave out the locale on purpose and pass currency second. Separator choice on internal reports is out of scope for this card. So the defect is limited to `dunning.py:45`.
- **Aim:** no overlapping open card (BUG-001 covers refunds). `docs/decisions.md` has no closed forks. The claim still holds against current code.
- Excluded as bias input: the card's `Prior` (SYMBOLS regression). It was tested and falsified above.

### Files (fix surface)

- `tally/reports/dunning.py:45` — reorder to `fmt_money(account.past_due_cents, account.currency, account.locale)`. Keyword args (`currency=`, `locale=`) would guard against a repeat.
- `tests/test_dunning.py` (new) — failing repro: GBP/en_GB account at 15+ days past due; assert the `£312.40` amount and that no `en_GB` text appears in the output. Optionally cover a non-default-separator locale (for example EUR/de_DE) so the test also exercises the separators.
- Provenance: native `tally/` source, no marker saying it was imported from another repo. Edit it here.

### Doc Impact

none — confirmed unchanged after read (`README.md:7` lists dunning letters as a customer-facing surface. That stays true, and no documented behavior changes.)

### Test Strategy: unit
