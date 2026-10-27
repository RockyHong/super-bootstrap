# GAP-66q7 — CLAUDE.md skeleton § Finding Triage has no parked route on scale-module repos

**Logged:** 2026-10-27 · **Source:** device note from claude-config-manager (its 5.3.0 → 5.5.0 runway re-sync)
**Problem:** § Planning already carries the bracketed `docs/parked.md` line for scale-module installs, but § Finding Triage stops at log vs fix-now. Every scale-module consumer forks in a parked route by hand ("Actionable but waiting on a named trigger → a `docs/parked.md` entry (its header owns the admission bar)"), and that fork then reads as drift on every sync.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md` § Finding Triage
**Prior:** a bracketed conditional line in § Finding Triage, kept when the scale module is installed, like the § Planning lines.
