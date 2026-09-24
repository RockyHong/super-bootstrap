"""Dunning letters — customer-facing past-due notices, sent by email and post."""

from ..money import fmt_money

STAGES = (
    (15, "reminder"),
    (45, "second_notice"),
    (75, "final_notice"),
)

TEMPLATES = {
    "reminder": (
        "Dear {name},\n\n"
        "Our records show a past-due amount of {amount} on your account.\n"
        "If you have already paid, please disregard this message.\n"
    ),
    "second_notice": (
        "Dear {name},\n\n"
        "Your account is now {days} days past due. The amount of {amount}\n"
        "must be paid to avoid further fees of {fee}.\n"
    ),
    "final_notice": (
        "Dear {name},\n\n"
        "FINAL NOTICE: {amount} is {days} days past due. Your account will be\n"
        "suspended unless payment is received within 10 days.\n"
    ),
}


def stage_for(days_past_due):
    stage = None
    for threshold, name in STAGES:
        if days_past_due >= threshold:
            stage = name
    return stage


def letter(account, late_fee_cents=3500):
    stage = stage_for(account.days_past_due)
    if stage is None or account.closed:
        return None
    return TEMPLATES[stage].format(
        name=account.name,
        days=account.days_past_due,
        amount=fmt_money(account.past_due_cents, account.locale, account.currency),
        fee=fmt_money(late_fee_cents, account.currency, account.locale),
    )


def letters(accounts):
    out = {}
    for a in accounts.values():
        body = letter(a)
        if body:
            out[a.account_id] = body
    return out
