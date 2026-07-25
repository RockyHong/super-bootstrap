# Carry — harness de-routing

## Anchor

Cut super-bootstrap's dependence on superpowers: it stops routing any external
process harness. Change A decided, Wave 1 + DEBT-031 shipped; change B (adopt
mattpocock) still open.

## Read first

1. `docs/specs/harness-architecture.md` — §3 dissolve table carries a **Cut**
   column (landed vs open) · §4 the grep-verifiable target state + remaining-site
   table · §5 why the fences stayed ambient · §8 adopt-mode coverage per cut site.
2. `docs/backlog.md` — DEBT-021/022/023, DEBT-026/027/028, DEBT-030/032,
   BUG-019, GAP-037, GAP-038, GAP-041, GAP-042.
3. `docs/decisions.md` — top row closes the triage doctrine-body fork; the next
   closes the rules-layer fence direction.
4. `git log --oneline a64bc7b..HEAD` — reasoning lives in the commit bodies.

## State

Wave 1 shipped and pushed. **DEBT-031 landed** — `2a96af5`, committed **local,
not pushed**. The triage skill + agent no longer name
`superpowers:systematic-debugging`; the discipline clause stands on its own and
the skill description's scope-summary tail is gone. Cold `audit-harness-edits`
ran (1 finding dispositioned), harness state stamped. Spec §3 row flipped to
landed, §8 gained its coverage row, card deleted.

**No foreign-harness skill referent survives anywhere in `plugins/`** — every
remaining `superpowers` hit is a path string, a naming string, or a folder-shape
consumer, all owned by DEBT-026 (spec §4 table).

## Next step — Wave 2, then the rest

- **Wave 2 — DEBT-027** (strip venue intent classification). Unblocks drain's
  eligibility rewrite. Check whether it subsumes DEBT-022 and BUG-019 first.
  Side effect: its venue-mode table is what makes spec §4's `rg … should return
  zero` unreachable (the plain English word "brainstorming" sits in those rows) —
  deleting them self-resolves it, so don't patch §4 separately.
- **Wave 3 — DEBT-026** (retire `docs/superpowers/specs|plans/`). Widest consumer
  set, and it owns the deferred naming work: `harness-bootstrap/SKILL.md`
  `description:`, the "superpowers runway" prose, the
  `chore: scaffold|sync superpowers pipeline` commit strings — which double as the
  mature-repo bootstrap detector, so they rename once, not twice — and the
  `superpowers` pipeline-family `tags:` keyword on 7 files. Carries its own
  downstream migration (§8 folder hole).
- **Wave 4 — DEBT-028** (drain stage machine → interface-driven). Needs 026's path
  decision and 027's eligibility shape settled.
- **Anytime, independent:** GAP-041 (read mattpocock at grade A; gates change B).

## Watch-outs

- **`2a96af5` is unpushed.** Push was deliberately withheld, not forgotten.
- **`.claude/settings.json` still pins superpowers locally.** That mask hid
  DEBT-031 through a whole authoring round. Any "is the repo still coupled?" check
  must reason about a repo *without* the pin, not this one.
- **RED pays on shipped prose — and usually says "write less".** DEBT-031's
  no-guidance control passed 5/5, so its carded Prior (author a replacement
  doctrine body) was unearned and the fix shipped purely subtractive. Waves
  026/027/028 touch the same lane; run the control before authoring prose there.
- **Evidence grades are load-bearing** (§7). Every mattpocock claim except the
  issue-tracker option list is grade B; two derived claims have already proved
  false mid-work after shaping full rounds of reasoning.
- **GAP-038 is blocked on change B** — held out of the cut deliberately.
- **Don't re-propose a rules-layer home for the discipline fences.**
  `docs/decisions.md` closes it, and the reason is mechanical: a `paths:` rule
  fires on file read, not on intent.
