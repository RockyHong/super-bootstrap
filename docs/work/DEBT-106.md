# DEBT-106 — commit-guard's stamp-ordering arm passes vacuously; no arm proves the stamp still fires

**Logged:** 2026-08-27 · **Source:** gateway self-verify while integrating the BUG-049 fix
**Problem:** `bench/commit-guard/`'s stamp-ordering arm asserts `foreign.md` never appears in `stamp-argv.log`. On the shipped (GREEN) wording the arm stops at the readback and the stamp never fires at all, so `stamp-argv.log` is never created — the assertion holds because nothing was stamped, not because the right set was stamped. A §5 prose regression that dropped the stamp step entirely would pass the arm. The RED/GREEN pair discriminates readback-after-stamp from readback-before-stamp; it does not discriminate correct-ordering from no-stamp-at-all.
**Area:** `bench/commit-guard/README.md` § Stamp-ordering arm; `bench/commit-guard/make-fixture.sh`; `bench/commit-guard/stamp-recorder.sh`
**Prior:** Needs a second fixture shape the current `make-fixture.sh` does not produce — a clean index (this session's paths staged, no foreign leftover) — plus a positive arm asserting `stamp-argv.log` contains exactly the verdict line and the session set. That turns the existing assertion from "foreign absent" into "argv equals the committed set", which is the property `harness-audit-pretool.sh:39-41` actually requires.
**Test-feel:** e2e
**Stochastic:** llm
**Blast:** local
