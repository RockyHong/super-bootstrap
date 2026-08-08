# mattpocock Coexistence — Operator Runbook

Operating posture for running [mattpocock/skills](https://github.com/mattpocock/skills) alongside super-bootstrap on the operator's own repos. The seam analysis — why composition is bounded to these surfaces, why the middle is human-typed only — lives in [`harness-architecture.md`](harness-architecture.md) §4; the coexistence decision in §6. This doc is the how-to: install, tracker recipe, lane picks, watch list.

**Posture: device-level unify.** The plugin installs user-scoped once and is visible in every repo; splitting back to per-repo opt-in later is a per-repo disable, no doc change. `plugins/super-bootstrap/` still references mattpocock nowhere — the [§4 grep contract](harness-architecture.md#4-the-seam-runtime-orthogonal-setup-time-composed) is untouched, and shipped skeletons stay bare. This runbook and an operator repo's own CLAUDE.md may name his commands; the shipped skeleton must not (`.claude/rules/repo-boundary.md` taste-coupling).

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

Do **not** pre-create `docs/agents/*` — his setup owns those files and carries no skip guarantee for pre-existing ones.

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
- His model-invoked discipline layer firing inside sb-dispatched subagents (doctrine injection into build containers) — unverified.
- His lane committing outside the commit door — worst case one missed doc-sync scan; observe, then decide whether an overlay earns its slot (trust-upstream-defaults: canonical first).
- Field-shape breaks — where his skills actually need `Type:`/`Blocked by:` the recipe declares away.
- His set's ambient token weight — measure at first install.
