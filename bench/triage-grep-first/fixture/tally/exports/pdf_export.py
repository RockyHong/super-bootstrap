"""Customer statement PDF — text layout only; the renderer turns it into a PDF."""

from ..money import fmt_money

WIDTH = 72


def _row(left, right):
    pad = WIDTH - len(left) - len(right)
    return left + " " * max(pad, 1) + right


def statement_layout(engine, statement, account):
    cur, loc = statement.currency, account.locale
    lines = []
    lines.append(f"{account.name}".ljust(WIDTH))
    lines.append(f"Statement for {statement.period}".ljust(WIDTH))
    lines.append("-" * WIDTH)
    lines.append(_row("Opening balance", fmt_money(statement.opening_cents, cur, loc)))
    for l in statement.lines:
        lines.append(_row(f"  {l.memo or l.kind}"[:50], fmt_money(l.amount_cents, cur, loc)))
    lines.append("-" * WIDTH)
    lines.append(_row("Closing balance", fmt_money(statement.closing_cents, cur, loc)))
    due = engine.minimum_payment(statement)
    lines.append(_row("Minimum payment due", fmt_money(due, cur, loc)))
    for n in statement.notes:
        lines.append(f"Note: {n}"[:WIDTH])
    return "\n".join(lines)
