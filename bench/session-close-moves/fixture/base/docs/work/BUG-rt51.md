# BUG-rt51 — a failed outage report retries forever

**Logged:** 2026-10-01 · **Source:** shift log
**Problem:** A failed outage report retried forever and filled the shift console's queue.
**Area:** `config/cabinet.toml`, the report task

## Plan — 2026-10-02

1. Cap the report retries in `config/cabinet.toml`.
2. Drop the report after the last retry and raise a panel fault.

## Progress — 2026-10-03

Steps 1 and 2 done and committed. After 5 failed retries the controller drops the report and the panel shows fault E7.
