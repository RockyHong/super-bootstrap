"""JSON export consumed by the customer portal API."""

import json

from ..money import fmt_money


def statement_json(engine, statement, account):
    loc = account.locale
    cur = statement.currency
    doc = {
        "account": statement.account_id,
        "period": statement.period,
        "currency": cur,
        "opening": {"cents": statement.opening_cents,
                    "display": fmt_money(statement.opening_cents, cur, loc)},
        "closing": {"cents": statement.closing_cents,
                    "display": fmt_money(statement.closing_cents, cur, loc)},
        "minimum_due": {"cents": engine.minimum_payment(statement),
                        "display": fmt_money(engine.minimum_payment(statement), cur, loc)},
        "lines": [
            {"event": l.event_id, "kind": l.kind, "cents": l.amount_cents,
             "display": fmt_money(l.amount_cents, cur, loc), "memo": l.memo}
            for l in statement.lines
        ],
        "notes": list(statement.notes),
    }
    return json.dumps(doc, ensure_ascii=False, sort_keys=True)
