# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** (removed by triage)

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** systematic
**Probe-deps:** none
**Execution:** inline — depth: reorder two calls; closure: one method in one file

### Repro (pinned)

"`R-88120` was the last line of the batch file."

### Root cause (verified)

`tally/engine.py` `run()` calls `self._emit_period()` before the final `self._rollover(None)`. The trailing refund is still in `_held` when the period is emitted; `_rollover` then applies it to a fresh `_open` slot that is never emitted, and `_apply_refund` records it in the replay ledger, so the redelivery is skipped. `is_duplicate` is not the cause.

### Files (fix surface)

- tally/engine.py:84-85 — swap the order

### Doc Impact

none — confirmed unchanged after read

### Test Strategy: unit

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** systematic
**Probe-deps:** none
**Execution:** inline — depth: reorder two calls; closure: one method in one file

### Repro (pinned)

"`R-88120` was the last line of the batch file."

### Root cause (verified)

`tally/engine.py` `run()` calls `self._emit_period()` before the final `self._rollover(None)`. The trailing refund is still in `_held` when the period is emitted; `_rollover` then applies it to a fresh `_open` slot that is never emitted, and `_apply_refund` records it in the replay ledger, so the redelivery is skipped. `is_duplicate` is not the cause.

### Files (fix surface)

- tally/engine.py:84-85 — swap the order

### Doc Impact

none — confirmed unchanged after read

### Test Strategy: unit
