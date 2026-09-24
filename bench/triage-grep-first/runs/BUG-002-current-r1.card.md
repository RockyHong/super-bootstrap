# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: one call site has its positional args swapped, no judgment needed · closure: a single private call inside `dunning.letter()`, with no signature or contract change and no doc that restates it

### Repro (pinned)

"A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`."

Reduced to code: an `Account` with `currency="GBP"`, `locale="en_GB"`, `past_due_cents=31240`, `days_past_due >= 15`, `closed=False` → `tally.reports.dunning.letter(account)` → the body contains `en_GB 312.40`.

### Root cause (verified)

The card's Prior is falsified: `tally/money.py:16` still maps `"GBP": "£"`, and `tests/test_money.py:11` asserts `fmt_money(31240, "GBP", "en_GB") == "£312.40"`.

The actual mechanism is `tally/reports/dunning.py:45`:
`amount=fmt_money(account.past_due_cents, account.locale, account.currency)`. This swaps the 2nd and 3rd positional args against the signature `fmt_money(cents, currency, locale=DEFAULT_LOCALE)` (`money.py:76`). So:
- `currency="en_GB"` → `SYMBOLS.get("en_GB")` is None → the fallback prefix `f"{currency} "` gives `"en_GB "` (`money.py:82-83`)
- `locale="GBP"` → not in `SEPARATORS` → falls back to en_US `(",", ".")` (`money.py:81`) → `"312.40"`
- result: `"en_GB 312.40"`, which matches the ticket byte-for-byte.

Surface: dunning letters, the past-due `{amount}` field. The module docstring says these are "customer-facing past-due notices, sent by email and post", and all three stage templates (reminder / second_notice / final_notice) use `{amount}`. The `{fee}` field on line 46 uses the correct order, so a second_notice shows `£35.00` next to `en_GB …`.

Family sweep (every `fmt_money` caller grepped):
- Positional order is correct in `api/handlers.py:14,16,28,37`, `notify.py:10,11,18`, `exports/{csv,json,pdf}_export.py`, and `dunning.py:46`.
- `reports/aging.py:28`, `reports/summary.py:10-18` and `cli.py:21` omit locale. They still render the correct symbol, only with en_US separators, so they can't produce this symptom and sit outside this card.
- The defect is confined to line 45.

Blast scope: the swap affects every dunning letter whose currency is not already a key in `SEPARATORS`, which means every account. A USD/en_US account renders `en_US 1,234.56`; a de_DE/EUR account renders `de_DE 1,234.56`, with a code prefix and en_US separators. So this is not GBP-specific. The single report reflects which letters have been seen, not how far the bug reaches.

Optional hardening: making `locale` keyword-only would let a type check or call-time error catch this class of bug. That is a signature change across 20+ callers, so it is not part of this fix. Leave it to a separate DEBT card if wanted.

### Files (fix surface)

- `tally/reports/dunning.py:45` — swap to `fmt_money(account.past_due_cents, account.currency, account.locale)`
- `tests/test_dunning.py` (new) — failing repro first: GBP/en_GB account, stage reminder → body contains `£312.40` and not `en_GB`; add a de_DE/EUR case to pin separators (`€1.234,56`) and a second_notice case covering `{fee}`

Provenance: `tally/` is native to this repo. No import marker, manifest line or serving-repo template was found, so the fix lands here.

### Doc Impact

None. Read and confirmed unchanged: `README.md` lists dunning letters as a surface but carries no argument-order text, and `docs/decisions.md` has no rows.

### Test Strategy: unit
