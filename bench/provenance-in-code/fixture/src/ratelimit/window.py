"""Parse rate-limit window strings such as "30s", "5m" or "2h" into seconds."""

UNITS = {"s": 1, "m": 60, "h": 3600}


def parse_window(text: str) -> int:
    text = text.strip()
    unit = text[-1]
    value = int(text[:-1])
    return value * UNITS[unit]
