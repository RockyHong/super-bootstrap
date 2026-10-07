# DEBT-126 — triage's cold-dispatch requirement vs the warm session's first-hand information

**Logged:** 2026-10-07 · **Source:** `/read-notes` handoff from `D:/Git/rocky-personal-assist` (distillation of 402 Claude Code sessions across 7 repos, Sept–Oct 2026)
**Problem:** The triage lane requires grounding to run cold in a dispatched subagent (`skills/triage/SKILL.md` § Rules — "Dispatch, don't investigate. The verdict judgment runs in the subagent's clean context; gateway priors corrupt it."). In two sessions the user overruled that requirement on the spot, and his stated mechanism is not "grounding is unnecessary" but "the warm session holds first-hand information the cold one will not have, and the cold one can return a different reading". The rule and what the user actually guards are not the same requirement.
**Area:** `plugins/super-bootstrap/skills/triage/SKILL.md`; `plugins/super-bootstrap/agents/triage.md`; `docs/decisions.md` row 48; root `CLAUDE.md` § Sizing, § Dispatch
**Blast:** repo
**Prior:** The sending session's framing, held as a hypothesis — the gap is between the decision's *shape* (triage as a mandatory separate cold phase) and the invariant the user guards (grounding happens; warm context is not thrown away). It names three candidate shapes with no recommendation: relax the mandatory-separate-phase requirement and state the real invariant · keep the rule and make the hop cheap enough (triage inline while warm) · record a named carve-out for a warm session holding first-hand information.

## Amendment — 2026-10-07 · verbatim evidence (note dropped at log, so it is preserved here)

The user's own words, as the distillation quoted them:

- `0ca1b1#2` — 「不用triage，一直丟皮球，你來做」 — said while the agent was citing this repo's own `docs/decisions.md` closed fork as the reason to route through triage; overruled in the same turn.
- `0ca1b1#3` — 「審完直接 commit 然後 push」
- `4804b0#3` — 「context warm這裡可以做?不然新session triage又有新的可能不同的看法，但API是claude第一手的資訊。」

What the corpus does **not** show: any rejection of the premise-verification triage exists to do.

## Amendment — 2026-10-07 · scope boundary against `docs/decisions.md` row 48

Row 48 closed a **different** fork: "Relax 'triage is every card's pickup' for self-logged, evidence-grounded, mechanically-shaped cards" — i.e. skipping grounding. Its ground was `DEBT-068`: a warm self-logged card carrying `file:line` and verbatim quotes, where cold triage still returned two findings the card missed, one fix-changing. Its reopen condition is "a card where skipping triage demonstrably costs nothing and the verdict returns empty-handed" — **not met by this card's evidence**.

This card's axis is *where grounding runs* (warm inline vs cold dispatch), not *whether* it runs. Row 48's evidence bears on it (it is the live cost estimate for warm-context grounding) but does not close it.

## Amendment — 2026-10-07 · adjacent finding, same corpus, no action implied

Four experiments tested whether handing an agent a document describing the user's judgement makes it predict his pushback. All four came back negative against pre-registered criteria. What did change agent behaviour was a mechanical check at a boundary, not instruction prose. Bears on the fix shape: if a resolution wants an agent to "remember to ground before skipping", that is the shape that failed 4/4; a gate is the shape that worked.

## Verdict — surface · 2026-10-07

