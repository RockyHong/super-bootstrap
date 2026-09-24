# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two statements in `StatementEngine.run()`, no judgment call; closure: one file plus one new unit test, and the only consumer (`cli.py`) calls `run()` unchanged

### Repro (pinned)

"Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

Minimal unit form: `run(Batch(..., [charge E1 1000, refund E2 400 ref=E1]))` should close at 600. Current code closes at 1000.

### Root cause (verified)

The card's Prior blames the key shape of `is_duplicate()`. I set it aside as bias input and tested it against the code. It is **not the root cause**; it explains only the second-night symptom.

- `tally/engine.py:141-143`: `_on_refund` never posts a refund directly. It parks every refund in `self._held` for one step, so a dispute on the next event can supersede it.
- `tally/engine.py:81`: held refunds settle through `_rollover(ev)` at the start of the next event. A refund that has a following event settles before emit and posts. This matches the staging result with the refund moved three lines up.
- `tally/engine.py:89-90`: at batch end the order is `self._emit_period()` **then** `self._rollover(None)`. `_emit_period` (`:356-363`) emits the statements, writes `_balances`, and resets `self._open = {}`. Only after that does `_apply_refund` (`:348-352`) apply the trailing refund. It calls `_statement()`, which builds a fresh Statement in the now-empty `_open`. That Statement is never emitted, because the next `run()` resets `_open` at `:77`, and it never reaches `_balances`. So the refund is on no statement and the closing balance is 12.34 too high. The `_rollover` docstring (`:332-333`) states the intended behavior ("once more after the loop … so the batch's trailing refund is settled"); the call order contradicts it.
- Second-night symptom: even on this lost path, `_apply_refund` still calls `self._refunds.record(ev)` (`:352`), so the ledger marks `R-88120` as applied. `R-88120-b` has the same key `(account, amount, posted_on)` (`refunds.py:23`), so `is_duplicate` returns True (`refunds.py:27-29`) and logs exactly the line in the card. The ledger is working as designed: processors don't echo refund ids on redelivery (`refunds.py:21-22`). It is being fed a false "applied" record by the batch-end bug.

Fix: swap `engine.py:89-90` so `self._rollover(None)` runs before `self._emit_period()`. The trailing refund then lands in its real open statement before emit, and the ledger record becomes accurate. Disputes are unaffected: when `next_ev=None`, the supersede branch is already skipped.

Family sweep: `_rollover` and `_held` have no other callers. `_apply_refund` is the only deferred posting path; every other handler posts immediately. The bug has one instance.

Out of scope, noted for the gateway (not this card's aim):
- **Data remediation.** The production ledger store already holds a false "applied" record for `R-88120`, and A-7731's August statement and carried balance are 12.34 too high. The code fix does not repair either. That needs an ops step, e.g. `RefundLedger.forget` on `R-88120` plus a re-post or adjustment. This is an ops/business action, not an implement-phase edit.
- The replay key `(account, amount, posted_on)` would also treat two genuinely different refunds on one account, same day and same amount, as a replay. That is a separate latent issue for its own card, not part of this fix.

### Files (fix surface)

- `tally/engine.py:89-90`: reorder so `_rollover(None)` runs before `_emit_period()`.
- `tests/test_engine.py`: add `test_refund_last_in_batch_posts` (a charge, then a refund as the final event; the closing balance reflects the refund and the refund line is present). Add a follow-up assertion that a later-batch resend with a new id is skipped only after the original has actually posted.
- Provenance: all files belong to this repo. No import markers, so no upstream route.

### Doc Impact

none — confirmed unchanged after read. `README.md` describes the `run()` contract only in general terms. The `_rollover` docstring already states the correct behavior. `docs/decisions.md` has no closed forks.

### Test Strategy: unit
