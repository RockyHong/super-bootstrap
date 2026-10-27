# GAP-jsp5 — take over the `ssot-doc-link` rule from claude-config-manager and ship it

**Logged:** 2026-10-27 · **Source:** user — CCM is a dogfood storehouse; graduated artifacts move to their SSOT owner
**Problem:** The commit door's doc-sync guarantee (a restated fact reaches its SSOT home in one hop) rests on the `ssot-doc-link` rule, and `doc-links.sh` plus the doc-sync restatement count assume it. The rule reaches this repo only as a CCM-served copy (`.claude/rules/ssot-doc-link.md` + `.served` sidecar), and harness-bootstrap ships no counterpart, so a plugin-only consumer runs doc-sync without the discipline it rests on. By the consumer-resolvability test (`.claude/rules/repo-boundary.md` § Finding lanes) the rule is this repo's concern. The served body also points at `.claude/guidelines/work-discipline/doc-link-discipline.md`, which a consumer repo lacks, so the shipped copy must carry its predicate self-contained.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/` (new rule skeleton + placement row), `.claude/rules/ssot-doc-link.md` (served → placed dogfood copy, sidecar removed), root `CLAUDE.md` § Rules provenance line
**Prior:** precedent — the doc-consult hook absorb (`docs/decisions.md` closed-fork row "super-bootstrap absorbs the CCM-planted doc-consult hook"): sb ships, then CCM retires its copy with no coverage gap. CCM handoff: `OUT-2e1a`. Feeds `GAP-ym4e`'s authoring-time term registration, which extends this rule.

## Amendment — 2026-10-27 · gateway

`dimension-discipline` is the same case: `doc-links.sh` and the doc-sync scan treat `dimension: history` frontmatter as frozen provenance, and only that rule tells an author to declare it; the shipped CLAUDE.md skeleton carries the routing summary, not the classify step, the frontmatter declaration or the tripwire. Proposed to CCM as a second takeover; `config-overlay` sent as an open question (no sb dependency, but it fires on harness-bootstrap's settings/hook output). Rulings return on `OUT-2e1a`.

## Amendment — 2026-10-27 · CCM reply note (`OUT-2e1a`)

Scope settled: ship `ssot-doc-link` and `dimension-discipline` together, built from the served copies as they stand — CCM confirms they match its sources byte for byte. `config-overlay` stays out (storehouse-owned). After the release lands, the author notifies CCM so it retires its copies.

## Verdict — auto-fix · 2026-10-27

**Fix-shape:** systematic
**Probe-deps:** none
**Execution:** phased(skip: design-settle) — depth: an existing codified pattern (always-placed rule asset, like `rules-index-skeleton.md`) plus the self-containment rule applied to two new instances, bodies transcribed from CCM-confirmed sources; closure: ~6 harness surfaces incl. ambient-loaded `CLAUDE.md` + the shipped skill body, so a written plan + build dispatch + `audit-harness-edits`, not inline

### Repro (pinned)

"The rule reaches this repo only as a CCM-served copy (`.claude/rules/ssot-doc-link.md` + `.served` sidecar), and harness-bootstrap ships no counterpart, so a plugin-only consumer runs doc-sync without the discipline it rests on." Amendment: "`doc-links.sh` and the doc-sync scan treat `dimension: history` frontmatter as frozen provenance, and only that rule tells an author to declare it; the shipped CLAUDE.md skeleton carries the routing summary, not the classify step, the frontmatter declaration or the tripwire."

### Root cause (verified)

premise age: clean — no commit touched `plugins/super-bootstrap/skills/harness-bootstrap/assets/`, either rule, or `CLAUDE.md` since 2026-10-27.

- Gap confirmed: `harness-bootstrap/assets/` holds rule skeletons `rules-index`, `rules-frontend`, `rules-mv3` only; no `ssot-doc-link` / `dimension-discipline` counterpart. `SKILL.md:339-341` (§ 2b asset table) and `:231` (§ 2a rules machinery) place none.
- Dependency confirmed: `commit/assets/doc-links.sh:76,123,627`, `commit/SKILL.md:19,23`, `agents/doc-sync-scan.md:23`, `commit/assets/restatement-predicate.md:27`, `harness-bootstrap/SKILL.md:454` (rot-scan skip) all key on `dimension: history` or the `ssot-doc-link` link-on-asserting-line shape. `docs/decisions.md:45,52` lean on `ssot-doc-link`'s declared-supersession case as the structural carrier for a closed scanner class — a consumer without the rule loses that carrier.
- Self-containment gap confirmed: both served bodies (`.claude/rules/ssot-doc-link.md:14-16`, `.claude/rules/dimension-discipline.md:31-32`) and their `description:` frontmatter cite `.claude/guidelines/work-discipline/{doc-link,doc-dimension}-discipline.md`, which violates `repo-boundary.md` § Taste-coupling for a shipped skeleton. The rules' load-bearing content lives in that lore: the four-guard link-candidate predicate, home-selection edges, and placement (`doc-link-discipline.md`), and the classify / route 1-5 / audit predicate (`doc-dimension-discipline.md`).
- Aim: CCM ruled on scope (`OUT-2e1a` reply amendment): ship both rules and keep `config-overlay` out. No overlapping open card. `GAP-ym4e` consumes this card (its authoring-time registration extends `ssot-doc-link`; its "ownership to settle at Design" fork resolves to "this repo's own rule" once this card ships). No closed fork in `docs/decisions.md` re-walked — the doc-consult absorb row (`:62`) is the matching precedent.
- Settled implementation calls (each cited, none is user judgment):
  - **Always-placed, not signal-gated.** The doc-sync gate these rules feed runs in every runway repo (CLAUDE.md skeleton § Doc Sync), so the rules follow the `index.md` placement row ("Always").
  - **Whole-body frozen asset, no placeholders.** The body is generic, so drift is checked like `AGENTS.md`. Grown content below the scaffold stays project-owned (`SKILL.md:184`).
  - **Self-contained by inlining.** Fold each lore file's predicate sections into its rule body: link-candidate guards 1-4, home edges and placement into `ssot-doc-link`; classify, route 1-5 and audit shapes into `dimension-discipline`. Drop every `.claude/guidelines/` path, the `doc-dimension-ssot` axiom name, and the "consumer artifacts cite this file by path" boundary lines. `rules-index-skeleton.md` ("body is imperative and full-detail") rules this form over a second shipped lore file. `/super-bootstrap:check-docs-consistency` is plugin-resolvable and may stay cited.
  - **Dogfood swap sequencing.** `OUT-2e1a` § Repo tail rules the order: "the dogfood copy drops its `.served` sidecar once CCM stops serving". Until then the served dogfood copy stays. Dogfood may taste-couple (`repo-boundary.md`), and an in-place edit of a served file is barred. The dogfood copy is replaced with the byte-identical shipped asset (asset lane) on the `OUT-2e1a` tail, not in this card's build.

### Files (fix surface)

- `plugins/super-bootstrap/skills/harness-bootstrap/assets/rules-ssot-doc-link-skeleton.md` (new) — self-contained rule. Frontmatter `paths:` is the same as the served copy. The `description:` is rewritten without the lore path. The body is the served rule + the inlined `doc-link-discipline.md` predicate / home edges / placement.
- `plugins/super-bootstrap/skills/harness-bootstrap/assets/rules-dimension-discipline-skeleton.md` (new) — the same treatment from the served `dimension-discipline.md` + `doc-dimension-discipline.md` (classify, route, audit, tripwire, `dimension: history` declaration).
- `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:203-214,231` — § 2a always-created tree + rules-machinery sentence name the two always-placed rules.
- `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:339-341` — § 2b asset table: two "Always" rows.
- `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:171-172` — § Pipeline-owned: the two rule bodies drift-checked whole against their assets.
- `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:505` — § Rules fill instruction. Today it drops the example bullets "when no signal-seeded rule file landed", and `index.md` takes no bullet. The two new rules always take bullets, so reword this line.
- `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:590-591` — § 2c staged-file list.
- `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md:113-127` — § Rules: two unbracketed shipped bullets (glob + key points), above the bracketed example scaffolding.
- `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md:62` — prose lane, dogfood ahead: dogfood `CLAUDE.md:63` carries "(`ssot-doc-link` rule)" and the skeleton omits it. This card makes it consumer-resolvable, so propagate it. Optionally do the same for the § Doc Sync dimension-routing lead line (`:78`) pointing at `dimension-discipline`.
- `CLAUDE.md:117-125` (dogfood § Rules) — fix the provenance line "First three served from the personal claude-config repo …" in this card only if the dogfood swap lands in this card. Otherwise it belongs to the `OUT-2e1a` tail, with the bullets re-labelled as placed from harness-bootstrap and only `config-overlay` served.
- Not edited here: `.claude/rules/{ssot-doc-link,dimension-discipline}.md{,.served}` are served (`.served` sidecar). Swap them on the `OUT-2e1a` tail after CCM retires. CCM-side retirement of both rules and both lore files belongs to CCM, and the author carries it per `OUT-2e1a`. No edit here or in a CCM clone.

### Doc Impact

- `plugins/super-bootstrap/README.md` — check its harness-bootstrap output enumeration (if it lists placed rule files) and add the two rules.
- `docs/overview.md:76` (Shipped-skeleton self-containment) — confirmed unchanged: the rule is stated generically. `:78` (Frozen-asset install contract) lists hook/autorun ensure-infra assets, not rule skeletons — confirmed unchanged.
- `docs/specs/harness-architecture.md` — rules-layer prose (`:189-225`) is mechanism-generic — confirmed unchanged.
- `docs/outward/OUT-2e1a.md` — on release, the author's release-landed note fires; the thread's next move updates (append, not rewrite).
- Release: `/release` bump (shipped assets + skill body change).
- Mention, not a fix: on a CCM-served consumer repo, a harness-bootstrap re-run between this release and CCM's retirement meets the served file at the same path and raises it as `⚠ drifted`. The author resolves this by declining until CCM retires. The window is transient and author-only.

### Test Strategy: unit

- Self-containment assertion: grep both new assets for `.claude/guidelines`, `work-discipline`, `axiom` — expect zero hits. The bite check: run it against the served copies first and expect hits.
- Cold dry-run (`skill-authoring.md` contract-shaped / behavior-shaping floor): in a plugin-only fixture with no `.claude/guidelines/`, a fresh agent gets each shipped rule body plus a sample doc edit and applies the rule (pick link homes / classify a dimension and declare `dimension: history`). Every lore lookup it attempts, or every guess it makes, is a gap to patch.
- `audit-harness-edits` on the diff (ambient `CLAUDE.md` skeleton + shipped skill body).

## Plan — 2026-10-27

Fix surface and settled calls: the Verdict above (author == executor session; steps reference it, no file bodies embedded).

1. Build (one dispatch): the two new rule skeletons, self-contained by inlining each lore predicate; `harness-bootstrap/SKILL.md` §§ 2a / Pipeline-owned / 2b / Rules-fill / 2c rows; `claude-md-skeleton.md` § Rules bullets + the line-62 rule mention; plugin README check. Bite check: the self-containment grep hits the served copies, then returns zero on both new assets.
2. Gateway verify: re-read the diff against the Verdict's file list and settled calls.
3. Cold dry-run: a fresh agent per shipped rule, given only the rule body and a sample doc edit in a plugin-only fixture; any lore lookup or guess is a gap to patch.
4. `audit-harness-edits` on the diff.
5. Doc-sync + `/super-bootstrap:commit`; `/release` follows. The dogfood swap and the `CLAUDE.md` § Rules provenance line stay on the `OUT-2e1a` tail.

## Progress — 2026-10-27

Plan steps 1–4 done: both shipped rule skeletons built and placed by harness-bootstrap (always, whole-body drift-checked), cold dry-run gaps patched (multi-home tiebreak, contradiction log route, description wording), `audit-harness-edits` dispositioned. Remaining: `/release`, then the `OUT-2e1a` tail (author's release-landed note to CCM; dogfood swap of both served rules once CCM retires them).
