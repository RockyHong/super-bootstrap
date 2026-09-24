# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two calls into the order the code's own docstring already states (no judgment); closure: one function in `tally/engine.py` + one regression test, no contract or consumer change

### Repro (pinned)

"`R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly."
"the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

### Root cause (verified)

`StatementEngine.run()` (`tally/engine.py:89-90`) calls `self._emit_period()` **before** `self._rollover(None)`:

- Every refund is parked in `self._held` by `_on_refund` (`engine.py:143`) and only posts when the *next* event triggers `_rollover` (`engine.py:81`). Mid-batch, the following event settles it into the open statement before emit — hence the staging replay posts correctly.
- For the trailing refund, no next event exists. `_emit_period()` (`engine.py:356-363`) emits the statements and resets `self._open = {}`. Only then does `_rollover(None)` → `_apply_refund` (`engine.py:348-352`) run: `_statement()` creates a **fresh** Statement in the now-empty `_open`, adds the refund line to it, and calls `self._refunds.record(ev)`. That orphan statement is never emitted (next `run()` resets `_open` at `engine.py:77`), and `_balances` was already set from the refund-less closing — closing balance 12.34 too high.
- `_rollover`'s own docstring (`engine.py:332-333`) states the intent: "once more after the loop with next_ev=None so the batch's trailing refund is settled" — the call order in `run()` defeats it.

Why `R-88120-b` was skipped: `_apply_refund` recorded `R-88120` in the persistent ledger even though its line was dropped, so the re-send's key `(account, amount, posted_on)` matched `R-88120` itself (`refunds.py:27-28`). The card's prior is ruled out as root cause — the collision is with the lost refund's own ledger entry, not "an earlier one"; the key shape is a documented choice (`refunds.py:21-22`) and plays no part in the first-night loss. Prior excluded from the judgment as dispatcher-side cause theory.

Fix: in `run()`, call `self._rollover(None)` before `self._emit_period()`. Dispute-supersede semantics unchanged (`next_ev=None` never matches a dispute).

Family sweep: `_held` is the only deferred-settlement state in the engine; no other handler writes to `_open` after emit. Scope is this one instance.

Out of code scope (ops remediation, not part of this fix): the production refund store still holds `(A-7731, 1234, posted_on) → R-88120`, so after the fix a re-send of the same refund will still be skipped as replay. Crediting A-7731's 12.34 needs an ops action (`RefundLedger.forget` on that entry then re-send, or a manual adjustment) and the already-shipped August statement needs a correction decision — both owner calls, route separately.

### Files (fix surface)

- `tally/engine.py:89-90` — swap order: `self._rollover(None)` then `self._emit_period()`
- `tests/test_engine.py` — add regression: batch `[charge E1 1000, refund E2 400 ref=E1]` (refund last) → one statement, closing 600, refund line present; plus a second `run()` asserting a trailing refund's ledger record corresponds to an emitted line

### Doc Impact

none — confirmed unchanged after read (`README.md` describes `run()` at contract level; `_rollover` docstring already states the correct intent; `docs/decisions.md` has no rows)

### Test Strategy: unit
