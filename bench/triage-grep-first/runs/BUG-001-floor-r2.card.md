# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two call statements in `run()`, a deterministic reorder with no design call · closure: one private method body in `tally/engine.py` plus one new unit test; no signature, contract, or consumer change.

### Repro (pinned)

"`R-88120` was the last line of the batch file." · "Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly." · "The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

Unit form: `StatementEngine().run(Batch("b1", "2026-08", [ev("E1","charge",amt=1000), ev("E2","refund",amt=400,ref="E1")]))`. Expected closing 600 with a refund line. Actual, by code read: closing 1000 and no refund line. This mirrors `tests/test_engine.py:19` `test_refund_mid_batch_posts` with the trailing charge removed.

### Root cause (verified)

- `tally/engine.py:141-143` `_on_refund`: every accepted refund is appended to `self._held`. It posts only when the next `_rollover()` call settles it.
- `tally/engine.py:80-81`: for a refund that is not last, the next loop iteration calls `_rollover(ev)` → `_apply_refund` → `_statement()`. The refund line lands in a statement in `self._open`, which is emitted later. This is why the refund posts when it is moved up.
- `tally/engine.py:89-90`: after the loop, `run()` calls `self._emit_period()` **before** `self._rollover(None)`. `_emit_period` (`:356-363`) copies `self._open` into `self._emitted`, writes `self._balances`, and resets `self._open = {}`. Then `_rollover(None)` settles the trailing refund. `_apply_refund` (`:348-352`) calls `_statement()`, which creates a **fresh** Statement in the now-empty `self._open` (`:104-114`) and adds the refund line there. That Statement is never emitted: `run()` returns the `_emitted` list built earlier, and the next `run()` clears `self._open` at `:77`. So the refund is on no statement and `_balances` keeps the pre-refund closing. This matches the card: "closing balance is 12.34 too high".
- The same `_apply_refund` also calls `self._refunds.record(ev)` (`:352`). The replay ledger now marks `R-88120` as applied even though it never posted. The re-sent `R-88120-b` has the same `(account, amount, posted_on)` key, so `is_duplicate` (`tally/refunds.py:25-30`) correctly reports it as a replay of `R-88120`. That explains the second symptom.
- **Prior excluded:** the card's `is_duplicate` hypothesis explains only the `R-88120-b` skip, and that skip follows from the poisoned ledger entry. It cannot explain why the original `R-88120` failed to post: no earlier refund held that key, since only `record()` writes the ledger and `record()` runs only from `_apply_refund`. It also cannot explain why position in the batch matters. The shape-based key is a deliberate choice (`tally/refunds.py:21-22`, processors do not echo the refund id back), not this defect.
- Family sweep: `_rollover(None)` at `:90` is the only settle-after-emit path. `_held` is the only deferred-posting buffer, and every other handler posts synchronously into `_open` before `:89`. Scope is one instance.
- Fix: swap `:89` and `:90`, so `_rollover(None)` runs before `_emit_period()`. `_held` is then always empty when `_emit_period` runs.

### Files (fix surface)

- `tally/engine.py:89-90` — swap the order so `self._rollover(None)` precedes `self._emit_period()`.
- `tests/test_engine.py` — add `test_refund_last_in_batch_posts`: a batch ending in a refund asserts the refund line is present and `closing_cents` is correct. Optionally also assert that a second `run()` with a same-shape refund under a new id is not blocked by a phantom ledger entry.
- Provenance: `tally/` and `tests/` are native to this repo. No import marker was found, and the README describes this as the tally project itself.
- Consumers: `tally/cli.py:19` and every export/report consumes the output of `run()` and is unchanged. The fix only makes that output correct.
- Out of code scope (ops remediation for the gateway to route): account A-7731's production `refund_store` still maps `(A-7731, 1234, posted_on)` → `R-88120`, although that refund never posted. After the fix ships, re-sending the refund will still be skipped as a replay unless that entry is cleared first (`RefundLedger.forget`) or the refund is re-issued another way. Other accounts whose refund was the last event of a past batch are affected the same way. Finding them requires a scan of past batch files and ledger data, which is an ops task that needs production authority.

### Doc Impact

None. Confirmed after reading: the `README.md` run description and the `run()`/`_rollover` docstrings (`engine.py:74-75`, `:329-334`) already describe the intended behavior ("once more after the loop … so the batch's trailing refund is settled"). The code, not the prose, is wrong. `docs/decisions.md` has no closed forks. `BUG-002` (money formatting) does not overlap.

### Test Strategy: unit
