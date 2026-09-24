# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** systematic
**Probe-deps:** none
**Execution:** inline — depth: swap two calls so they match the order `_rollover`'s own docstring already specifies, no design call · closure: one method in `tally/engine.py` plus one regression test, no contract or consumer change

### Repro (pinned)

> Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.

Unit repro: `StatementEngine().run(Batch("b1","2026-08",[ev("E1","charge",amt=1000), ev("E2","refund",amt=400,ref="E1")]))` → expected `out[0].closing_cents == 600`. Current code returns 1000, and the ledger still records E2 as applied.

### Root cause (verified)

`tally/engine.py:89-90`: `run()` calls `self._emit_period()` **before** `self._rollover(None)`.

- `_on_refund` (`engine.py:135-143`) never posts a refund on the spot. It appends the refund to `self._held`, and the refund only posts when `_rollover()` runs before the *next* event. A refund that is the last event has no next event, so it is still sitting in `_held` when the loop ends.
- `_emit_period()` (`engine.py:356-363`) snapshots `_open` into `_emitted`, writes `_balances[account] = st.closing_cents`, and then **resets `self._open = {}`**.
- Then `_rollover(None)` → `_apply_refund` (`engine.py:348-352`) → `_statement()` finds `_open` empty, builds a **new orphan Statement**, and adds the refund line to it. Nothing ever emits that orphan: `run()` returns `list(self._emitted)`, and the next `run()` wipes `_open` at line 77. `_balances` was already written without the refund. That explains the refund missing from every statement and the closing balance being 12.34 too high.
- `_apply_refund` still calls `self._refunds.record(ev)` (line 352), so the persisted replay ledger marks R-88120 as applied even though it never posted. That explains the second-night symptom: `R-88120-b` has the same `(account, amount, posted_on)` key and `RefundLedger.is_duplicate` (`refunds.py:25-30`) skips it. The ledger is doing its job correctly; the record it reads from is wrong.
- The "moved three lines up posts correctly" observation follows directly: a non-final refund gets settled by `_rollover(next_ev)` at line 81 while `_open` is still live.

The code's own contract says so: the `_rollover` docstring (`engine.py:332-333`) says it is called "once more after the loop with next_ev=None so the batch's trailing refund is settled", and the `_on_refund` comment (line 140) says "or end of batch". The trailing refund is supposed to be settled into the period's statements, and the call order breaks that.

**Card's Prior not adopted.** I did not use it as evidence. The replay-key shape `(account, amount, posted_on)` is a deliberate choice (`refunds.py:21-22`: processors don't echo our id on redelivery), and it only explains the downstream skip of `R-88120-b`, not the original loss. Changing the key would not make R-88120 post.

**Fix:** swap lines 89-90 so `self._rollover(None)` runs before `self._emit_period()`.

**Family sweep:** `_held` is the only deferred-settlement buffer in the engine. Every other handler writes to `_open` synchronously inside the loop. No other path writes after `_emit_period`. The defect is limited to trailing refunds, for any account, any batch.

### Files (fix surface)

- `tally/engine.py:89-90` — reorder: `self._rollover(None)` before `self._emit_period()`.
- `tests/test_engine.py` — add regression `test_refund_last_in_batch_posts` (charge then trailing refund → closing reflects the refund and a `refund` line is present). Optionally also add a two-batch case: trailing refund in b1, same-shape refund with a new id in b2 → skipped as a replay, and b1's statement carries the refund, which proves the ledger record now matches a posted line.
- Provenance: all files are native to this repo; I found no import marker or manifest.
- Consumers: `tally/cli.py:19` and README-described exports/reports only consume `run()`'s return value. The signature and return shape are unchanged, so no consumer edit is needed.

**Out of the code fix — ops follow-up for the gateway to route:** production data for A-7731 stays wrong after the code lands. The persisted refund store (outside this repo; `cli.py` builds a store-less engine) holds a false `R-88120` record, the August statement and carried balance lack the 12.34 credit, and `R-88120-b` was skipped. Fixing that means removing the stale ledger entry (`RefundLedger.forget`) and reposting or reissuing the statement. That is an operational decision, not part of this diff. Other accounts whose refund was the final line of any past batch are affected the same way, so a sweep of past batch files' last lines would size the damage.

### Doc Impact

none — confirmed unchanged after read (`README.md` describes `run()` at a level the fix doesn't alter; `_rollover` docstring already states the corrected behavior; `docs/decisions.md` has no closed forks).

### Test Strategy: unit