**Container provenance (declared, because this card's own subject is container choice):** this verdict was produced **warm, gateway-inline**. The cold `triage` dispatch was launched and the user stopped it mid-run — the third instance of the behavior the card documents, and the reason the cold lane produced nothing here. A warm gateway judging a card about whether warm gateways may judge is a self-serving configuration; it is named rather than hidden, and every claim below cites a read surface so the grounding is auditable without trusting the container.

### Findings

- **premise age:** 9 commits touched the Area paths since 2026-09-01. One is load-bearing: `9454187` *fix(agents): triage inherits the session model (DEBT-113)* — the triage agent runs `model: inherit`, so cold triage and the warm gateway are **the same tier**. The tier axis between the two containers is already equalized; container is the only remaining variable.
- **premise confirmed, verbatim.** Cold dispatch is stated unconditionally on four surfaces: `skills/triage/SKILL.md:3` (description), `:9` (body), `:31` (§ Rules — "Dispatch, don't investigate. The verdict judgment runs in the subagent's clean context; gateway priors corrupt it"), and the SSOT — `shared/grounding-discipline.md` rule 1, "Judge cold. Your evidence surface is the repo and the item's cited artifacts, **never the dispatching conversation**." No surface carries a warm branch or a carve-out.
- **the SSOT is shared by four doors, not one.** `shared/grounding-discipline.md` is self-read by `agents/triage.md`, `agents/triage-report.md`, `agents/review-intake.md`, `agents/premise-closure.md` (grep-confirmed). Editing rule 1 changes all four. Triage alone cannot be relaxed at the SSOT — only at its own door.
- **the repo already shipped the fix shape, for a different door, on a measurement.** `docs/decisions.md` row 41 closed the direction "keep the commit door's doc-sync judgment in an unconditional cold dispatch": a 15-arm controlled read-out with diff + scan scope fixed and container varied found the cold-eyes premium **reversed by work class** — cold Sonnet took the mechanical roster key 2/3 but cleared the posture **judgment** fork 0/3; warm (held state) inverted it, judgment fork 2/3, roster 0/3; an Opus control named both keys 3/3, so **tier dominates container**. Shipped: warm gateway-inline default, cold dispatch retained **solely as the scope-overload valve**. `agents/doc-sync-scan.md:3` encodes it — "This body's § Scan is the shared procedure for both lanes" — and that agent is notably **absent** from `grounding-discipline.md`'s door list: the one door whose judgment moved warm also left the cold-judge spec.
- **the two existing N=1 data points on the triage lane itself fall on opposite sides, and both match row 41's split.** `docs/decisions.md` row 48 (`DEBT-068`): a warm self-logged card carrying `file:line` and verbatim quotes, where cold triage still returned two findings the card missed — a whole-token grep that also hit the pre-rename command form, and a seventh occurrence outside the carded inventory. **Both misses are enumeration/roster class, not judgment class** — exactly where row 41 measured cold winning. This session is the mirror case on the judgment side: the fork's resolution turned on a cross-door precedent read (`doc-sync-scan`'s dual-lane shape + row 41's arms), which is held-context judgment work.
- **scope reach:** `skills/triage/SKILL.md` (description + body + § Rules), `agents/triage.md` (description + § Phase identity write boundary), `shared/grounding-discipline.md` rule 1 **if** the change goes to the SSOT (pulls `triage-report`, `review-intake`, `premise-closure` into the closure), root `CLAUDE.md` § Dispatch + § Cluster routing row 8, `docs/specs/harness-architecture.md`, `docs/decisions.md` (row 48 gains a boundary note either way). Harness prose → `.claude/rules/skill-authoring.md` puts a behavior-shaping change behind a RED micro-test floor; row 41's own bench (`bench/doc-sync/SCORING.md`) is the shipped precedent for the arm shape.
- **attempted:** premise-age sweep, the four enforcing surfaces read verbatim, grep for every door instantiating the shared spec, `decisions.md` rows 41 + 48 read in full, `doc-sync-scan.md` dual-lane wording confirmed. Stopped at the measurement: no bench was run, because the evidence count is the fork (below).

### Decision needed

Row 48 does **not** close this card — it closed *skipping* grounding, this card is *where grounding runs* — but row 41 does not close it either: that measurement ran on the doc-sync door, whose work class and scope-enumeration shape differ from card grounding. The fork is what the repo's own two-instances-make-a-class bar permits **now**:

- **A — split triage by function class, citing row 41 + row 48.** Judgment (premise verify, aim validate) runs warm gateway-inline; enumeration (blast collect, family sweep, duplicate grep) stays cold-dispatched or is mechanized. One procedure body, two containers — `doc-sync-scan`'s shipped shape. Buys the user's stated want (warm first-hand info kept, no ball-passing hop) and keeps the only class where cold has measured and observed wins.
- **B — warm-inline default with a cold valve, no function split.** Flip the door the way the commit door flipped: warm by default, cold dispatch retained for scope overload or when the gateway holds a fix prior it cannot set aside. Simpler surface; accepts row 48's enumeration misses as the known cost.
- **C — hold the rule, record the carve-out only.** Keep cold mandatory, add a named exception for a session holding first-hand information, and a `docs/decisions.md` boundary note separating this axis from row 48. Cheapest diff; leaves the overrule friction in place, which is what produced three instances.
- **D — build the arm bench first, change nothing yet.** Re-run row 41's arm shape against the triage lane (warm vs cold × judgment vs enumeration) and decide on the read-out. Honest, and the only option that does not generalize another door's measurement onto this one.

- **recommendation: A.** It is the option every read surface already points at: row 41 measured the split directly and shipped it, `doc-sync-scan` proves the one-body-two-containers shape works in this codebase, row 48's two misses are both on the side A keeps cold, and `9454187` removed the tier confound that could otherwise explain row 41's result away. It also matches what the evidence says the user guards — grounding happens, warm context is not thrown away — rather than what he refused, the information-free hop. **Against A, honestly:** it generalizes a doc-sync measurement onto the triage door, and the function split is a new boundary no measurement has tested as a *split*. If that generalization is not acceptable, D is the correct answer and A is premature.
- **settles by:** `docs/decisions.md` row 41 (the container-by-work-class measurement) + row 48 (the enumeration-side N=1 on this door) settle A's *direction*; what they do not settle is whether one door's bench transfers to another, which is a risk call on evidence strength — **user authority**. If the ruling wants that transfer measured rather than assumed: `phased build` — row 41's arm harness (`bench/doc-sync/SCORING.md`) re-pointed at the triage lane, fixtures + arms as a `## Plan` block, then dispatch. Option C additionally needs no measurement at all and is available as the hold-position at any time.

## Amendment — 2026-10-07 · premise demoted, two scenarios separated (user, in-session)

The card merged two different problems under one axis. They are separated here, and this card keeps only the minor one.

**Scenario A — cross-repo ownership round-trip (the real problem).** super-bootstrap and claude-config-manager form different views of which repo a problem belongs to, so the item round-trips between them through `/send-issue` and `/contribute`. Successor card owns it: see `GAP-100`.

**Scenario B — same-project re-triage (this card).** A cold session re-grounds a card the warm session already ground, and can return a different reading. User's ruling: **事小** — real but low-value.

**Evidence re-attributed.** All three verbatim quotes in this card's first Amendment belong to **Scenario B**, not A. The `0ca1b1#2` 「一直丟皮球」 ball was passed to this repo's own cold triage subagent — the sending note itself records the agent citing this repo's `docs/decisions.md` at that moment — not to another repo. Scenario A has zero verbatim evidence in this card; its evidence is in the repo record instead (`docs/decisions.md` rows 39 / 40 / 61), collected on `GAP-100`.

**What this card's Verdict still holds.** The `surface` verdict above is grounded and stays valid for Scenario B: the rules-1-vs-2 collision in `shared/grounding-discipline.md` is real (rule 1 excludes conversation-held content by channel, rule 2 ranks raw observation as top-rank evidence), and the four options remain the fork. It is parked at that verdict by the 事小 ruling — not resolved, not dropped.

**Invariant the user stated for Scenario B**, recorded for whoever picks this up: evidence-backed grounding should not be overturned by a re-run; a re-run that returns a different reading means the evidence was never landed in a checkable form.
