# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: change a key; closure: one file

### Repro (pinned)

"`R-88120` was the last line of the batch file."

### Root cause (verified)

`tally/refunds.py` `RefundLedger.key()` keys replays on (account, amount, posted_on), so `is_duplicate()` treats the trailing refund as a replay of an earlier same-shape refund and drops it.

### Files (fix surface)

- tally/refunds.py:22 — key on event id

### Doc Impact

none — confirmed unchanged after read

### Test Strategy: unit
