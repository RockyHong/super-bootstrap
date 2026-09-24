# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: a two-statement reorder inside `StatementEngine.run()`, no judgment; closure: private to `run()`, no signature or return-shape change, sole caller `tally/cli.py:19` unaffected.

### Repro (pinned)

> "Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

Minimal unit shape: `run(Batch(..., [charge E1 amt=1000, refund E2 amt=400 ref=E1]))` → expect closing 600 with a `refund` line; today it returns closing 1000 with no refund line.

### Root cause (verified)

The card's Prior is refuted and was excluded from the judgment. `is_duplicate()` cannot explain the original loss. A key collision does not depend on where the event sits in the batch, yet the staging replay with `R-88120` moved up posted correctly. Also, no `refund R-88120 skipped as replay` line is reported; the only skip line in the log is for `R-88120-b`.

The real mechanism is an ordering bug at `tally/engine.py:89-90`:

- `_on_refund` (`engine.py:135-143`) does not post a refund. It puts it in `self._held`, and the refund is settled by `_rollover(next_ev)` before the next event is handled (`engine.py:81`). That wait supports the dispute-supersedes-refund rule.
- A refund that is the last event has no next event. It is settled by the trailing `self._rollover(None)` at `engine.py:90`.
- But `self._emit_period()` runs first, at `engine.py:89`. It snapshots `_open` into `_emitted`, writes `_balances`, and sets `self._open = {}` (`engine.py:356-363`).
- `_rollover(None)` then calls `_apply_refund` (`engine.py:348-352`). There, `_statement()` builds a new orphan `Statement` in the now-empty `_open` and adds the refund line to it. Nothing emits that statement, and the next `run()` wipes it with `self._open = {}` at `engine.py:77`. The refund lands on no statement, and the closing balance stays high by the refund amount. This matches "12.34 too high".
- `_apply_refund` still calls `self._refunds.record(ev)` (`engine.py:352`), so the ledger marks `R-88120` as applied even though it never posted.

The `R-88120-b` skip follows from that bad record. Its key `(account, amount, posted_on)` (`refunds.py:23`) matches the stored `R-88120` entry, so `is_duplicate` (`refunds.py:25-30`) does what it was built to do and skips a refund it believes was already applied. The ledger is the only thing wrong here, because its entry claims a posting that never happened.

**Fix:** swap `engine.py:89-90` so `self._rollover(None)` runs before `self._emit_period()`. The trailing refund then lands in the account's open statement before the snapshot, and `record()` only runs for a refund that actually posted.

Family sweep: `_held` is the only deferred-settlement path in the engine. `_rollover` is called only at `engine.py:81` and `engine.py:90`, and `_emit_period` only at `engine.py:89`. No other handler defers work past the loop, so the fix covers the whole family.

Out of scope, noted for the gateway:

1. **Production data remediation.** The persisted `refund_store` probably still maps A-7731's key to `R-88120`. After the fix ships, `R-88120` / `R-88120-b` still needs one reposting action from ops (for example `RefundLedger.forget` plus a re-send). This is an ops step, not part of this code change.
2. **Key design.** The `(account, amount, posted_on)` key would also merge two genuine same-day, same-amount refunds. The code comment at `refunds.py:21-22` says this is deliberate, and this bug does not depend on it. If anyone wants it revisited, it belongs on a separate card.

### Files (fix surface)

- `tally/engine.py:89-90` — swap order: `self._rollover(None)` before `self._emit_period()`
- `tests/test_engine.py` — add a failing repro: a refund as the last event posts (closing 600, `refund` line present). Add a second test: a follow-up batch carrying a resend with the same key and a new id is skipped only because the original actually posted.
- Provenance: all files are native to this repo (no import marker or manifest found), so the fix lands here.

### Doc Impact

None. The `_rollover` docstring (`engine.py:330-334`) and the `_on_refund` comment (`engine.py:136-140`) already describe the intended behavior ("once more after the loop … so the batch's trailing refund is settled") and stay accurate. `README.md` and `docs/decisions.md` (no closed forks) were read and need no change.

### Test Strategy: unit
