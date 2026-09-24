"""Money formatting and arithmetic helpers.

Amounts travel through tally as integer cents. Formatting is the only place a
currency symbol or a locale's separators are applied.
"""

from dataclasses import dataclass

# ISO-4217 code -> display symbol. Unknown codes render as the code itself,
# followed by a space ("CHF 12.00"), which is the conventional fallback.
SYMBOLS = {
    "USD": "$",
    "CAD": "CA$",
    "AUD": "A$",
    "EUR": "€",
    "GBP": "£",
    "JPY": "¥",
    "INR": "₹",
    "BRL": "R$",
    "MXN": "MX$",
}

# Currencies with no minor unit.
ZERO_DECIMAL = {"JPY"}

# locale -> (thousands separator, decimal separator)
SEPARATORS = {
    "en_US": (",", "."),
    "en_GB": (",", "."),
    "en_CA": (",", "."),
    "fr_CA": (" ", ","),
    "de_DE": (".", ","),
    "fr_FR": (" ", ","),
    "pt_BR": (".", ","),
    "es_MX": (",", "."),
    "ja_JP": (",", "."),
}

DEFAULT_LOCALE = "en_US"


@dataclass(frozen=True)
class Money:
    cents: int
    currency: str

    def __add__(self, other):
        _same_currency(self, other)
        return Money(self.cents + other.cents, self.currency)

    def __sub__(self, other):
        _same_currency(self, other)
        return Money(self.cents - other.cents, self.currency)

    def __neg__(self):
        return Money(-self.cents, self.currency)

    def is_zero(self):
        return self.cents == 0


def _same_currency(a, b):
    if a.currency != b.currency:
        raise ValueError(f"currency mismatch: {a.currency} vs {b.currency}")


def _group(digits, sep):
    out = []
    while len(digits) > 3:
        out.insert(0, digits[-3:])
        digits = digits[:-3]
    out.insert(0, digits)
    return sep.join(out)


def fmt_money(cents, currency, locale=DEFAULT_LOCALE):
    """Render integer cents as a display string, e.g. fmt_money(123456, "USD") -> "$1,234.56".

    `currency` is an ISO-4217 code; `locale` picks the separators.
    """
    thousands, decimal = SEPARATORS.get(locale, SEPARATORS[DEFAULT_LOCALE])
    symbol = SYMBOLS.get(currency)
    prefix = symbol if symbol is not None else f"{currency} "
    sign = "-" if cents < 0 else ""
    cents = abs(int(cents))
    if currency in ZERO_DECIMAL:
        body = _group(str(cents), thousands)
    else:
        whole, frac = divmod(cents, 100)
        body = f"{_group(str(whole), thousands)}{decimal}{frac:02d}"
    return f"{sign}{prefix}{body}"


def parse_cents(text):
    """Parse a plain decimal string ("12.34", "-5", "1000.5") into integer cents."""
    text = text.strip()
    neg = text.startswith("-")
    if neg:
        text = text[1:]
    if "." in text:
        whole, frac = text.split(".", 1)
        frac = (frac + "00")[:2]
    else:
        whole, frac = text, "00"
    cents = int(whole or "0") * 100 + int(frac)
    return -cents if neg else cents


def sum_cents(items):
    return sum(int(i) for i in items)
