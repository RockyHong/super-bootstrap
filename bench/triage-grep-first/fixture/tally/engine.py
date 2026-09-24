"""StatementEngine — turns a nightly Batch of events into per-account Statements.

One engine instance lives for the lifetime of the nightly job and is fed one
batch per period. Each run() builds the period's statements from scratch; the
cross-batch state it keeps is the refund replay ledger and the FX table.
"""

import logging
from dataclasses import dataclass, field

from .money import Money
from .refunds import RefundLedger

log = logging.getLogger(__name__)

INTEREST_CAP_BPS = 2500        # 25.00% APR ceiling, regulatory
LATE_FEE_CENTS = 3500
DISPUTE_HOLD_DAYS = 45


@dataclass
class Line:
    event_id: str
    kind: str
    amount_cents: int
    memo: str = ""


@dataclass
class Statement:
    account_id: str
    period: str
    currency: str
    lines: list = field(default_factory=list)
    opening_cents: int = 0
    notes: list = field(default_factory=list)

    @property
    def closing_cents(self):
        return self.opening_cents + sum(l.amount_cents for l in self.lines)

    def add(self, ev, amount_cents, memo=""):
        self.lines.append(Line(ev.event_id, ev.kind, amount_cents, memo or ev.memo))

    def total(self, kind):
        return sum(l.amount_cents for l in self.lines if l.kind == kind)


