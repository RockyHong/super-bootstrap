# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: the fix is fully determined (swap two calls in `run()`, no judgment needed); closure: one function in `tally/engine.py` plus one unit test, no API or contract change, and no doc describes the call order.

### Repro (pinned)

> "Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

Unit form: `StatementEngine().run(Batch(..., [charge E1 1000, refund E2 400 ref=E1]))` → refund line absent, `closing_cents == 1000` (expected 600).

### Root cause (verified)

`tally/engine.py:89-90`: `run()` calls `self._emit_period()` **before** `self._rollover(None)`.

- `_on_refund` (`engine.py:135-143`) never posts a refund directly. It parks every refund in `self._held` for one step, in case the next event is a dispute that supersedes it.
- Mid-batch, the next event's `_rollover(ev)` (`engine.py:81`) settles the held refund through `_apply_refund` **before** emit. That is why the staging replay posted correctly with `R-88120` moved up.
- A trailing refund is settled only by the `_rollover(None)` call after the loop. By then `_emit_period()` (`engine.py:356-363`) has already appended the statements to `_emitted`, written `_balances[account_id] = st.closing_cents` (the figure that is 12.34 too high), and reset `self._open = {}`. `_apply_refund` → `_statement()` (`engine.py:104-114`) then creates a **new orphan Statement** in `_open` and adds the refund line to it. Nothing ever emits that statement, and the next `run()` clears `_open` (`engine.py:77`). Result: the refund is on no statement and the balance stays too high.
- The same call path runs `self._refunds.record(ev)` (`engine.py:352`), so the ledger records `R-88120` as applied even though it never posted. The re-sent `R-88120-b` matches the key `(account_id, amount_cents, posted_on)` (`refunds.py:23`), and `is_duplicate` returns True with the log line quoted in the card (`refunds.py:28`). The second miss follows from the first.

**Prior excluded / falsified.** Card prior: "`RefundLedger.is_duplicate()` is swallowing it — replay key … collides with an earlier one." The staging replay rules this out as the root cause. `is_duplicate` runs when the refund is handled, and its key does not depend on the event's position in the batch, so moving the refund three lines up could not change its answer. Yet the refund then posted. `is_duplicate` explains only the `R-88120-b` skip, and there it works as designed: it matches a ledger entry left behind by the orphan apply. Keying on the refund's observable fields rather than its id is an intentional, documented choice (`refunds.py:21-22`) and is out of fix scope.

**Fix:** swap `engine.py:89-90` to `self._rollover(None)` then `self._emit_period()`. With `next_ev=None` the dispute-supersede check is skipped, so a trailing refund posts to the still-open statement, `_held` is empty before emit, and the ledger's `record` call only happens for a refund that actually posted.

**Family sweep:** `_rollover` is the only deferred-settle path. No other handler defers work past the loop (`_held` / `_rollover` / `_emit_period` appear only in engine.py). The fix scopes to this one instance.

### Files (fix surface)

- `tally/engine.py:89-90`: swap the order so held refunds settle before emit.
- `tally/engine.py:329-334`: the `_rollover` docstring ("once more after the loop … so the batch's trailing refund is settled") stays true; optionally add "before emit".
- `tests/test_engine.py`: add `test_refund_last_in_batch_posts` (charge 1000, then refund 400 as the last event → closing 600, refund line present, `e.balance("A1") == 600`).
- Consumers: `tally/cli.py:19` is the only `run()` caller and needs no change; the return contract is unchanged.
- Provenance: every touched file belongs to this repo (no import marker or manifest), so the fix lands here.

### Doc Impact

none — confirmed unchanged after read: `README.md` describes `run()` only at the contract level; `docs/decisions.md` has no closed forks, so nothing is re-walked; no overlapping open card (`BUG-002` is about money formatting).

**Outside code scope: ops remediation, not the implement phase's job.** Account A-7731's August statement and balance are still 12.34 too high. The production refund ledger also holds a phantom `R-88120` entry that will keep skipping any re-send with the same account, amount, and posted date. The code fix does not repair either one. After the fix ships, ops needs to act, for example: `RefundLedger.forget(R-88120)` on the persisted store and then re-post, or a manual adjustment. Route this to the account owner / ops. Earlier batches that ended in a refund have the same defect; auditing batch files whose last line is a refund would size the exposure.

### Test Strategy: unit
