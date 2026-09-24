# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two positional args back to the `fmt_money(cents, currency, locale)` signature, no judgment; closure: one call site in one module, no signature or contract change, no other consumer affected.

### Repro (pinned)

> A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`.

Minimal repro: `dunning.letter(Account(..., currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due>=15))`. The body contains `en_GB 312.40`.

### Root cause (verified)

- **Prior falsified.** `tally/money.py:16` still maps `"GBP": "£"`, and `tests/test_money.py:11` pins `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. `SYMBOLS` is intact. `fmt_money` is correct when it gets its arguments in the right order.
- **Actual defect:** `tally/reports/dunning.py:45`, `amount=fmt_money(account.past_due_cents, account.locale, account.currency)`, passes locale and currency in swapped positions. The signature is `fmt_money(cents, currency, locale)` (money.py:76). The call above it at line 46 uses the correct order.
- **How the symptom follows:** with `currency="en_GB"` and `locale="GBP"`:
  - money.py:81 `SEPARATORS.get("GBP", …)` falls back to en_US `(",", ".")`, so the separators still look right and hide the swap.
  - money.py:82 `SYMBOLS.get("en_GB")` returns `None`, so line 83 falls back to `"en_GB "`.
  - The result is `"en_GB 312.40"`. That matches the screenshot exactly, including the space and the separators.
- **Surface:** the dunning letter, "customer-facing past-due notices, sent by email and post" (dunning.py:1). The `{amount}` slot appears in all three stages (`reminder`, `second_notice`, `final_notice`). The `{fee}` slot (line 46) renders correctly, so a `second_notice` shows `£35.00` next to `en_GB …`.
- **Family sweep:** every other `fmt_money` call that passes both currency and locale uses the correct order:
  - `notify.py:10,11,18`
  - `api/handlers.py:14,16,28,37`
  - `exports/csv_export.py:24-25`, `json_export.py:16-23`, `pdf_export.py:19-25`
  - `dunning.py:46`

  The callers that omit locale are internal ops outputs and render the currency symbol correctly, so they cannot produce the `{locale} ` prefix: `reports/aging.py:28`, `reports/summary.py:10-18`, `cli.py:21`. The defect is scoped to one instance.
- **Aim:** no overlapping open card (BUG-001 is the refund ledger). `docs/decisions.md` has no closed forks. The claim holds against HEAD `13559f7`.
- **Excluded prior:** the card's `Prior:` line was treated as a hypothesis and falsified above. It did not steer the fix route.

### Files (fix surface)

- `tally/reports/dunning.py:45`: reorder the arguments to `fmt_money(account.past_due_cents, account.currency, account.locale)`.
- `tests/test_dunning.py` (new): a failing repro. Use an en_GB/GBP account with `past_due_cents=31240` and `days_past_due=45`. Assert that `£312.40` and `£35.00` appear in the letter and that `en_GB` does not.
- Provenance: all files are native to this repo. No vendoring markers were found.

### Doc Impact

None. Confirmed after reading: `README.md:6-7` only lists dunning letters as a surface, and its wording is unaffected. `docs/decisions.md` needs no entry because the fix leaves a diff.

### Test Strategy: unit
