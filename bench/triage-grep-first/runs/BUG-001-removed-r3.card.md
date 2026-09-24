# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: a two-line call-order swap in `run()`, no judgment in the fix; closure: `tally/engine.py` + one regression test, no contract or consumer change.

### Repro (pinned)

> "`R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly."

> "The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

Unit repro: `StatementEngine().run(Batch("b1","2026-08",[ev("E1","charge",amt=1000), ev("E2","refund",amt=400,ref="E1")]))` → expected `closing_cents == 600`; current code returns 1000.

### Root cause (verified)

`tally/engine.py:89-90` — `run()` calls `self._emit_period()` **before** `self._rollover(None)`.

1. `_on_refund` (`engine.py:141-143`) never posts; it parks every refund in `self._held`, settled by `_rollover()` when the next event arrives (`engine.py:81`).
2. A refund that is the batch's last event has no next event, so it is still in `_held` when the loop ends.
3. `_emit_period()` (`engine.py:356-363`) emits the open statements, writes `_balances`, then sets `self._open = {}`.
4. `_rollover(None)` then runs `_apply_refund` (`engine.py:348-352`). `_statement()` finds no open slot, so it creates a **new orphan Statement** in the now-empty `_open`. The refund line goes on that orphan, which is never emitted, and the next `run()` wipes it (`engine.py:77`). The emitted statement and `_balances` are both missing the refund. That matches "closing balance is 12.34 too high".
5. `_apply_refund` still calls `self._refunds.record(ev)` (`engine.py:352`), so the ledger marks `R-88120` as applied even though it posted nowhere.

The re-send failure follows from step 5: `R-88120-b` has the same `(account, amount, posted_on)` key (`refunds.py:23`), and `is_duplicate` returns True because `_seen[k] == "R-88120" != "R-88120-b"` (`refunds.py:27-28`). That produces the exact logged line `refund R-88120-b skipped as replay of R-88120`.

**Card Prior, assessed:** the ledger does skip `R-88120-b`, but that skip is downstream. It does not explain `R-88120` itself going missing. That refund was never judged a duplicate: the same batch posts correctly when the refund is moved up (repro 1), and the ledger key does not depend on position in the batch. The key being shape-based rather than id-based is deliberate (`refunds.py:21-22`, processors do not echo ids back), and it is out of scope here. Latent side note, not this aim: two genuinely distinct refunds with the same account, amount and date would collide. If that matters, it should be a separate card.

**Family sweep:** `_held` is the only deferred-settlement state in the engine. No other handler defers work past the loop, and `_rollover` is the only post-loop flush. No siblings are affected.

### Files (fix surface)

- `tally/engine.py:89-90` — swap the two lines so `self._rollover(None)` runs before `self._emit_period()`. The trailing refund then lands on the live statement before emit, and `record()` only runs when the refund actually posts. The `_rollover` docstring (`engine.py:330-334`) already describes this intended order. No change needed there.
- `tests/test_engine.py` — add `test_refund_last_in_batch_posts`: charge 1000 followed by a trailing refund of 400 must give `closing_cents == 600`. Optionally also assert `e.balance("A1") == 600`, and that a second run with a different-id refund of the same shape is still skipped only after a real post.
- Consumers: `tally/cli.py:19` and the exports / reports / api layers only see `run()`'s return value. The fix makes that value correct and changes no interface. `tests/test_engine.py:28` (dispute supersession) keeps passing because supersession happens in the in-loop `_rollover(ev)`, not the post-loop call.
- Provenance: `tally/` is native to this repo. No import markers were found, so there is no upstream route.

**Out of code scope — ops remediation (flag to the gateway):** the production refund store already holds a record for `R-88120` under the key `(A-7731, 1234, posted_on)`, so account A-7731 stays short after the fix ships. Ops needs a separate step to clear that entry (`RefundLedger.forget`) and re-deliver, or to post a manual credit, and possibly to reissue the August statement. That is a customer / ops action, not part of this diff. The same stale-record state may exist on any account whose refund was the trailing event of a past batch.

### Doc Impact

none — confirmed unchanged after read (`README.md` describes `run()` at API level only; the `_rollover` and `_on_refund` comments already state the intended trailing-refund settlement; `docs/decisions.md` has no closed forks).

### Test Strategy: unit
