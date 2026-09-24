"""Receivables aging report (internal, finance)."""

from ..money import fmt_money

BUCKETS = ((0, "current"), (30, "1-30"), (60, "31-60"), (90, "61-90"), (10**9, "90+"))


def bucket_for(days_past_due):
    for limit, name in BUCKETS:
        if days_past_due <= limit:
            return name
    return BUCKETS[-1][1]


def aging_table(accounts):
    totals = {name: 0 for _, name in BUCKETS}
    for a in accounts.values():
        if a.closed or a.past_due_cents <= 0:
            continue
        totals[bucket_for(a.days_past_due)] += a.past_due_cents
    return totals


def render_aging(accounts, currency="USD"):
    totals = aging_table(accounts)
    out = ["bucket      amount"]
    for _, name in BUCKETS:
        out.append(f"{name:<11} {fmt_money(totals[name], currency)}")
    return "\n".join(out)
