# Carry — harness de-routing

## Anchor

Cut super-bootstrap's dependence on superpowers: it stops routing any external
process harness. Change A decided; Wave 1, DEBT-031, and Wave 2 shipped. Change B
(adopt mattpocock) still open.

## Read first

1. `docs/specs/harness-architecture.md` — §3 dissolve table carries a **Cut**
   column (landed vs open) · §4 the grep-verifiable target state + remaining-site
   table, now carrying a **live command referent** kind · §5 why the fences stayed
   ambient · §8 adopt-mode coverage per cut site.
2. `docs/backlog.md` — DEBT-021/022/023, DEBT-026/027/028, DEBT-030,
   DEBT-032/033/034, BUG-019, GAP-037, GAP-038, GAP-041, GAP-042.
3. `docs/decisions.md` — top row closes the intent-axis de-routing fork; the next
   two close the triage doctrine-body fork and the rules-layer fence direction.
4. `git log --oneline a64bc7b..HEAD` — reasoning lives in the commit bodies.

## State

Wave 2 shipped — `659a509`. The todo lane's `brainstorm` vocabulary is renamed
(`Settle design` action verb, `Design-open` spec-shape label, `/super-bootstrap:log`
as the empty-state door); the intent axis, its predicates, and drain's gates were
deliberately not touched. DEBT-027 re-aimed at the cost question after its carded
de-routing premise was falsified against the code. Cold `audit-harness-edits` ran
(PASS WITH NITS, 3 findings dispositioned — 2 applied, 1 carded as DEBT-034),
harness state stamped.

**spec §4's grep was blind to command-form referents** — a pattern built from skill
names (`brainstorming`, `writing-plans`) cannot see `/brainstorm`, `/write-plan`,
`/execute-plan`. Widened, it exposed live foreign-command referents the skeleton cut
missed: `drain/assets/phase-loop.md` actually **dispatches** those three as phase
commands (DEBT-028), and two prose routes survive in help/bootstrap (DEBT-033). The
prior carry's claim "no foreign-harness skill referent survives anywhere in
`plugins/`" is false — it rested on the narrow pattern.

## Next step — Wave 3, then the rest

- **Wave 3 — DEBT-026** (retire `docs/superpowers/specs|plans/`). Widest consumer
  set, and it owns the deferred naming work: `harness-bootstrap/SKILL.md`
  `description:`, the "superpowers runway" prose, the
  `chore: scaffold|sync superpowers pipeline` commit strings — which double as the
  mature-repo bootstrap detector, so they rename once, not twice — and the
  `superpowers` pipeline-family `tags:` keyword on 7 files. Carries its own
  downstream migration (§8 folder hole).
- **Wave 4 — DEBT-028** (drain stage machine → interface-driven). Needs 026's path
  decision. Now also owns `phase-loop.md`'s live `/brainstorm` · `/write-plan` ·
  `/execute-plan` dispatch, which is a real runtime coupling, not a naming string.
- **DEBT-033** — help/bootstrap prose routes. `skills/super-bootstrap/SKILL.md:42`
  is the sharper half: it seeds a foreign command name into the *consumer* repo's
  backlog, outliving the cut in repos this one does not control.
- **DEBT-034** — the backlog's write-once claim rule has no stated path for a card
  whose premise is falsified; the DEBT-027 re-aim took the overwrite path ad hoc.
- **Anytime, independent:** GAP-041 (read mattpocock at grade A; gates change B).

## Watch-outs

- **super-bootstrap's own skills did not load this session.** Device
  `~/.claude/settings.json:222` carries `"super-bootstrap@super-bootstrap": false`;
  this repo's project pin says `true` and loses. `/super-bootstrap:log` and
  `/super-bootstrap:commit` were unavailable — cards and commits went inline. Every
  dogfood claim about the repo's own doors is untested until that flips.
- **`.claude/settings.json` still pins superpowers locally.** Any "is the repo still
  coupled?" check must reason about a repo *without* the pin, not this one.
- **A grep proxy built from names goes blind to forms.** §4's check missed live
  command referents for a whole wave. Derive the pattern from the shape a referent
  takes at the call site, not from the skill-name list.
- **RED pays on shipped prose — and usually says "write less".** DEBT-031's
  no-guidance control passed 5/5, so its carded Prior was unearned. Waves 026/028
  touch the same lane; run the control before authoring prose there.
- **Evidence grades are load-bearing** (§7). Every mattpocock claim except the
  issue-tracker option list is grade B; two derived claims already proved false
  mid-work after shaping full rounds of reasoning.
- **GAP-038 is blocked on change B** — held out of the cut deliberately.
- **Don't re-propose a rules-layer home for the discipline fences.**
  `docs/decisions.md` closes it, and the reason is mechanical: a `paths:` rule
  fires on file read, not on intent.
