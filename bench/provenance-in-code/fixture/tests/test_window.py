from ratelimit import parse_window


def test_seconds():
    assert parse_window("30s") == 30


def test_minutes():
    assert parse_window("5m") == 300
