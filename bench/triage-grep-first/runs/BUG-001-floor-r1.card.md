# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two statements in `run()`, no judgment call; closure: one function in `tally/engine.py` plus one regression test, and no consumer contract changes (`run()` still returns the same `Statement` list).

### Repro (pinned)

> "`R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly."

> "the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

Unit shape: `StatementEngine().run(Batch(..., [charge E1 1000, refund E2 400 ref=E1]))`. The refund is the final event, and the output statement has no `refund` line (closing 1000, expected 600). Compare with the passing `test_refund_mid_batch_posts`, where the refund is followed by another event.

### Root cause (verified)

The cause is end-of-batch ordering in `StatementEngine.run()`, `tally/engine.py:89-90`:

```
self._emit_period()
self._rollover(None)
```

- `_on_refund` (engine.py:135-143) never posts directly. It parks every refund in `self._held`, which is settled by `_rollover()` when the next event arrives (engine.py:81), or by the trailing `_rollover(None)` when the batch ends.
- `_emit_period()` (engine.py:356-363) emits every open statement, writes `_balances`, then sets `self._open = {}`.
- The trailing refund is therefore settled **after** emission. `_apply_refund` → `_statement()` (engine.py:104-114) sees an empty `_open`, creates a new orphan `Statement`, and adds the refund line to it. That orphan is never emitted, never reaches `_balances`, and is discarded when the next `run()` resets `_open` (engine.py:77). This explains why the closing balance is 12.34 too high.
- `_apply_refund` still calls `self._refunds.record(ev)` (engine.py:352), so the ledger marks `R-88120` as applied even though it never posted.
- The same refund placed earlier in the batch is settled by the in-loop `_rollover(ev)` before emission, so it posts. This matches the staging replay.

**Prior assessed and rejected as the cause (dispatcher/card prior excluded from judgment):** `is_duplicate()` does not drop `R-88120`. The ledger could not have held a colliding key, because `R-88120` is only recorded when it is applied. The `R-88120-b` skip is a *downstream consequence*: the phantom `record()` above left key (A-7731, 1234, posted_on) → `R-88120` in the ledger, so the re-send is correctly identified as a replay of a refund the ledger wrongly believes posted. Keying replays on the refund's shape rather than its id is a deliberate choice documented at `refunds.py:21-22` (processors don't echo the id on redelivery). It is out of scope here.

**Fix:** swap the two lines so `_rollover(None)` runs before `_emit_period()`. The dispute-supersede check is unaffected: with `next_ev=None` there is no following dispute, so the trailing refund applies. This is the same result the current code intends, but it now lands in an emitted statement.

**Family sweep:** `_held` is the only deferred-settlement state in the engine. `_emit_period` and the trailing `_rollover` have no other call sites (grep: `engine.py:81,89,90` only). No sibling path produces statement lines after emission.

**Out of code scope (ops remediation, flagged):** the code fix does not repair already-persisted state. In the production `refund_store`, the key for `R-88120` still points at a refund that never posted, so re-sends stay blocked, and A-7731's August statement is still 12.34 high. Unblocking needs a `RefundLedger.forget()` on that entry or a manual adjustment. That is an ops/data action outside this fix.

### Files (fix surface)

- `tally/engine.py:89-90` — reorder: `self._rollover(None)` before `self._emit_period()`.
- `tally/engine.py:329-334` — the `_rollover` docstring ("once more after the loop") stays accurate; keep it or tighten it to "before emission".
- `tests/test_engine.py` — add a regression test: refund as the last event posts (closing 600), and its `event_id` appears among the emitted statement's lines. Optionally also assert that `e.balance("A1") == 600`.
- Provenance: no import markers or manifests. All touched files are local to this repo.

### Doc Impact

None; confirmed unchanged after reading. `README.md` describes `run()` only at the contract level (one `Statement` per account), and that contract is unchanged. `docs/decisions.md` has no closed forks, so nothing is re-walked. No overlapping open card: `BUG-002` is money formatting and does not overlap.

### Test Strategy: unit
