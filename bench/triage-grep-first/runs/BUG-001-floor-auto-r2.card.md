# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two call lines in `StatementEngine.run()`, no judgment in the change; closure: one method plus one new unit test, no contract, signature or doc change.

### Repro (pinned)

> "`R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly."

> "the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

Unit form: `StatementEngine().run(Batch("b1", "2026-08", [charge E1 1000, refund E2 400 ref=E1]))`. The refund is the final event. Expected result: closing 600 with a `refund` line. Current code returns closing 1000 with no refund line.

### Root cause (verified)

The bug is in the order of the last two calls in `tally/engine.py:89-90` (`run()`):

```
self._emit_period()   # 89 — emits statements from self._open, then sets self._open = {}
self._rollover(None)  # 90 — settles the trailing held refund
```

- `_on_refund` (`engine.py:135-143`) never posts a refund directly. It appends the refund to `self._held`. `_rollover()` settles the held refund when the *next* event arrives. If the refund is the batch's last event, the only settlement is the `_rollover(None)` after the loop.
- That call runs after `_emit_period()` (`engine.py:356-363`), which has already emitted the statements and reset `self._open = {}`. `_rollover(None)` then calls `_apply_refund` (`engine.py:348-352`). `_statement()` (`engine.py:104-114`) creates a new Statement in the now-empty `_open`, and the refund line is added to it. That Statement is never returned, and `_balances` is never updated from it. The next `run()` sets `_open = {}` (`engine.py:77`), which discards it. So the refund is on no statement, and the closing balance is too high by exactly the refund amount. This matches "closing balance is 12.34 too high".
- Moving the refund earlier in the batch settles it at `engine.py:81` during the loop, before the emit. That is why the staging replay with `R-88120` three lines up posted correctly. `test_refund_mid_batch_posts` covers only this path. No test puts a refund last.
- **Secondary symptom (`R-88120-b` skipped):** `_apply_refund` calls `self._refunds.record(ev)` (`engine.py:352`) even when the line goes to the orphaned statement. The persisted ledger therefore marks `R-88120` as applied. The next night's re-send `R-88120-b` has the same `(account, amount, posted_on)` key (`refunds.py:23`), so `is_duplicate` (`refunds.py:25-30`) returns True and logs exactly the line in the card. The ledger behaves as designed; the lost post poisoned its input.
- **The card's Prior is rejected as root cause.** `is_duplicate` explains only the second, downstream symptom. It cannot explain the first loss: `R-88120` was the first delivery, and the staging replay posted it once it was moved. Changing the key to the refund id would also go against the documented design reason in `refunds.py:21-22` ("Processors do not always echo our refund id back on redelivery"). Leave the key unchanged.
- **Family sweep:** `_rollover(None)` is the only code that settles held state after the loop. `_emit_period` has one caller (`engine.py:89`). No other handler defers posting. The problem is limited to this one ordering.
- **Fix:** swap lines 89 and 90 so that `self._rollover(None)` runs before `self._emit_period()`. The docstring at `engine.py:332-333` ("once more after the loop with next_ev=None so the batch's trailing refund is settled") already describes this order. The code does not follow its own contract.
- **Ops follow-up (outside the code fix):** after the fix, the production ledger store still holds the `R-88120` key. A new re-send for A-7731 would still be skipped. The implementer's report must tell ops to call `RefundLedger.forget(R-88120)` for the affected key, or to post a manual adjustment, before re-sending. Other accounts whose refund was the last event of a past batch have the same problem. Ops can find them with a store key whose refund event_id appears on no emitted statement.

### Files (fix surface)

- `tally/engine.py:89-90`: swap to `self._rollover(None)` then `self._emit_period()`.
- `tests/test_engine.py`: add `test_refund_last_in_batch_posts` (charge 1000, refund 400 as the final event → closing 600, one `refund` line). Also add a two-batch case: after that run, a second `run()` opens with `opening_cents == 600`, proving `_balances` carried the refund.
- Provenance: `tally/` and `tests/` are this repo's own source. No import marker or manifest exists, and no serving repo is involved.
- Consumers, read and unchanged: `tally/cli.py:19` (`engine.run`), plus exports, reports and api, which render the emitted Statements. They receive the corrected statements without any change.

### Doc Impact

None. The following were read and confirmed unchanged: the `_rollover` docstring (`engine.py:329-334`) already states the intended order; `README.md`; `docs/decisions.md` (no closed forks); `refunds.py` module docstring. No open card overlaps: BUG-002 is currency-symbol formatting.

### Test Strategy: unit