class StatementEngine:
    def __init__(self, balances=None, refund_store=None, fx=None):
        # account_id -> closing balance carried from the previous period
        self._balances = balances if balances is not None else {}
        self._refunds = RefundLedger(refund_store)
        self._fx = dict(fx or {})              # (from, to) -> rate as float
        self._open = {}                        # account_id -> Statement being built
        self._held = []                        # refunds waiting one step (see _on_refund)
        self._charges = {}                     # event_id -> charge Event, this batch
        self._disputed = set()                 # charge event_ids under dispute
        self._emitted = []
        self._period = None
        self._handlers = {
            "charge": self._on_charge,
            "refund": self._on_refund,
            "fee": self._on_fee,
            "adjustment": self._on_adjustment,
            "interest": self._on_interest,
            "dispute": self._on_dispute,
            "fx_rate": self._on_fx_rate,
            "note": self._on_note,
        }

    # ------------------------------------------------------------------ run

    def run(self, batch):
        """Process one batch; return the list of Statements for batch.period."""
        self._period = batch.period
        self._open = {}
        self._charges = {}
        self._emitted = []
        for ev in batch.events:
            self._rollover(ev)
            handler = self._handlers.get(ev.kind)
            if handler is None:
                log.warning("no handler for %s (%s)", ev.kind, ev.event_id)
                continue
            if not self._accepts(ev):
                continue
            handler(ev)
        self._emit_period()
        self._rollover(None)
        return list(self._emitted)

    def _accepts(self, ev):
        if not ev.account_id:
            log.warning("event %s has no account; dropped", ev.event_id)
            return False
        if ev.amount_cents < 0 and ev.kind in ("charge", "fee", "interest"):
            log.warning("negative %s %s; dropped", ev.kind, ev.event_id)
            return False
        return True

    # ------------------------------------------------------- statement slots

    def _statement(self, account_id, currency="USD"):
        st = self._open.get(account_id)
        if st is None:
            st = Statement(
                account_id=account_id,
                period=self._period,
                currency=currency,
                opening_cents=self._balances.get(account_id, 0),
            )
            self._open[account_id] = st
        return st

    def _convert(self, cents, src, dst):
        if src == dst:
            return cents
        rate = self._fx.get((src, dst))
        if rate is None:
            inverse = self._fx.get((dst, src))
            if inverse is None:
                raise KeyError(f"no fx rate {src}->{dst}")
            rate = 1.0 / inverse
        return int(round(cents * rate))

    # ------------------------------------------------------------- handlers

    def _on_charge(self, ev):
        st = self._statement(ev.account_id, ev.currency)
        amount = self._convert(ev.amount_cents, ev.currency, st.currency)
        st.add(ev, amount)
        self._charges[ev.event_id] = ev

    def _on_refund(self, ev):
        # A refund immediately followed by a dispute on the same charge is a
        # processor-side chargeback conversion: the dispute supersedes the
        # refund and the refund must not post. We cannot know that until we
        # see the next event, so every refund waits one step in _held and is
        # settled by _rollover() when the next event (or end of batch) arrives.
        if self._refunds.is_duplicate(ev):
            return
        self._held.append(ev)

    def _on_fee(self, ev):
        st = self._statement(ev.account_id, ev.currency)
        if ev.memo == "late" and ev.amount_cents == 0:
            st.add(ev, LATE_FEE_CENTS, "late payment fee")
            return
        st.add(ev, self._convert(ev.amount_cents, ev.currency, st.currency))

    def _on_adjustment(self, ev):
        st = self._statement(ev.account_id, ev.currency)
        # adjustments are signed; positive = debit to the customer
        st.add(ev, self._convert(ev.amount_cents, ev.currency, st.currency), ev.memo or "adjustment")

    def _on_interest(self, ev):
        st = self._statement(ev.account_id, ev.currency)
        bps = int(ev.meta.get("apr_bps", 0))
        if bps > INTEREST_CAP_BPS:
            log.warning("apr %s bps above cap on %s; capping", bps, ev.event_id)
            bps = INTEREST_CAP_BPS
        base = max(st.opening_cents, 0)
        amount = ev.amount_cents or int(round(base * bps / 10000 / 12))
        if amount:
            st.add(ev, amount, f"interest @ {bps / 100:.2f}% APR")

    def _on_dispute(self, ev):
        self._disputed.add(ev.ref)
        st = self._statement(ev.account_id, ev.currency)
        charge = self._charges.get(ev.ref)
        if charge is not None:
            amount = self._convert(charge.amount_cents, charge.currency, st.currency)
            st.add(ev, -amount, f"provisional credit, dispute on {ev.ref}")
        else:
            st.notes.append(f"dispute {ev.event_id} on charge {ev.ref} from an earlier period")

    def _on_fx_rate(self, ev):
        src, dst = ev.meta.get("pair", "USD/USD").split("/")
        self._fx[(src, dst)] = float(ev.meta.get("rate", 1.0))

    def _on_note(self, ev):
        self._statement(ev.account_id, ev.currency).notes.append(ev.memo)

    # ----------------------------------------------------- minimum payment

    def minimum_payment(self, statement):
        """Minimum payment due for a statement, per the cardholder agreement:

        the greater of (a) 1% of the closing balance plus this period's
        interest and fees, or (b) a $25 floor — never more than the closing
        balance itself, and zero on a credit balance.
        """
        closing = statement.closing_cents
        if closing <= 0:
            return 0
        interest = statement.total("interest")
        fees = statement.total("fee")
        pct = int(round(closing * 0.01))
        candidate = pct + interest + fees
        floor = 2500
        due = max(candidate, floor)
        return min(due, closing)

    def past_due(self, statement, prior_minimum_cents, paid_cents):
        """Amount past due carried into this statement from the prior one."""
        shortfall = prior_minimum_cents - paid_cents
        return shortfall if shortfall > 0 else 0

    # ----------------------------------------------------------- reconcile

    def reconcile(self, statement):
        """Internal consistency checks run by the job before statements ship.

        Returns a list of human-readable problems; empty means clean.
        """
        problems = []
        seen = set()
        for line in statement.lines:
            if line.event_id in seen and line.kind != "interest":
                problems.append(f"{statement.account_id}: event {line.event_id} posted twice")
            seen.add(line.event_id)
            if line.kind == "charge" and line.amount_cents < 0:
                problems.append(f"{statement.account_id}: negative charge {line.event_id}")
            if line.kind == "refund" and line.amount_cents > 0:
                problems.append(f"{statement.account_id}: positive refund {line.event_id}")
        if statement.total("interest") and statement.opening_cents <= 0:
            problems.append(f"{statement.account_id}: interest on non-positive opening balance")
        disputes = [l for l in statement.lines if l.kind == "dispute"]
        for d in disputes:
            ref = d.memo.rsplit(" ", 1)[-1]
            if ref not in self._disputed:
                problems.append(f"{statement.account_id}: dispute credit {d.event_id} without dispute record")
        return problems

    def reconcile_all(self, statements):
        out = {}
        for st in statements:
            p = self.reconcile(st)
            if p:
                out[st.account_id] = p
        return out

    # ------------------------------------------------------------ summaries

    def period_summary(self, statements):
        """Aggregate figures for the ops dashboard, keyed by kind."""
        summary = {k: 0 for k in self._handlers}
        summary["accounts"] = 0
        summary["closing_total"] = 0
        summary["credit_balances"] = 0
        for st in statements:
            summary["accounts"] += 1
            summary["closing_total"] += st.closing_cents
            if st.closing_cents < 0:
                summary["credit_balances"] += 1
            for line in st.lines:
                if line.kind in summary:
                    summary[line.kind] += line.amount_cents
        return summary

    def largest_movements(self, statements, n=10):
        movements = []
        for st in statements:
            delta = st.closing_cents - st.opening_cents
            movements.append((abs(delta), st.account_id, delta))
        movements.sort(reverse=True)
        return [(acct, delta) for _, acct, delta in movements[:n]]

    def dormant(self, statements):
        return [st.account_id for st in statements if not st.lines]

    # --------------------------------------------------------- serialization

    def to_rows(self, statement):
        """Flatten a statement into export rows (one per line + a closing row)."""
        rows = []
        running = statement.opening_cents
        rows.append({
            "account": statement.account_id,
            "period": statement.period,
            "kind": "opening",
            "event": "",
            "amount_cents": statement.opening_cents,
            "balance_cents": running,
            "memo": "opening balance",
        })
        for line in statement.lines:
            running += line.amount_cents
            rows.append({
                "account": statement.account_id,
                "period": statement.period,
                "kind": line.kind,
                "event": line.event_id,
                "amount_cents": line.amount_cents,
                "balance_cents": running,
                "memo": line.memo,
            })
        rows.append({
            "account": statement.account_id,
            "period": statement.period,
            "kind": "closing",
            "event": "",
            "amount_cents": 0,
            "balance_cents": statement.closing_cents,
            "memo": "closing balance",
        })
        return rows

    def from_rows(self, rows):
        """Inverse of to_rows, used by the replay tool."""
        if not rows:
            return None
        head = rows[0]
        st = Statement(
            account_id=head["account"],
            period=head["period"],
            currency=head.get("currency", "USD"),
            opening_cents=head["amount_cents"],
        )
        for r in rows[1:]:
            if r["kind"] in ("opening", "closing"):
                continue
            st.lines.append(Line(r["event"], r["kind"], r["amount_cents"], r.get("memo", "")))
        return st

    # ------------------------------------------------------------- rollover

    def _rollover(self, next_ev):
        """Settle refunds held from the previous step.

        Called before each event is handled, and once more after the loop with
        next_ev=None so the batch's trailing refund is settled.
        """
        if not self._held:
            return
        held, self._held = self._held, []
        for refund in held:
            if (
                next_ev is not None
                and next_ev.kind == "dispute"
                and next_ev.ref == refund.ref
            ):
                log.info("refund %s superseded by dispute %s", refund.event_id, next_ev.event_id)
                continue
            self._apply_refund(refund)

    def _apply_refund(self, ev):
        st = self._statement(ev.account_id, ev.currency)
        amount = self._convert(ev.amount_cents, ev.currency, st.currency)
        st.add(ev, -abs(amount), ev.memo or f"refund of {ev.ref}")
        self._refunds.record(ev)

    # ---------------------------------------------------------------- emit

    def _emit_period(self):
        for account_id in sorted(self._open):
            st = self._open[account_id]
            if not st.lines and not st.notes and st.opening_cents == 0:
                continue
            self._balances[account_id] = st.closing_cents
            self._emitted.append(st)
        self._open = {}

    # -------------------------------------------------------------- queries

    def balance(self, account_id):
        return self._balances.get(account_id, 0)

    def disputed(self):
        return set(self._disputed)

    def as_money(self, statement):
        return Money(statement.closing_cents, statement.currency)
