# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swapped positional args restored to the `fmt_money(cents, currency, locale)` contract, no judgment; closure: one call site, no in-repo consumers of `dunning.letters()`, no doc change

### Repro (pinned)

> A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`.

Surface: dunning letter (`tally/reports/dunning.py`, "sent by email and post"), `{amount}` field — present in all three stage templates (`reminder`, `second_notice`, `final_notice`).

### Root cause (verified)

Card Prior is **falsified** — `tally/money.py:16` holds `"GBP": "£"`; `tests/test_money.py:11` asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`. `fmt_money` is correct.

Defect: `tally/reports/dunning.py:45` calls `fmt_money(account.past_due_cents, account.locale, account.currency)` — args 2 and 3 swapped against the signature `fmt_money(cents, currency, locale)` (`money.py:76`). Trace with `past_due_cents=31240, locale="en_GB", currency="GBP"`:
- `SEPARATORS.get("GBP", …)` → miss → en_US `(",", ".")` (`money.py:81`)
- `SYMBOLS.get("en_GB")` → `None` → prefix `"en_GB "` (`money.py:82-83`)
- body `"312.40"` → returns `"en_GB 312.40"` — byte-exact match to the screenshot.

Adjacent `fee=` line (`dunning.py:46`) uses the correct order — a `second_notice` letter shows a correct `£35.00` fee beside the broken amount.

Family sweep (every `fmt_money` caller): `notify.py:10,11,18`, `api/handlers.py:14,16,28,37`, `exports/pdf_export.py:19-25`, `exports/json_export.py:16-23`, `exports/csv_export.py:24-25` all pass `(cents, currency, locale)` in order — clean. `cli.py:21`, `reports/aging.py:28`, `reports/summary.py:10-18` omit locale (default `en_US` separators) — internal/ops output, not this symptom class; out of scope. Only instance of the swap: `dunning.py:45`.

Reach: every dunning letter for every account renders `{locale} {amount}` with en_US separators (US account → `en_US 312.40`; de_DE/EUR account → `de_DE 1,234.56`), not only GBP. "No other reports" does not narrow the mechanism.

Fix: `fmt_money(account.past_due_cents, account.currency, account.locale)` — keyword args (`currency=…, locale=…`) on lines 45-46 harden against recurrence.

### Files (fix surface)

- `tally/reports/dunning.py:45` — swap args to `(cents, currency, locale)`
- `tally/reports/dunning.py:46` — optional: same keyword-arg form for consistency
- `tests/test_dunning.py` (new) — failing repro: `letter(Account("A1", "Jo", "j@x", currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due=20))` contains `£312.40` and not `en_GB`; plus a `second_notice` case (days ≥ 45) asserting amount and fee both symbol-prefixed

Provenance: all files native to this repo — no import marker / manifest; no upstream route.

### Doc Impact

none — confirmed unchanged after read: `README.md:7` names dunning letters only as a customer-facing surface; `docs/decisions.md` holds no closed forks; no overlapping open card (`BUG-001` = unrelated refund ledger).

### Test Strategy: unit
