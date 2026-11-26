# BUG-r4k8 — parse_window accepts zero, negative and uppercase-unit windows wrongly

**Logged:** 2026-11-18 · **Source:** support ticket from the billing team
**Problem:** `parse_window("0s")` and `parse_window("-5m")` return 0 and -300, and the limiter then divides by the window or never resets. `parse_window("5M")` raises a bare `KeyError` instead of a clear error.
**Area:** `src/ratelimit/window.py`

## Design — 2026-11-21

Considered clamping a non-positive value to 1 second, as the old Go limiter did. Rejected: clamping hid a misconfigured billing window for two weeks last quarter. Decision: reject a non-positive value with `ValueError`. Accept the unit case-insensitively (`5M` == `5m`), because the ops config generator emits uppercase. An unknown unit raises `ValueError` naming the unit.
