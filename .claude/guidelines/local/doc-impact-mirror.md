# Doc Impact Mirror

A change enumerates the adjacent docs its behavior may have moved, and each one
leaves an outcome marker in the same change: updated, or "read — confirmed
unchanged." Whatever names the scan set — a plan block, a scope artifact, a
commit-time gate that derives it mechanically — the marker is what makes the scan
readable afterward.

Anti-drift discipline at change-time. Specs + code + reference docs evolve in
parallel; without mirroring, they desync silently.

## Test

> "If I changed behavior described elsewhere, did I read those docs and either update them or confirm they're still accurate?"

- All yes → safe to land.
- Any "haven't looked" → not session-safe. Read first.

## Failure modes

- Scan omitted "because nothing relevant changed" → next session can't tell whether it happened or got skipped.
- Adjacent docs enumerated but no outcome marker → reader doesn't know whether they were checked.

Upstream discipline: the single-source-of-truth principle handles design-time dedup; Doc Impact mirror handles drift SSoT can't dedupe.

In this repo the enumeration and the gate are both the commit door — [`CLAUDE.md` § Doc Sync](../../../CLAUDE.md#doc-sync-non-negotiable).
