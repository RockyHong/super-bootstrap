# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: one call site's positional-arg swap, no judgment; closure: one private function in a leaf module (`reports/dunning.py`), `fmt_money` signature and every other caller untouched.

### Repro (pinned)

"A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`."

Concrete repro: `letter(Account(account_id=…, name=…, email=…, currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due=15))` → body contains `en_GB 312.40`.

### Root cause (verified)

- **Prior falsified.** `tally/money.py:16` holds `"GBP": "£"`, and `tests/test_money.py:11` pins `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. `SYMBOLS` is intact, so the prior was excluded as a hypothesis.
- **Surface: dunning letters** (`tally/reports/dunning.py`, "customer-facing past-due notices, sent by email and post" per its docstring). This is the "letter" option in the card's list.
- **Mechanism.** `dunning.py:45` calls `fmt_money(account.past_due_cents, account.locale, account.currency)` with the locale and currency swapped against the signature `fmt_money(cents, currency, locale=...)` at `money.py:76`. With `locale="en_GB"`, `currency="GBP"`:
  - `money.py:82` `SYMBOLS.get("en_GB")` → `None` → `money.py:83` prefix = `"en_GB "`
  - `money.py:81` `SEPARATORS.get("GBP", en_US)` → `(",", ".")` → body `312.40`
  - result `"en_GB 312.40"`, which matches the screenshot character for character.
- The next line, `dunning.py:46` (`fee=`), passes the arguments in the correct order. The swap affects only the `{amount}` placeholder, which all three templates (reminder, second_notice, final_notice) contain.
- **Family sweep.** Every other `fmt_money` caller that passes an account locale uses the order `(cents, currency, locale)`: `notify.py:10,11,18`, `api/handlers.py:14,16,28,37`, `exports/json_export.py:16-23`, `exports/pdf_export.py:19-25`, `exports/csv_export.py:24-25`. `dunning.py:45` is the only swapped call site. `reports/summary.py`, `reports/aging.py` and `cli.py` omit locale and use the default, so they cannot produce a `<locale> ` prefix. They are also ops-internal, not customer-facing.
- **Impact beyond GBP.** Every non-`en_US` dunning letter is wrong. The prefix becomes the locale code, and separators fall back to en_US, because a currency code never keys `SEPARATORS`. Example: de_DE/EUR would render `de_DE 1,234.56`. `en_US` accounts also render `en_US 312.40`, so the bug reaches every dunning recipient, not only UK ones.
- Ad-hoc Python execution to confirm this was not granted. The trace is deterministic dict lookups and needs no runtime confirmation.

### Files (fix surface)

- `tally/reports/dunning.py:45` — swap to `fmt_money(account.past_due_cents, account.currency, account.locale)` so it matches line 46.
- `tests/test_dunning.py` (new) — failing repro: a GBP/en_GB account with `past_due_cents=31240, days_past_due=15` produces a letter that contains `£312.40` and does not contain `en_GB`. A second case (e.g. EUR/de_DE, `second_notice` stage) pins separators and `{fee}`.
- Provenance: `tally/` is native to this repo. There is no import marker or manifest, so the fix is a local edit.
- Aim: no overlapping open card (BUG-001 covers refund posting, which is unrelated), and `docs/decisions.md` has no closed forks.

### Doc Impact

none — confirmed unchanged after read (README.md:7 names dunning letters as a customer-facing surface; the fix preserves that; `docs/decisions.md` needs no row).

### Test Strategy: unit
