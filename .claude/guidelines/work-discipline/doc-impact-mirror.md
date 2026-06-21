# Doc Impact Mirror

Every work-scope artifact (plan, scope, spec — whatever the pipeline names them) lists adjacent docs that may need updates from this work. Implementer updates each listed doc in the same change, or explicitly records "none — confirmed unchanged after read." Verification stage gates before merge.

Anti-drift discipline at change-time. Specs + code + reference docs evolve in parallel; without mirroring, they desync silently.

## Test

> "If I changed behavior described elsewhere, did I read those docs and either update them or confirm they're still accurate?"

- All yes → safe to merge.
- Any "haven't looked" → not session-safe. Read first.

## Failure modes

- Doc Impact omitted "because nothing relevant changed" → next session can't tell whether scan happened or got skipped.
- Adjacent docs listed but no outcome marker → reader doesn't know whether they were checked.

Upstream discipline: the single-source-of-truth principle handles design-time dedup; Doc Impact mirror handles drift SSoT can't dedupe.
