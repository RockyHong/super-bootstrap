"""Account records as loaded from the customer store."""

from dataclasses import dataclass


@dataclass
class Account:
    account_id: str
    name: str
    email: str
    currency: str = "USD"      # ISO-4217 billing currency
    locale: str = "en_US"      # display locale for customer-facing output
    balance_cents: int = 0
    past_due_cents: int = 0
    days_past_due: int = 0
    credit_limit_cents: int = 0
    closed: bool = False


def load_accounts(rows):
    """Build Accounts from customer-store dict rows."""
    out = {}
    for r in rows:
        a = Account(
            account_id=r["id"],
            name=r.get("name", ""),
            email=r.get("email", ""),
            currency=r.get("currency", "USD"),
            locale=r.get("locale", "en_US"),
            balance_cents=int(r.get("balance_cents", 0)),
            past_due_cents=int(r.get("past_due_cents", 0)),
            days_past_due=int(r.get("days_past_due", 0)),
            credit_limit_cents=int(r.get("credit_limit_cents", 0)),
            closed=bool(r.get("closed", False)),
        )
        out[a.account_id] = a
    return out


def available_credit(account):
    return max(account.credit_limit_cents - account.balance_cents, 0)
