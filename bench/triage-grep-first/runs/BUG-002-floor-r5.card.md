# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: fix one call site's argument order, no judgment involved. Closure: one line in one leaf module (`reports/dunning.py`, which nothing else in `tally/` imports) plus one new unit test.

### Repro (pinned)

> A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`.

Reproduce with an `Account(currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due>=15, closed=False)` passed to `tally.reports.dunning.letter()`. The `{amount}` field renders as `en_GB 312.40`.

### Root cause (verified)

- **The card's Prior is false.** `tally/money.py:16` still holds `"GBP": "£"`, and `tests/test_money.py:11` asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. `SYMBOLS` is intact. I kept the Prior out of the judgment and treated it as a hypothesis only.
- **The source is the dunning letter** (docstring: "customer-facing past-due notices, sent by email and post"). At `tally/reports/dunning.py:45`, `fmt_money(account.past_due_cents, account.locale, account.currency)` passes the arguments in the wrong order. The signature is `fmt_money(cents, currency, locale)` (`money.py:76`).
- **How the symptom follows** from `fmt_money(31240, "en_GB", "GBP")`:
  - `SEPARATORS.get("GBP", …)` misses and falls back to the en_US separators `,` and `.`.
  - `SYMBOLS.get("en_GB")` returns `None`, so the prefix becomes `"en_GB "` (`money.py:82-83`).
  - The body is `312.40`, so the output is exactly `en_GB 312.40`.
  - This also explains the card's "no other reports": the defect only shows for accounts past due by 15 days or more.
- **Family sweep:** I checked every `fmt_money` call site in the repo:
  - `dunning.py:46` (the `{fee}` line in the same function) is correct.
  - `notify.py:10,11,18`, `api/handlers.py:14,16,28,37`, `exports/pdf_export.py:19,21,23,25`, `exports/json_export.py:16,18,20,23` and `exports/csv_export.py:24,25` all pass `(cents, currency, locale)` in the right order.
  - `cli.py:21`, `reports/aging.py:28` and `reports/summary.py:10-18` omit `locale` and use the default. They are ops/internal output and cannot produce a `<locale> ` prefix.
  - `dunning.py:45` is the only swapped call.
- **Fix:** change line 45 to `fmt_money(account.past_due_cents, account.currency, account.locale)`. Keyword arguments (`currency=…, locale=…`) at this call site would also stop the swap from coming back.

### Files (fix surface)

- `tally/reports/dunning.py:45` — correct the argument order in the `amount=` formatting call. It affects all three stages: `reminder`, `second_notice` and `final_notice`.
- `tests/test_dunning.py` (new) — failing repro first. A GBP/`en_GB` account at 15 days past due or more should give a letter containing `£312.40` and no `en_GB `. Also assert that a `de_DE`/EUR account gets `€` with `de_DE` separators, which pins the locale half of the swap.
- Provenance: none of these files is imported from another repo (no marker, and no template elsewhere). `tally/` is native, so the fix lands here.

### Doc Impact

None. I read `README.md` (it only lists dunning letters as a renderer) and `docs/decisions.md` (it has no closed forks). Neither describes argument order. The card's Prior is superseded by this block; the card itself is left as written.

### Test Strategy: unit
