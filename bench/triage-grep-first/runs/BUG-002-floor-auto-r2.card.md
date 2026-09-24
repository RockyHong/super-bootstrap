# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two positional args back to the signature order (no judgment); closure: one call site in one module, no contract/signature change, no doc drift

### Repro (pinned)

"A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`."

Reproduction: `tally.reports.dunning.letter(Account(..., currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due>=15))` → the letter body contains `en_GB 312.40`.

### Root cause (verified)

Prior falsified: `tally/money.py:16` carries `"GBP": "£"`, and `tests/test_money.py:11` asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. `fmt_money` is correct.

Producing surface: **dunning letters** (`tally/reports/dunning.py`, "customer-facing past-due notices, sent by email and post"). At `tally/reports/dunning.py:45`:

`amount=fmt_money(account.past_due_cents, account.locale, account.currency)`

The locale and currency are swapped against the signature `fmt_money(cents, currency, locale)` (`money.py:76`). With `currency="en_GB"`, `SYMBOLS.get` returns None, so the fallback at `money.py:83` builds the prefix `"en_GB "`. With `locale="GBP"`, the `SEPARATORS.get` at `money.py:81` falls back to en_US separators `(",", ".")`. The output is `en_GB 312.40`, which matches the screenshot character for character. The `{amount}` field appears in all three templates (reminder / second_notice / final_notice). Line 46 (`fee=`) has the correct order, so only the past-due amount is affected, and only in dunning letters.

Family sweep: every other `fmt_money` call passes `(cents, currency, locale)` in order: `api/handlers.py:14,16,28,37`, `exports/csv_export.py:24-25`, `exports/json_export.py:16-23`, `exports/pdf_export.py:19-25`, `notify.py:10,11,18`, `dunning.py:46`. Dunning is the only call that swaps them. Out of scope (different defect class, not this symptom): `cli.py:21`, `reports/aging.py:28` and `reports/summary.py:10-18` omit the locale, so they get en_US separators. Aging and summary are internal reports, so no customer sees them. The separators for en_GB match en_US anyway.

Aim: this is the only open card that overlaps (BUG-001 is about refund posting, not related). `docs/decisions.md` has no closed forks. The claim holds against HEAD `13559f7`.

### Files (fix surface)

- `tally/reports/dunning.py:45` — change the call to `fmt_money(account.past_due_cents, account.currency, account.locale)`. Optionally pass `currency=`/`locale=` as keywords, matching the style of `api/handlers.py:37`, so the order can't slip again.
- `tests/` — add a new `test_dunning.py` with a regression test: a GBP/en_GB account past due ≥15 days gets a letter containing `£312.40` and not containing `en_GB`. There is currently no dunning test.

All touched files are native to this repo, so no upstream route is involved.

### Doc Impact

none — confirmed unchanged after read (`README.md:6-7` lists dunning letters only as a surface; `money.py` docstring already states the correct signature).

### Test Strategy: unit
