"""HTTP handlers for the customer portal (framework-agnostic request -> dict)."""

from ..accounts import available_credit
from ..money import fmt_money


def get_balance(accounts, account_id):
    a = accounts.get(account_id)
    if a is None:
        return {"status": 404, "error": "no such account"}
    return {
        "status": 200,
        "balance": {"cents": a.balance_cents,
                    "display": fmt_money(a.balance_cents, a.currency, a.locale)},
        "available": {"cents": available_credit(a),
                      "display": fmt_money(available_credit(a), a.currency, a.locale)},
    }


def get_past_due(accounts, account_id):
    a = accounts.get(account_id)
    if a is None:
        return {"status": 404, "error": "no such account"}
    return {
        "status": 200,
        "days": a.days_past_due,
        "amount": {"cents": a.past_due_cents,
                   "display": fmt_money(a.past_due_cents, a.currency, a.locale)},
    }


def get_credit_limit(accounts, account_id):
    a = accounts.get(account_id)
    if a is None:
        return {"status": 404, "error": "no such account"}
    return {"status": 200,
            "limit": fmt_money(a.credit_limit_cents, a.currency, locale=a.locale)}
