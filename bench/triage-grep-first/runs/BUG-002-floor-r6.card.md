# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two positional arguments back to the signature order that every other caller already uses (no judgment call); closure: one line in one leaf renderer, no signature or contract change, and no other consumer affected.

### Repro (pinned)

> A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter).

Traced repro: `dunning.letter(Account(..., currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due>=15))` → `{amount}` renders `en_GB 312.40`.

### Root cause (verified)

- **Surface:** dunning letters. `tally/reports/dunning.py:45` (sent by email and post, per the module docstring on line 1).
- **Mechanism:** the signature is `fmt_money(cents, currency, locale=DEFAULT_LOCALE)` (`tally/money.py:76`), but line 45 calls `fmt_money(account.past_due_cents, account.locale, account.currency)`, so currency and locale are swapped. `currency` becomes `"en_GB"`. `SYMBOLS.get("en_GB")` returns `None`, so `money.py:83` takes the unknown-code fallback, `f"{currency} "` → `"en_GB "`. `locale` becomes `"GBP"`, which is not in `SEPARATORS`, so the separators silently fall back to `en_US` (`,` / `.`). For en_GB those match, which is why the output looks like `en_GB 312.40` with nothing else visibly wrong. For a `de_DE`/EUR account the same bug would also produce the wrong separators (`de_DE 1,234.56`).
- **The card's Prior is falsified and was excluded from the judgment:** `money.py:16` holds `"GBP": "£"`, and `tests/test_money.py:11` asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. `fmt_money` itself is correct.
- **Blast within the letter:** the `{amount}` placeholder is wrong in all three templates (reminder, second_notice, final_notice). The `{fee}` on line 46 of the same call has the correct argument order.
- **Family sweep:** I checked every `fmt_money` call site. All other customer-facing callers pass `(cents, currency, locale)` correctly: `api/handlers.py:14,16,28,37`, `notify.py:10,11,18`, `exports/pdf_export.py:19,21,23,25`, `exports/json_export.py:16,18,20,23`, `exports/csv_export.py:24,25`. Line 45 of `dunning.py` is the only swapped call. `cli.py:21`, `reports/summary.py` and `reports/aging.py` omit locale (internal/ops output), so they cannot produce this symptom and are out of this card's scope.

### Files (fix surface)

- `tally/reports/dunning.py:45`: fix the argument order to `fmt_money(account.past_due_cents, account.currency, account.locale)`. Keyword arguments (`currency=..., locale=...`) would harden the call against the same swap.
- `tests/test_dunning.py` (new): a failing-first unit test. It builds an en_GB/GBP account with `past_due_cents=31240, days_past_due=15`, asserts `"£312.40"` appears in `letter(account)`, and asserts `"en_GB"` does not. Optionally add a de_DE/EUR case to pin the separators (`"€1.234,56"`).
- Provenance: all files are native to this repo, with no import marker or template source.

### Doc Impact

none. I read `README.md` (it lists dunning letters as a surface but says nothing about argument order or formatting) and `docs/decisions.md` (no closed forks). Neither changes.

### Test Strategy: unit
