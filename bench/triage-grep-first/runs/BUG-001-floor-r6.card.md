# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two statements at the end of `run()`, no design call; closure: one method in `tally/engine.py` + one regression test, no signature, contract, or doc change.

### Repro (pinned)

> "`R-88120` was the last line of the batch file."
> "Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly."
> "The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

Minimal unit form: `run(Batch(..., [charge E1 1000, refund E2 400 ref=E1]))`. Expected closing 600, actual 1000.

### Root cause (verified)

The problem is the order of the last two calls in `StatementEngine.run()` (`tally/engine.py:89-90`):

```
self._emit_period()      # 89 — ships statements, then sets self._open = {} (line 363)
self._rollover(None)     # 90 — settles the trailing held refund *after* emission
```

- `_on_refund` (`engine.py:135-143`) never posts a refund directly. It puts the refund in `_held`, and `_rollover()` settles it when the next event is handled. When the refund is the last event, only the final `_rollover(None)` can settle it.
- That call runs after `_emit_period()` has already added the statements to `_emitted` and reset `_open`. `_apply_refund` (`engine.py:348-352`) then calls `_statement()`, which creates a new orphan `Statement` in the empty `_open`. `run()` never returns it, `_balances` never picks up its closing balance, and the next `run()` wipes it (`engine.py:77`). As a result, both the August closing balance and the next period's opening balance are 12.34 too high.
- A refund placed mid-batch is settled by the `_rollover(ev)` for the next event (`engine.py:81`) while its statement is still open. That explains why moving `R-88120` three lines up made it post, and why `test_refund_mid_batch_posts` passes.
- The docstring for `_rollover` (`engine.py:332-333`) says the after-loop call exists "so the batch's trailing refund is settled". The intent is clear and the code does the opposite, so there is no design decision to make.

**Card prior (tested, excluded as root cause).** `is_duplicate()` did not swallow `R-88120`. `R-88120` was dropped by the emit/rollover ordering above. The ledger is involved only in the second symptom: `_apply_refund` still calls `self._refunds.record(ev)` (line 352) on the orphaned post, so the persistent ledger records `R-88120` as applied even though it was never posted. The re-send `R-88120-b` has the same `(account, amount, posted_on)` key, and `is_duplicate` correctly treats it as a replay of `R-88120`. The shape-based key is deliberate (`refunds.py:21-22`: processors don't echo our id on redelivery). Changing it to the refund id would reopen the replay-protection hole and would not fix the batch-tail loss. `refunds.py` stays unchanged.

**Family sweep.** `_held` / `_rollover` is the only deferred-settlement path in the engine. Every other handler posts directly into `_open` during the loop. `_emit_period` has one caller (`run`), and `run` has one production caller (`cli.py:19`). The fix covers the whole family.

**Fix.** Swap lines 89 and 90 so `_rollover(None)` runs before `_emit_period()`. The trailing refund then lands on its open statement, gets emitted, and is carried into `_balances`. The dispute-supersede check is unaffected: with `next_ev=None` the refund posts, as the docstring intends.

**Out of scope for the code fix (ops remediation, for the dispatcher to route).** The persistent `refund_store` already holds `R-88120`'s key, so after the fix a fresh re-send is still skipped as a replay. Restoring A-7731's 12.34 USD needs a separate data or ops step, such as `RefundLedger.forget()` on `R-88120` followed by a re-post, or a manual adjustment. That is an operational call, not part of this code change.

### Files (fix surface)

- `tally/engine.py:89-90` — swap so `self._rollover(None)` runs before `self._emit_period()`.
- `tests/test_engine.py` — add `test_refund_last_in_batch_posts`: `[charge E1 1000, refund E2 400 ref=E1]` → one statement, closing 600, the refund line present, and `e.balance("A1") == 600`. Optionally also assert that a following batch's opening is 600.
- Consumers read-checked, no change: `tally/cli.py:19` (sole `run()` caller) and `tally/refunds.py` (the key stays as is). No file here is imported from another repo; there is no provenance marker.

### Doc Impact

None; confirmed unchanged after reading. `README.md` describes `run()` only at the "one Statement per account" level, which the fix makes true. The `_rollover` docstring already describes the corrected behavior. `docs/decisions.md` has no closed forks.

### Test Strategy: unit
