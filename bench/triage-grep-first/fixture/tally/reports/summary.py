"""Nightly ops summary posted to the finance channel (internal)."""

from ..money import fmt_money


def ops_summary(engine, statements, currency="USD"):
    s = engine.period_summary(statements)
    lines = [
        f"accounts: {s['accounts']}",
        f"charges: {fmt_money(s['charge'], currency)}",
        f"refunds: {fmt_money(s['refund'], currency)}",
        f"fees: {fmt_money(s['fee'], currency)}",
        f"interest: {fmt_money(s['interest'], currency)}",
        f"closing total: {fmt_money(s['closing_total'], currency)}",
        f"credit balances: {s['credit_balances']}",
    ]
    for acct, delta in engine.largest_movements(statements, 5):
        lines.append(f"  mover {acct}: {fmt_money(delta, currency)}")
    return "\n".join(lines)
