# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: a two-line call reorder in `run()` that restores the contract `_rollover`'s own docstring already states; closure: one method in `tally/engine.py` plus one regression test, and no signature or consumer contract changes.

### Repro (pinned)

From the card, verbatim:
- "`R-88120` was the last line of the batch file."
- "Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly."
- "the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

Minimal unit repro: `StatementEngine().run(Batch("b1", "2026-08", [ev("E1","charge",amt=1000), ev("E2","refund",amt=400,ref="E1")]))` → expected `closing_cents == 600`; the current code returns 1000 and has no refund line.

### Root cause (verified)

The bug is in `tally/engine.py:89-90`, `StatementEngine.run()`. The end-of-batch calls run in the wrong order:

```
self._emit_period()
self._rollover(None)
```

1. `_on_refund` (engine.py:143) never posts a refund immediately. It appends the refund to `_held`, and `_rollover()` settles it when the next event arrives (engine.py:81). A refund that is the last event has no next event, so only the post-loop `_rollover(None)` can settle it.
2. `_emit_period()` (engine.py:356-363) runs first. It snapshots `_open` into `_emitted` and sets `self._open = {}`.
3. `_rollover(None)` then calls `_apply_refund` (engine.py:348-352). Because `_open` is now empty, `_statement()` creates a new orphan `Statement`. The refund line goes onto that orphan, which is never added to `_emitted`, and `_balances` is never updated. `run()` returns `list(self._emitted)` without it, and the next `run()` resets `_open = {}` (engine.py:78), so the refund is gone for good. This explains why the August closing balance is 12.34 too high.
4. `_apply_refund` still calls `self._refunds.record(ev)` (engine.py:352). The persistent replay ledger therefore stores `(A-7731, 1234, posted_on) → R-88120` for a refund that never shipped.
5. The next night, `R-88120-b` has the same account, amount and posted_on. `is_duplicate` (refunds.py:25-30) matches that key with a different id and logs `refund R-88120-b skipped as replay of R-88120`. That is exactly the line in the card's job log. The re-send is lost because of the ghost record from step 4, not because the key is wrong.

The `_rollover` docstring (engine.py:332-333) states the intended contract: "once more after the loop with next_ev=None so the batch's trailing refund is settled". `run()` breaks it by settling the refund after the period has already been emitted. Moving the refund three lines up works because a following event triggers `_rollover(ev)` inside the loop, before emission. That matches the staging replay.

**Fix:** swap the two calls, so `self._rollover(None)` runs before `self._emit_period()`. Settling with `next_ev=None` cannot be superseded by a dispute, so the order swap changes nothing else.

**Prior excluded (dispatch/card bias input):** the card blames the `(account, amount, posted_on)` key. That is not the root cause. The key is deliberate: refunds.py:20-22 says "Processors do not always echo our refund id back on redelivery". Switching to the refund id would break redelivery protection, and it would still lose the original trailing refund. The collision is with the ghost record of `R-88120` itself, not with an earlier refund.

**Family sweep:** `_held` is the only deferred-posting path. `_rollover` is called only at engine.py:81 and engine.py:90, and every other handler posts directly into `_open` inside the loop. No sibling path writes after `_emit_period()`, so the verdict covers the whole family.

### Files (fix surface)

- `tally/engine.py:89-90`: swap the order to `self._rollover(None)` and then `self._emit_period()`.
- `tests/test_engine.py`: add `test_refund_last_in_batch_posts` (refund as the final event, expect closing 600 and a `refund` line). Also add a cross-batch case: the trailing refund posts, and a re-send with the same shape in the next batch is still skipped as a replay of a refund that actually posted.
- No consumer changes. `tally/cli.py:19` is the only `run()` caller and its contract is unchanged. `tally/refunds.py` needs no change.
- Provenance: all touched files are native to this repo. There are no import markers or manifest lines.
- **Out of code scope (ops remediation, not part of this fix):** production `refund_store` data already holds the ghost entry `(A-7731, 1234, posted_on) → R-88120`. Every trailing refund from past batches likely left the same kind of ghost. The code fix does not repair them. Ops needs to find the affected trailing refunds, clear them with `RefundLedger.forget()` or re-post them, and correct the affected statements. A-7731's August statement is the known case. That is an operational decision for whoever owns the job, and it does not change the code fix.

### Doc Impact

None. I read `README.md` and `docs/decisions.md` and confirmed neither needs to change: the README does not describe refund timing, and `decisions.md` has no closed fork on refund settlement or the replay key. The `_rollover` docstring already describes the corrected behavior.

### Test Strategy: unit
