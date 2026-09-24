# BUG-002 — Customer-facing amount rendered with a locale code instead of a currency symbol

**Logged:** 2026-09-21 · **Source:** support ticket #4471 (cropped customer screenshot)
**Problem:** A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter). No other reports so far.
**Area:** `tally/` — money formatting and its customer-facing callers
**Prior:** GBP dropped out of `money.SYMBOLS` in the locale refactor, so `fmt_money` falls back to printing a code.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two positional args back into the `fmt_money(cents, currency, locale)` order, no judgment; closure: one call site in one module, no signature or contract change, no other consumer affected

### Repro (pinned)

"A UK customer (billing currency GBP, locale `en_GB`) sent a screenshot of an amount rendered as `en_GB 312.40` — it should read `£312.40`. The crop does not show which surface produced it (portal, statement PDF, email, letter)."

Code-level repro: `Account(..., currency="GBP", locale="en_GB", past_due_cents=31240, days_past_due>=15, closed=False)` → `dunning.letter(account)` contains `en_GB 312.40`.

### Root cause (verified)

`tally/money.py` SYMBOLS lost its GBP entry in the locale refactor, so fmt_money falls back to printing a code.
### Files (fix surface)

- `tally/reports/dunning.py:45`: change to `fmt_money(account.past_due_cents, account.currency, account.locale)`. Using keyword args (`currency=…, locale=…`) at `:45-46` would prevent the same swap from recurring.
- `tests/test_dunning.py` (new): regression test. A GBP/en_GB account with `past_due_cents=31240` and `days_past_due=15` must produce a `letter()` containing `£312.40` and not `en_GB`. Also cover a `second_notice` stage (days ≥ 45) so `{fee}` is exercised.
- Provenance: all touched paths are native to `tally/`. No import marker or manifest found, so this is a local edit.

### Doc Impact

None. README.md line 7 describes dunning letters generically, and `docs/decisions.md` has no closed forks. Confirmed unchanged after read. No open card overlaps this one (BUG-001 is about refund posting).

### Test Strategy: unit
