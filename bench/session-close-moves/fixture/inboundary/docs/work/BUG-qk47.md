# BUG-qk47 — the shutdown routine leaves the heater on

**Logged:** 2026-11-10 · **Source:** this session, while writing `docs/shutdown.md`
**Problem:** `docs/shutdown.md` never tells the operator to switch the heater off, so a cabinet left ajar overnight keeps heating an empty chamber.
**Area:** `docs/shutdown.md`
