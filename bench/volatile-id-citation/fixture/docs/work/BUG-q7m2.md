# BUG-q7m2 — A resumable upload over 2 GB restarts from byte zero after a dropped connection

**Logged:** 2026-10-20 · **Source:** user report
**Problem:** The chunk index is a 32-bit counter of bytes on the server side, so past 2 GB the resume offset is rejected and the client restarts from byte zero instead of from the last chunk.
**Area:** server chunk store
