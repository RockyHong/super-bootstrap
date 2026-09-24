# BUG-001 — Refund missing from statement when it is the last event of the nightly batch

**Logged:** 2026-09-20 · **Source:** support escalation #4402 + nightly job log
**Problem:** Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly. The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement.
**Area:** `tally/` statement generation
**Prior:** `RefundLedger.is_duplicate()` is swallowing it — its replay key is (account, amount, posted_on) rather than the refund id, so the refund collides with an earlier one.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** inline — depth: swap two statement lines in `run()` so the end-of-batch settle happens before emit, no design judgment · closure: one function in `tally/engine.py` plus one regression test; `run()`'s return contract stays the same, and the only caller (`cli.py:19`) is unaffected.

### Repro (pinned)

> "Account A-7731's refund of 12.34 USD (event `R-88120`, reversing charge `C-88011`) was in the 2026-08 nightly batch but never appeared on the customer's August statement; the closing balance is 12.34 too high. `R-88120` was the last line of the batch file. Ops replayed the batch in staging with `R-88120` moved three lines up and the refund posted correctly."

> "The next night support re-sent the refund as `R-88120-b`; the job log shows `refund R-88120-b skipped as replay of R-88120`, and it is still on no statement."

Minimal unit shape: `StatementEngine().run(Batch("b1","2026-08",[charge E1 1000, refund E2 400 ref=E1]))` with the refund last → `out[0].closing_cents` should be 600. Under the current code it is 1000 and there is no refund line.

### Root cause (verified)

The card's Prior blames `RefundLedger.is_duplicate()`. That was excluded as a lead and tested against the code. It explains only the secondary symptom (the skipped `R-88120-b`), not the missing refund.

- `tally/engine.py:141-143` — `_on_refund` does not post a refund. It appends it to `self._held`, to be settled by the next `_rollover()`. This is by design, for the refund→dispute supersession check.
- `tally/engine.py:80-81` — inside the loop, every event calls `_rollover(ev)` first, so a refund with any event after it gets settled into the open statement. That is why moving `R-88120` up three lines made it post.
- **`tally/engine.py:89-90`** — after the loop, `run()` calls `self._emit_period()` **before** `self._rollover(None)`. Two effects:
  - `_emit_period()` (`:356-363`) has already written `self._balances`, appended the statements to `self._emitted`, and reset `self._open = {}`.
  - The trailing refund's `_rollover(None)` → `_apply_refund` (`:348-352`) → `_statement()` (`:103-113`) then creates a **new orphan Statement** in the now-empty `_open`. That statement is never emitted: the next `run()` resets `_open` at `:77`.

  Result: the refund is missing from every statement and `_balances` carries a closing balance 12.34 too high. This matches both reported symptoms. The `_rollover` docstring (`:332-333`) states the intent is for "the batch's trailing refund" to be settled, so the order of these two calls contradicts the code's own contract.
- Secondary symptom: `_apply_refund` still calls `self._refunds.record(ev)` (`:352`) on the orphaned refund. The ledger (keyed on `(account_id, amount_cents, posted_on)`, `refunds.py:22-25`, persisted across batches per the engine docstring `:4-5`) therefore marks `R-88120` as applied. A re-send with the same account, amount and posted_on is then rejected by `is_duplicate` (`refunds.py:27-31`, log text matches the card's job log verbatim). The shape-based key is documented intent (processor redelivery without echoed ids), not the defect. The defect is recording a refund that never posted. With the call order fixed, `record()` only fires for refunds that land on an emitted statement.
- Family sweep: `_held` is the only deferred-settle state in the engine. `_charges`, `_disputed` and `_fx` are applied synchronously, so no sibling path defers past emit. The fix scopes to this one instance.

Fix: in `run()`, call `self._rollover(None)` before `self._emit_period()`.

### Files (fix surface)

- `tally/engine.py:89-90` — swap the order: settle held refunds (`_rollover(None)`), then `_emit_period()`.
- `tests/test_engine.py` — add `test_refund_last_in_batch_posts` (charge then refund as the final event → refund line present and closing reduced). Optionally add a trailing-refund-then-next-batch check that `_balances` carries the refunded balance.
- No imported or vendored files: `tally/` and `tests/` are native to this repo, with no source-repo marker.

### Doc Impact

None — confirmed unchanged after reading. README.md describes `run()` at contract level only. `docs/decisions.md` has no rows, so no closed fork is re-walked. No other open card overlaps (BUG-002 is money formatting).

Out of the fix's scope, for ops (data, not code): account A-7731's live ledger store still holds the key for the orphaned `R-88120`, and its August statement and carried balance are already 12.34 high. The code fix does not repair that. Remediation (for example `RefundLedger.forget` on that key and re-posting, or a correcting `adjustment` event) is an operational call on production data and belongs outside the implement diff.

### Test Strategy: unit
