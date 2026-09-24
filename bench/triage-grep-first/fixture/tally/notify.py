"""Customer email notifications (statement ready, payment received)."""

from .money import fmt_money


def statement_ready(account, statement, minimum_due_cents):
    return (
        f"Hi {account.name},\n\n"
        f"Your {statement.period} statement is ready. Closing balance: "
        f"{fmt_money(statement.closing_cents, account.currency, account.locale)}.\n"
        f"Minimum payment due: {fmt_money(minimum_due_cents, account.currency, account.locale)}.\n"
    )


def payment_received(account, amount_cents):
    return (
        f"Hi {account.name},\n\n"
        f"We received your payment of {fmt_money(amount_cents, account.currency, account.locale)}. "
        f"Thank you.\n"
    )
