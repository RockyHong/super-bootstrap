# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: a two-line reorder in `run()` with no judgment (the `_rollover` docstring already states the intended order); closure: one method in `tally/engine.py` plus one unit test, no callers or signatures change.

### Repro (pinned)

> "Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

Minimal form: `StatementEngine().run(Batch(..., [charge E1 1000, refund E2 400 ref=E1]))` → expected closing 600; the current code returns 1000.

### Root cause (verified)

The end-of-batch steps in `StatementEngine.run()` run in the wrong order: `tally/engine.py:89-90` calls `self._emit_period()` **before** `self._rollover(None)`.

1. `_on_refund` (engine.py:135-143) never posts directly. It appends the refund to `self._held`, and `_rollover(next_ev)` settles it when the next event arrives (engine.py:81).
2. A refund on the batch's last line has no next event, so it is still in `_held` when the loop ends.
3. `_emit_period()` (engine.py:356-363) copies each statement into `_emitted`, sets `_balances`, and then clears `self._open = {}`.
4. Only then does `_rollover(None)` call `_apply_refund`, and `_statement()` (engine.py:104-114) creates a **new orphan Statement** in the now-empty `_open`. The refund line goes onto that orphan. It is never emitted, `_balances` never sees it, and the next `run()` discards it at engine.py:77. So the refund appears on no statement, and the account's closing balance and carried balance are both too high by the refund amount, matching the "12.34 too high" in the card.
5. `_apply_refund` still calls `self._refunds.record(ev)` (engine.py:352), so the ledger records `R-88120` as applied even though it never posted. When `R-88120-b` arrives with the same (account, amount, posted_on) key, `is_duplicate` (refunds.py:25-30) correctly reports it as a replay of what the ledger holds. The log line `refund R-88120-b skipped as replay of R-88120` is a downstream effect of step 4, not a separate defect.

The fix is to call `self._rollover(None)` before `self._emit_period()`. That matches `_rollover`'s own docstring (engine.py:332-333: "once more after the loop with next_ev=None so the batch's trailing refund is settled").

**The card's Prior is not the cause and was excluded as bias input.** The replay key (account, amount, posted_on) is deliberate (refunds.py:21-22). The ledger holds R-88120 only because of the orphan post, and moving the refund up three lines fixes posting without touching the key. That result points to where the refund sits in the batch, not to a key collision.

**Family sweep:** `_held` is the only deferred-settlement path in the engine. No other handler writes to a statement after `_emit_period`. The fix covers the whole family.

**Out of scope for the code fix (ops remediation, flag to the gateway):** the persisted `refund_store` still maps A-7731's (account, 1234, posted_on) key to `R-88120`, and August has already shipped. Reordering the code does not repair A-7731. It needs a `RefundLedger.forget` or a manual adjustment plus a corrected or next-period statement. That is an ops decision about restating a shipped statement, not part of this fix.

**Separate observation, not this card:** the (account, amount, posted_on) key would also block a genuinely distinct second refund with the same amount and date. That is a product/risk trade-off the refunds.py comment accepts on purpose. If someone wants it revisited, it should be its own card.

### Files (fix surface)

- `tally/engine.py:89-90`: swap to `self._rollover(None)` then `self._emit_period()`.
- `tests/test_engine.py`: add a trailing-refund test (charge then refund as the last event, assert closing = charge − refund and the refund line is present). Optionally add a second `run()` to assert the carried `opening_cents` reflects the refund.
- Provenance: no marker, manifest, or template suggests any touched file is imported from another repo, so all edits are local.

### Doc Impact

none. Confirmed unchanged after reading `README.md`, `docs/decisions.md` (no closed forks), and the `_rollover` docstring, which already describes the corrected behavior. No `docs/techstack.md` exists, so no `§ Probes` table applies.

### Test Strategy: unit
