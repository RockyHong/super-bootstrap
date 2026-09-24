"""CSV export of statements for the finance team (internal)."""

import csv
import io

from ..money import fmt_money

HEADER = ["account", "period", "kind", "event", "amount", "balance", "memo"]


def statement_csv(engine, statements, accounts):
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(HEADER)
    for st in statements:
        acct = accounts.get(st.account_id)
        locale = acct.locale if acct else "en_US"
        for row in engine.to_rows(st):
            w.writerow([
                row["account"],
                row["period"],
                row["kind"],
                row["event"],
                fmt_money(row["amount_cents"], st.currency, locale),
                fmt_money(row["balance_cents"], st.currency, locale),
                row["memo"],
            ])
    return buf.getvalue()


def raw_csv(engine, statements):
    """Unformatted cents, for machine consumers."""
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(["account", "period", "kind", "event", "amount_cents", "balance_cents"])
    for st in statements:
        for row in engine.to_rows(st):
            w.writerow([row["account"], row["period"], row["kind"], row["event"],
                        row["amount_cents"], row["balance_cents"]])
    return buf.getvalue()
