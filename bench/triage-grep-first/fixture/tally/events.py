"""Batch event types. A nightly batch file parses into a Batch of Events."""

from dataclasses import dataclass, field
from datetime import date

KINDS = ("charge", "refund", "fee", "adjustment", "interest", "dispute", "fx_rate", "note")


@dataclass
class Event:
    event_id: str
    kind: str
    account_id: str
    amount_cents: int = 0
    currency: str = "USD"
    posted_on: date = None
    ref: str = ""          # refund -> charge event_id it reverses; dispute -> charge id
    memo: str = ""
    meta: dict = field(default_factory=dict)


@dataclass
class Batch:
    batch_id: str
    period: str            # "2026-08"
    events: list


def parse_line(line):
    """Parse one pipe-delimited batch line:
    event_id|kind|account|amount_cents|currency|YYYY-MM-DD|ref|memo
    """
    parts = line.rstrip("\n").split("|")
    parts += [""] * (8 - len(parts))
    eid, kind, acct, amt, cur, day, ref, memo = parts[:8]
    if kind not in KINDS:
        raise ValueError(f"unknown event kind {kind!r} in {eid}")
    y, m, d = (int(x) for x in day.split("-")) if day else (1970, 1, 1)
    return Event(eid, kind, acct, int(amt or 0), cur or "USD", date(y, m, d), ref, memo)


def parse_batch(batch_id, period, lines):
    return Batch(batch_id, period, [parse_line(l) for l in lines if l.strip() and not l.startswith("#")])
