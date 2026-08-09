# mattpocock Coexistence — Operator Runbook

Operating posture for running [mattpocock/skills](https://github.com/mattpocock/skills) alongside super-bootstrap on the operator's own repos. The seam analysis — why composition is bounded to these surfaces, why the middle is human-typed only — lives in [`harness-architecture.md`](harness-architecture.md) §4; the coexistence decision in §6. This doc is the how-to: install, tracker recipe, lane picks, watch list.

**Posture: paired, device install + per-repo enable.** The plugin installs once at device scope and sits **disabled** there; enabling is per repo. It is not an opt-in pick — super-bootstrap and mattpocock/skills ship paired, and bootstrap performs the per-repo enable alongside the wiring ([`GAP-056`](../work/GAP-056.md) carries that build; until it lands, the enable and the steps below are run by hand). Pairing is not hard coupling: sb's own doors never depend on his lane, and a repo drops him with a per-repo disable, no doc change. Until `GAP-056` lands, `plugins/super-bootstrap/` references mattpocock nowhere — the [§4 grep contract](harness-architecture.md#4-the-seam-runtime-orthogonal-setup-time-composed) is untouched, and shipped skeletons stay bare. This runbook and an operator repo's own CLAUDE.md may name his commands; the shipped skeleton must not (`.claude/rules/repo-boundary.md` taste-coupling).

## Install

Once per device:

```
/plugin marketplace add mattpocock/skills
/plugin install mattpocock-skills@mattpocock
```

Once per repo (after `harness-bootstrap` has run — the log door and `docs/work/` must exist):

1. Run `/setup-matt-pocock-skills`.
2. At the issue-tracker question pick **Other**.
3. Paste the recipe below as the workflow description.

His setup owns `docs/agents/*` — never hand-create them ahead of it. Where a prior run already wrote them (this repo included), his skill is silent on pre-existing files, so a re-run may overwrite: diff before accepting.

## The tracker recipe

Paste verbatim at the "Other" prompt:

> Issues live as card files at `docs/work/{ID}.md`, one file per issue, ID in the form `BUG-###`, `DEBT-###`, or `GAP-###` (feature ideas are GAP). `docs/work/README.md` and `TEMPLATE.md` are contract files, not issues.
>
> - **Publish** a new issue by invoking `/super-bootstrap:log <observation>` — never write a card file directly; the log door assigns the ID.
> - **Fetch** open issues by listing/reading `docs/work/*.md`. A card file present = open; there is no Status field.
> - **Comment** by appending an `## Amendment — {date}` block to the card. Cards are append-only threads — never rewrite earlier blocks.
> - **Resolve** by deleting the card file. Git history is the archive.
> - Cards carry no `Type:` or `Blocked by:` fields — express type and blocking relationships in the card's prose body.
> - Before filing an enhancement, check `docs/decisions.md` for a previously rejected direction (it is this repo's `.out-of-scope/` superset).

## Lane picks per work shape

The two ends stay super-bootstrap's — capture via `/super-bootstrap:log`, commits via `/super-bootstrap:commit` (doc-sync rides it). The middle is his lane, human-typed (his user-invoked layer is model-unreachable — [§4](harness-architecture.md#4-the-seam-runtime-orthogonal-setup-time-composed)). His per-shape paths are catalogued in [§7](harness-architecture.md#7-evidence-index); the sb-side chaining:

| Work shape | Chain |
|---|---|
| Bug with a runtime | `/super-bootstrap:triage` grounds the card (verdict) → human types `/diagnosing-bugs` for the red-loop fix |
| Bug, no runtime (docs/harness) | sb lane whole — triage verdict → implement → commit door |
| Fuzzy feature | `/grill-me` → `/to-spec` → `/to-tickets` → `/wayfinder` → `/implement`; resulting tickets land through the recipe above |
| Maintenance / debt sweep | `/improve-codebase-architecture` (proposes only) → picks feed `/super-bootstrap:log` |
| Inbox / external PR sorting | his `/triage` (label state machine); per-card grounding stays `/super-bootstrap:triage` — name collision, different work |

## Watch list

Friction observed in live runs is logged as cards via `/super-bootstrap:log`, per [§6](harness-architecture.md#6-decided-vs-open)'s live-adoption-is-the-trial. Known open questions ([§7 carried questions](harness-architecture.md#7-evidence-index)):

- Head-contract content — what a hand-off into his lane must carry; read out of the first live hand-off, interface work waits on it.
- His model-invoked discipline layer firing inside sb-dispatched subagents (doctrine injection into build containers) — live surface at v1.2.3: `tdd`, `code-review`, `grilling`, `diagnosing-bugs`, `domain-modeling` and 6 more are model-invocable; behavior unobserved. Count the manifest, not the tree — his `plugin.json` registers 25 of the repo's 35 `SKILL.md`, and an explicit `skills` array is an allowlist, so the 10 unregistered folders (4 of them model-invocable) never load.
- His lane committing outside the commit door — worst case one missed doc-sync scan; observe, then decide whether an overlay earns its slot (trust-upstream-defaults: canonical first).
- Field-shape breaks — where his skills actually need `Type:`/`Blocked by:` the recipe declares away.
