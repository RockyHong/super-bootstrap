# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two statements in `run()` so the end-of-batch refund settles before statements emit, no judgment; closure: one method in `engine.py` plus one regression test, no public contract or consumer change

### Repro (pinned)

> "`R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly."

> "the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

Minimal unit form: `run(Batch("b1", "2026-08", [charge E1 amt=1000, refund E2 amt=400 ref=E1]))` should give closing 600. Current code returns 1000 with no refund line.

### Root cause (verified)

The bug is an ordering fault in `StatementEngine.run()` (`tally/engine.py:89-90`). The card's Prior points at a different cause.

- `_on_refund` (`engine.py:141-143`) does not post a refund. It holds it in `_held`, and `_rollover(next_ev)` settles it at the start of the next event (`engine.py:81`).
- A trailing refund has no next event. It gets settled only by the post-loop `self._rollover(None)` at `engine.py:90`, which runs **after** `self._emit_period()` at `engine.py:89`.
- `_emit_period` (`engine.py:356-363`) copies every `_open` statement into `_emitted` and updates `_balances`, then resets `self._open = {}`.
- `_rollover(None)` then calls `_apply_refund` (`engine.py:348-352`). There `_statement()` finds no open slot, so it creates a **new orphan Statement** and adds the refund line to it. That orphan is never emitted. `run()` returns the `_emitted` list as it already stood, and the next `run()` wipes `_open` (`engine.py:77`). The result: the refund is on no statement, `_balances` keeps the pre-refund closing, and the August closing is 12.34 too high.
- `_apply_refund` still calls `self._refunds.record(ev)` (`engine.py:352`), so R-88120 is written to the replay ledger even though it never posted.

This ordering bug also explains the rest of the card's evidence:
- **The line depends on position.** When R-88120 sits mid-batch, the in-loop `_rollover(ev)` settles it while its statement is still open, so it posts. The existing `test_refund_mid_batch_posts` passes for the same reason. There is no trailing-refund test.
- **The log line is direct evidence.** `skipped as replay of R-88120` means `_seen[key] == "R-88120"` (`refunds.py:27-28`). The only writer of `_seen` is `record()`, which is called only from `_apply_refund`. So R-88120 was not dropped by `is_duplicate`. It went through `_apply_refund` onto a statement that was never emitted. The re-send R-88120-b then matched that phantom ledger entry.

**Prior excluded.** The card's hypothesis was that `is_duplicate()` with key (account, amount, posted_on) "collides with an earlier one". It does not explain why position matters, and the log line contradicts it: the colliding id is R-88120 itself, not an earlier refund. The shape-based key (`refunds.py:21-23`, documented rationale: processors do not always echo the refund id) only makes the second failure (the -b re-send) possible. It is a separate design choice and stays outside this fix.

**Family sweep.** `_held` is the only deferred state settled after the loop. Every other handler posts immediately. The dispute-supersede check in `_rollover` needs `next_ev`, which is `None` at the end of the batch either way, so moving `_rollover(None)` ahead of `_emit_period` changes no supersede outcome.

**Fix.** In `run()`, call `self._rollover(None)` before `self._emit_period()`.

**Out of code scope, for ops (not part of this fix).** The production refund store may still hold the phantom key for R-88120 (A-7731, 1234, posted_on). If that store persists across runs, the code fix alone will not post R-88120 or R-88120-b. Account A-7731 needs a separate ops step: correct the August statement and/or run `RefundLedger.forget`. From this repo it is not possible to see whether the store persists: `cli.py:18` builds `StatementEngine()` with an in-memory store.

### Files (fix surface)

- `tally/engine.py:89-90` — swap the order: `_rollover(None)` first, then `_emit_period()`
- `tests/test_engine.py` — add `test_refund_last_in_batch_posts`: a charge E1 of 1000 followed by a trailing refund E2 of 400 (ref E1). Assert: closing 600, a `refund` line is present, and `e.balance("A1") == 600`. The existing `test_refund_superseded_by_dispute` must stay green.
- Provenance: all touched files are native to this repo. There is no import marker and no source repo.

### Doc Impact

None. Confirmed unchanged after reading: the `_rollover` docstring ("once more after the loop with next_ev=None so the batch's trailing refund is settled") stays accurate after the swap, and `README.md` and the engine module docstring make no claim about ordering. There are no overlapping open cards (BUG-002 is about money formatting). `docs/decisions.md` has no closed forks.

### Test Strategy: unit
