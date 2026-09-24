# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: a two-line reorder in `run()` that restores the order the `_rollover` docstring already states, with no judgment call · closure: `engine.py` plus one new test, with no consumer contract change (`run()` still returns `list[Statement]`)

### Repro (pinned)

"`R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly." / "the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

Unit form: `StatementEngine().run(Batch("b1", "2026-08", [ev("E1","charge",amt=1000), ev("E2","refund",amt=400,ref="E1")]))` → expected `closing_cents == 600`, and the output contains a `refund` line. Current code returns 1000 and no refund line.

### Root cause (verified)

The problem is the call order at `tally/engine.py:89-90`. `run()` calls `self._emit_period()` first and then `self._rollover(None)`.

1. `_on_refund` (`engine.py:135-143`) never posts a refund directly. It puts the refund in `self._held`, and the next `_rollover()` call settles it.
2. A refund in the middle of a batch gets settled by `_rollover(ev)` at `engine.py:81` when the next event arrives. It posts before the emit, which matches the "moved three lines up → posted" observation.
3. A refund that is the last event is still in `_held` when the loop ends. `_emit_period()` (`engine.py:356-363`) then does three things before the refund is settled:
   - appends every open statement to `_emitted`
   - writes `_balances[account] = closing_cents`, which leaves the balance 12.34 too high, as the card reports
   - resets `self._open = {}`
4. After that, `_rollover(None)` → `_apply_refund` (`engine.py:348-352`) calls `_statement()`, which creates a new orphan `Statement` in the already-cleared `_open`. The refund line goes on that orphan, which is never emitted, and the next `run()` wipes it at `engine.py:77`. The refund is on no statement.
5. The same `_apply_refund` call also runs `self._refunds.record(ev)` (`engine.py:352`). The replay ledger therefore marks `R-88120` as applied even though it was never posted. When the refund is re-sent as `R-88120-b` with the same (account, amount, posted_on) key, `is_duplicate` (`refunds.py:25-30`) correctly treats it as a replay of an applied refund. That produces the exact log line quoted in the card. The skip is a downstream effect of the false `record`, not a separate defect.

The `_rollover` docstring (`engine.py:332-333`: "once more after the loop with next_ev=None so the batch's trailing refund is settled") states the intended order, and lines 89-90 violate it. Fix: swap the two calls so `_rollover(None)` runs before `_emit_period()`. With `next_ev=None` there is no dispute to supersede the refund, so a trailing refund always posts. That is correct because a dispute can only supersede a refund when it immediately follows it in the same batch (`engine.py:136-140`).

- **Excluded prior:** the card's `Prior` blames the `is_duplicate` key shape. It is excluded as the root cause. The original `R-88120` was the first refund with its key, so `is_duplicate` returned False and the refund reached `_held`. Only the re-send was blocked, and only because of the false `record` described in step 5. Whether (account, amount, posted_on) is too broad as a replay key is a separate question that this evidence does not show. It is not part of this fix.
- **Family sweep:** `_rollover` and `_apply_refund` are the only code that writes statement state after the event loop, and refund is the only event kind that is deferred through `_held`. No other handler posts after `_emit_period`, so the fix covers the whole family.
- **Out of fix surface (ops, not code):** this fix does not correct data already affected. Account A-7731's August statement and balance, and the persisted `refund_store` entry for `R-88120`, have to be corrected separately. Any earlier batch that ended in a refund is affected the same way. The gateway should route this as its own remediation item.

### Files (fix surface)

- `tally/engine.py:89-90`: swap to `self._rollover(None)` and then `self._emit_period()`. This is the only code change. No file here is imported from another repo.
- `tests/test_engine.py`: add `test_refund_last_in_batch_posts`, which uses the unit repro above and asserts `closing_cents == 600` and that a `refund` line is present. Optionally assert that `e.balance("A1") == 600`, which checks that the carried balance includes the refund. Existing `test_refund_mid_batch_posts` and `test_refund_superseded_by_dispute` must still pass.
- Consumers (read only, unchanged): `tally/cli.py:19` and any other caller of `run()`. The return type and shape stay the same, and callers now get the trailing refund line as intended.

### Doc Impact

None. I read `README.md`, `docs/decisions.md` (no closed forks) and the `_on_refund` / `_rollover` comments in `engine.py`, and they already describe the intended behavior. No `docs/techstack.md`, so there are no probes. No overlapping open card: BUG-002 is about currency-symbol formatting and is unrelated.

### Test Strategy: unit
