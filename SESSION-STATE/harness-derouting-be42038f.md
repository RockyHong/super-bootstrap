# Carry — harness de-routing

## Anchor

Cut super-bootstrap's dependence on superpowers: it stops routing any external
process harness. Change A decided; Waves 1–3 shipped. Change B (adopt
mattpocock) still open.

## Read first

1. `docs/specs/harness-architecture.md` — §3 dissolve table (only drain's stage
   machine is still open) · §4 the seam, now naming two **sanctioned** hit
   classes the grep may return · §6 wave-close conditions + § His dispatch
   posture (settled grade A) · §7 evidence index · §8 downstream migration.
2. `docs/backlog.md` — DEBT-021/022/023, DEBT-027/028, DEBT-030, DEBT-032 →
   036, BUG-019, GAP-037, GAP-038, GAP-042, GAP-043.
3. `docs/decisions.md` — three top rows close the intent-axis, triage
   doctrine-body, and rules-layer-fence forks.
4. `git log --oneline a64bc7b..HEAD` — reasoning lives in the commit bodies.

## State

Wave 3 shipped — `00c54be`. `docs/superpowers/` is `docs/work/`, and the naming
that rode with it went in the same change (skill description + H1, runway prose,
emitted commit strings, family `tags:` on 7 files, both manifests). Phase 2a
migrates before it creates, so downstream gets a real migration rather than the
orphan §8 previously accepted.

GAP-041 closed before it — `a5079da`. mattpocock read at grade A across seven
skills. His posture is **session-as-atomic-runner**; dispatch fires only for
isolation (`code-review`) and offload (`research`), and `wayfinder` states the
one-ticket-per-session rule outright. No model tier anywhere in his set.

**That read reversed DEBT-026's fork.** `to-tickets` owns no path — it publishes
to whatever tracker setup configured, and `.scratch/` is only its local
fallback. So retire lost its ground and rename won.

## Next step — Wave 4, then the rest

- **Wave 4 — DEBT-028** (drain stage machine → interface-driven). Now
  unblocked: 026's path decision landed. Owns `phase-loop.md`'s live
  `/brainstorm` · `/write-plan` · `/execute-plan` dispatch — a real runtime
  coupling, not a naming string.
- **DEBT-027 / DEBT-022 / BUG-019** — re-aim against `docs/work/`. BUG-019
  narrows: the Full scaffold restriction is on the path, not the folder's name.
- **DEBT-033** — help/bootstrap prose routes; the `skills/super-bootstrap`
  one seeds a foreign command name into *consumer* backlogs.
- **DEBT-036** (new) — triage-report's dup branch routes new facts to a door
  that refuses them. Pairs with DEBT-034; both press on write-once.
- **DEBT-035** — triage.md's doctrine bullets vs `diagnosing-bugs`, now
  readable at grade A. Check the shape mismatch first: his loop needs a runtime
  to go red; verdict work has none.

## Watch-outs

- **super-bootstrap's own agents did not load this session.** Device
  `~/.claude/settings.json:222` pins `super-bootstrap@super-bootstrap: false`.
  Skills resolved from the plugin cache, but `triage-report`, `log` and
  `doc-sync-scan` were absent from the agent registry — all three ran as
  `general-purpose` carrying the agent body read out of the cache. Every
  dogfood claim about the repo's own doors is still untested. Device config →
  `/contribute`, not this backlog.
- **The §4 grep no longer targets zero.** Two hit classes are sanctioned and
  documented: `resolve-plugins`' illustrative "superpowers or any other", and
  `harness-bootstrap`'s historical detector strings, which must keep matching
  or every bootstrapped repo reads as never-bootstrapped.
- **Case-sensitive greps miss naming.** The H1 "Superpowers Pipeline" survived
  the whole sweep; only `grep -i` caught it. Sweep case-insensitively before
  claiming a rename complete.
- **`.claude/settings.json` still pins superpowers locally.** Any "is the repo
  still coupled?" check must reason about a repo *without* the pin.
- **RED pays on shipped prose — and usually says "write less".** DEBT-031's
  no-guidance control passed 5/5. Run the control before authoring prose in
  this lane.
- **A cold probe's finding can be real with a wrong fix.** The Wave 3 audit
  said `docs/work/triage/` was never a directory; git history shows verdict
  files lived there and were cleaned up. Adjudicate finding and fix shape
  separately.
- **GAP-038 is blocked on change B** — and the grade-A read raised it from
  nice-to-have to the actual composition mechanism.
- **Don't re-propose a rules-layer home for the discipline fences.**
  `docs/decisions.md` closes it: a `paths:` rule fires on file read, not intent.
