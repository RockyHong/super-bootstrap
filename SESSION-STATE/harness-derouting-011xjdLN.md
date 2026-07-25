# Carry — harness de-routing

## Anchor

Cut super-bootstrap's dependence on superpowers: it stops routing any external
process harness. Change A decided and Wave 1 shipped; change B (adopt
mattpocock) still open.

## Read first

1. `docs/specs/harness-architecture.md` — §3 dissolve table carries a **Cut**
   column (landed vs open) · §5 why the fences stayed ambient and the rules layer
   cannot hold them · §8 adopt-mode coverage per cut site.
2. `docs/backlog.md` — DEBT-021/022/023, DEBT-026/027/028, DEBT-030/031/032,
   BUG-019, GAP-037, GAP-038, GAP-041, GAP-042.
3. `docs/decisions.md` — top row closes the rules-layer fence direction.
4. `git log --oneline a64bc7b..HEAD` — reasoning lives in the commit bodies.

## State

**Wave 1 shipped and pushed** (`refactor(harness): de-route the pipeline from
superpowers`). Cluster rows 1–3 and the envelope's ambient laws restated as
declared disciplines; `§ Inside a route` and the SDD chain clause removed;
topology doc deleted; `superpowers` unpinned as core dep and delocked in
resolve-plugins; § Coding Principles moved to a declared standard plus a
`CODING_STANDARDS.md` override socket. Cold `audit-harness-edits` ran — 8 findings
applied, harness state stamped. Tree clean, synced with origin.

DEBT-024 / DEBT-025 / DEBT-029 / GAP-039 resolved and deleted. The landing
produced three new cards: DEBT-031, DEBT-032, GAP-042.

## Next step — DEBT-031 first, then the waves

Order corrected after Wave 1 landed: the pre-landing plan put Wave 2 next, but
DEBT-031 is the only open item that leaves **shipped behavior broken for a fresh
consumer**, so it outranks throughput cleanup.

- **DEBT-031 — triage doctrine.** Bootstrap no longer installs superpowers, yet
  cluster row 8 still routes to `/super-bootstrap:triage`, whose skill description
  and `agents/triage.md:17` name `superpowers:systematic-debugging` as doctrine.
  Any repo bootstrapped after Wave 1 hits a dangling doctrine reference.
  **Behavior-shaping shipped prose** → `.claude/rules/skill-authoring.md` routes it
  through `superpowers:writing-skills` RED first, not a quick edit. That skill is
  ~105 KB plus control runs — **wants a fresh session's room**, which is why this
  one closed here.
- **Wave 2 — DEBT-027** (strip venue intent classification). Unblocks drain's
  eligibility rewrite. Check whether it subsumes DEBT-022 and BUG-019 first.
- **Wave 3 — DEBT-026** (retire `docs/superpowers/specs|plans/`). Widest consumer
  set, and it now owns the deferred naming work: `harness-bootstrap/SKILL.md`
  `description:`, the "superpowers runway" prose, and the
  `chore: scaffold|sync superpowers pipeline` commit strings — which double as the
  mature-repo bootstrap detector, so they rename once, not twice. Carries its own
  downstream migration (§8 folder hole).
- **Wave 4 — DEBT-028** (drain stage machine → interface-driven). Needs 026's path
  decision and 027's eligibility shape settled.
- **Anytime, independent:** GAP-041 (read mattpocock at grade A; gates change B).

## Watch-outs

- **`.claude/settings.json` still pins superpowers locally.** That mask hid
  DEBT-031 through a whole authoring round — the false claim shipped into a draft
  and only a cold audit caught it. Any "is the repo still coupled?" check must
  reason about a repo *without* the pin, not this one.
- **Evidence grades are load-bearing** (§7). Every mattpocock claim except the
  issue-tracker option list is grade B; two derived claims have already proved
  false mid-work after shaping full rounds of reasoning.
- **GAP-038 is blocked on change B** — held out of the cut deliberately.
- **Don't re-propose a rules-layer home for the discipline fences.**
  `docs/decisions.md` closes it, and the reason is mechanical: a `paths:` rule
  fires on file read, not on intent.
