# Carry — mattpocock ↔ super-bootstrap pairing

## Anchor

Pair the two so a bootstrapped repo arrives with mattpocock enabled and wired. Decision
landed and propagated this session; **nothing is built**. Next session implements.

## Read first

- `docs/work/GAP-056.md` — the build card; its Area line is the propagation list
- `docs/specs/mattpocock-coexistence.md` — posture header + the tracker recipe that has to
  become a shipped file
- `docs/specs/harness-architecture.md` §4 and §6 — both carry `Superseded` notes pointing here
- `docs/decisions.md` row 21 — reopened + answered in place; the original rejection is
  preserved below the annotation, not deleted
- `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` §2a — the shape to copy:
  `andrej-karpathy-skills` is already a foreign core dep the shipped skeleton names

## State

Decided: device install left **disabled**, enable is **per repo** and bootstrap does it,
plus wiring = awareness prompts + the initial per-repo setup process. Not an opt-in pick,
not hard coupling. Every doc that states a posture now states this one — that sweep was the
session's last unit, after the docs had carried two contradictory postures for two commits.

This repo is already wired by hand (`docs/agents/*`, CLAUDE.md § Agent skills) — it is the
worked example the shipped version generalises from, not a second implementation.

Shipped and published: v2.30.2. Board also holds `BUG-034`, `DEBT-057`, `DEBT-058`, all raw.

## Next step

`/super-bootstrap:triage GAP-056`. Design is largely settled by the owner's statement above,
so expect the verdict to size the propagation rather than reopen the aim.

## Watch-outs

- The §4 grep contract (`plugins/super-bootstrap/` names mattpocock nowhere) is **deliberately
  spent** by this card. An audit will read the first mattpocock string in the shipped tree as
  a violation — it is the decision, not a slip.
- Shipped-skeleton self-containment still binds: whatever gets seeded must resolve from the
  installed plugins alone, with none of this repo's own paths.
- `docs/decisions.md` row 20 (DEBT-035 vacate) has two reopen conditions; pairing satisfies
  only "a covering skill ships as a core pin". It does **not** reopen — don't let the pairing
  work drag it in.
- Row 21 is answered. Re-arguing the built-in-pin merits is re-walking a closed fork.
- This session ran as a child/bridge session whose system prompt blocks the Agent tool until
  the user asks for it. A fresh session may carry the same block — check before assuming
  dispatch is available, since the envelope's build and doc-sync phases both want it.
- Unverified: a clean `/reload-plugins`. The dangling superpowers pin was removed and the
  enabled-vs-installed reconciliation is 7/0, but no error-free reload was observed.
