# mattpocock Coexistence — Operator Runbook

Operating posture for running [mattpocock/skills](https://github.com/mattpocock/skills) alongside super-bootstrap on the operator's own repos. The seam analysis — why composition is bounded to these surfaces, why the middle is human-typed only — lives in [`harness-architecture.md`](harness-architecture.md) §4; the coexistence decision in §6. This doc is the how-to: install, tracker recipe, lane picks, watch list.

**Posture: paired, device install + per-repo enable.** The plugin installs once at device scope and sits **disabled** there; enabling is per repo. It is not an opt-in pick — super-bootstrap and mattpocock/skills ship paired, and `harness-bootstrap` §2a seeds the per-repo enable as a [**paired pin**](../techstack.md#key-dependencies): unconditional like a core dep, droppable unlike one. Pairing is not hard coupling: sb's own doors never depend on his lane, and a repo drops him by flipping the pin to `false`, no doc change. `plugins/super-bootstrap/` names him only at setup-time — the §2a pin entry with its marketplace, the tracker-recipe asset, and the first-run handoff string — and at zero runtime sites; the [§4 grep contract](harness-architecture.md#4-the-seam-runtime-orthogonal-setup-time-composed) is what holds that boundary and enumerates the sanctioned hits. This runbook and an operator repo's own CLAUDE.md may name his commands; the shipped skeleton must not (`.claude/rules/repo-boundary.md` taste-coupling).

## Install

Device scope, once — install, then leave it **disabled** there so every enable is a deliberate per-repo one:

```
/plugin marketplace add mattpocock/skills
/plugin install mattpocock-skills@mattpocock
```

Per repo, `harness-bootstrap` §2a owns the enable: it seeds `"mattpocock-skills@mattpocock": true` into `.claude/settings.json` plus the `mattpocock` → `mattpocock/skills` entry in `extraKnownMarketplaces`, on a fresh scaffold and on any re-sync of a repo that predates the pairing. Its first-run handoff names his commands and hands over the two steps a model cannot take — his user-invoked layer is model-unreachable ([§4](harness-architecture.md#4-the-seam-runtime-orthogonal-setup-time-composed)), so these are typed by hand after the runway is in place:

1. Type `/setup-matt-pocock-skills`.
2. At its issue-tracker question pick **Other**, then paste the recipe (below) as the workflow description.

His setup owns `docs/agents/*` — nothing pre-writes them, here or downstream. Where a prior run already wrote them (this repo included), his skill is silent on pre-existing files, so a re-run may overwrite: diff before accepting.

To drop him in a repo, set the pin to `false` — never delete the key. §2a merges absent keys back in on every sync; a present `false` is skipped, so the drop survives.

## The tracker recipe

Single source: [`assets/mattpocock-tracker-recipe.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/mattpocock-tracker-recipe.md), shipped with `harness-bootstrap`. Paste its block verbatim at the **Other** prompt — never a hand-typed variant, and never a second copy kept elsewhere; the asset marks which of its clauses his skills actually act on.

This repo pastes it unmodified. The asset was generalized from this repo's declaration and already names `docs/work/` and `/super-bootstrap:log`, so there is nothing repo-specific left to adapt. What his setup writes from it lands at [`docs/agents/issue-tracker.md`](../agents/issue-tracker.md) — that file is his output, not the source; re-paste from the asset.

## Lane picks per work shape

The two ends stay super-bootstrap's — capture via `/super-bootstrap:log`, commits via `/super-bootstrap:commit` ([doc-sync](../../CLAUDE.md#doc-sync-non-negotiable) rides it). The middle is his lane, human-typed (his user-invoked layer is model-unreachable — [§4](harness-architecture.md#4-the-seam-runtime-orthogonal-setup-time-composed)). His per-shape paths are catalogued in [§7](harness-architecture.md#7-evidence-index); the sb-side chaining:

| Work shape | Chain |
|---|---|
| Bug with a runtime | `/super-bootstrap:triage` grounds the card (verdict) → human types `/diagnosing-bugs` for the red-loop fix |
| Bug, no runtime (docs/harness) | sb lane whole — triage verdict → implement → commit door |
| Fuzzy feature | `/grill-me` → `/to-spec` → `/to-tickets` → `/wayfinder` → `/implement`; resulting tickets land through the recipe above |
| Maintenance / debt sweep | `/improve-codebase-architecture` (proposes only) → picks feed `/super-bootstrap:log` |
| Inbox sorting | his `/triage` (label state machine) over the [config-declared tracker](../agents/triage-labels.md#the-two-triage-lanes) — here the card files; GitHub-side requests enter via `/pull-issue`, not his lane; per-card grounding stays `/super-bootstrap:triage` — name collision, different work |

## Watch list

Friction observed in live runs is logged as [cards](../work/README.md#routing) via `/super-bootstrap:log`, per [§6](harness-architecture.md#6-decided-vs-open)'s live-adoption-is-the-trial. Known open questions ([§7 carried questions](harness-architecture.md#7-evidence-index)):

- Head-contract content — what a hand-off into his lane must carry; read out of the first live hand-off, interface work waits on it.
- His model-invoked discipline layer firing inside sb-dispatched subagents (doctrine injection into build containers) — live surface at v1.2.3: `tdd`, `code-review`, `grilling`, `diagnosing-bugs`, `domain-modeling` and 6 more are model-invocable; behavior unobserved. Count the manifest, not the tree — his `plugin.json` registers 25 of the repo's 35 `SKILL.md`, and [an explicit `skills` array is an allowlist](../techstack.md#framework), so the 10 unregistered folders (4 of them model-invocable) never load.
- His lane committing outside the commit door — worst case one missed doc-sync scan; observe, then decide whether an overlay earns its slot (trust-upstream-defaults: canonical first).
- Field-shape breaks — where his skills actually need `Type:`/`Blocked by:` the recipe declares away.
