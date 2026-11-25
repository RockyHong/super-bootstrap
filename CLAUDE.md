# super-bootstrap

Workflow doctrine — pipeline, dispatch, doc sync, git — loads from [`.claude/rules/harness.md`](.claude/rules/harness.md). This file holds the project's own sections.

## This repo's additions to the harness doctrine

These lines bind in this repo together with `.claude/rules/harness.md`; a line labelled *takes over* wins over the doctrine line it names.

**§ Development Workflow.**

- Verify on a harness-file change = `audit-harness-edits` — the envelope's verify step, § Sizing's full cold verify pass and § Doc Sync's own-harness verify pass alike.
- Cluster 7, Harness edit → `load-harness-principles` pre, `audit-harness-edits` post; this takes over the doctrine's cluster 7 row in § Cluster routing.

**§ Dispatch.**

- Added to **Build**: **A brief whose work adds or rewrites an assertion demands the bite check too** — the induced failure text verbatim in the report. Full demands (readings that must not regress, measured-spread calibration): [`dispatch-brief-demands.md`](.claude/guidelines/work-discipline/dispatch-brief-demands.md).
- **A fixture walk that commits runs headless, rooted at the fixture** — launch it as `claude -p` with the fixture as cwd, not as an in-session subagent: a subagent's commit meets this repo's `commit-channel` deny, whose route (`/super-bootstrap:commit`) commits this repo, not the fixture. Protocol: [`bench/commit-guard/README.md` § Protocol](bench/commit-guard/README.md#protocol).
- Writer run mode — criterion: `.claude/guidelines/work-discipline/dispatch-run-mode.md`; exception mechanics: `~/.claude/guidelines/claude-shape/hook-feedback-channels.md` § Background-subagent Write-create.

**§ Doc Sync.**

- Layer 2 lanes: [commit `SKILL.md`](plugins/super-bootstrap/skills/commit/SKILL.md).
- Write boundary: the release-owned manifests here are the plugin manifests. Plugin manifests → `/release`; this takes over the doctrine's "A release-owned manifest" route line.
- Write boundary, foreign-owned harness — a served copy (provenance classes: `.claude/rules/repo-boundary.md` § Finding lanes; `.claude/guidelines/**` whole: § Ownership by folder), or a file in another repo → flag the drift and route it by that rule's concern-first test: this repo's concern → `/super-bootstrap:log` here, the served copy untouched; the serving repo's → `/contribute`; this takes over the doctrine's "Foreign-owned harness" route line.

## Rules (auto-load on file match)

`.claude/rules/*.md` files attach to file reads via `paths:` frontmatter — full-body rule fires at the decision moment, zero ambient cost when irrelevant (`harness.md` aside: no frontmatter, loaded every session).

- **`dimension-discipline.md`** (placed) — fires on `docs/**/*.md`, `/README.md` (root), `plugins/*/README.md` (plus any `paths:` entries the repo appends)
  • Before editing a prose doc, classify what it owns: state (overwrite in place) vs history (append-only, git's job).
- **`ssot-doc-link.md`** (placed) — fires on `docs/**/*.md`, `/README.md` (root), `plugins/*/README.md` (plus any `paths:` entries the repo appends)
  • Link each concept to its SSOT home as you write — born-linked, not back-filled.
- **`config-overlay.md`** (served) — fires on `.claude/settings.json`, `.claude/settings.local.json`, `.claude/hooks/**`, `.mcp.json`
  • Default to upstream canonical wiring as shipped; empirically prove canonical fails before authoring an overlay, and date-stamp any overlay kept as decay debt.
  • Place ambient-behavior config at the lowest layer every target runtime loads; document parity exceptions explicitly.
- **`repo-boundary.md`** (native) — fires on `CLAUDE.md`, `CODING_STANDARDS.md`, `plugins/**`, `.claude/{rules,guidelines,hooks,skills,agents}/**`, and the skeleton-mirrored docs (`docs/{overview,techstack,decisions,terminology,parked,test-queue}.md`, `docs/{work,outward}/{README,TEMPLATE}.md`)
  • State which copy is under test (published vs in-repo dev). Route a finding by whose concern it is before whose tree holds the file — concern = must the artifact resolve in a plugin-only repo? (§ Finding lanes): concern here → `/super-bootstrap:log`, a served copy under this repo's `.claude/` included; the serving repo's → `/contribute`, never a local-clone edit.
  • Taste-coupling: dogfood harness (this repo's own CLAUDE.md/rules) may wire served guidelines; shipped skeletons (`plugins/*/skills/*/assets/**`, and the placed doctrine copy `.claude/rules/harness.md`) must be self-contained — downstream ≠ author.
  • Sync direction, two lanes by SSOT side: dogfood project prose ahead (skeleton-mirrored docs, `CLAUDE.md` project sections) → editing it pulls the shipped-skeleton counterpart into the closure (propagate stripped of dogfood-only refs, or state it's dogfood-specific); frozen asset ahead (the workflow doctrine `assets/harness.md` included) → fix the asset, refresh the placed dogfood copy byte-identical — `.claude/rules/harness.md` takes no direct edit. A re-run verifies both.
  • Ownership by folder: `.claude/guidelines/` is the storehouse's tree whole (served, clone-replaced); this repo's own material lives outside it — firing rules in `.claude/rules/`, reference in `docs/`.
- **`skill-authoring.md`** (native) — fires on `plugins/*/skills/**`
  • Skill edits route by test surface: behavior-shaping prose → RED first (micro-test floor); mechanical → audit + release checks.
- **`asset-dialects.md`** (native) — fires on `plugins/*/skills/**/*.sh`, `plugins/*/skills/**/*.py`, `plugins/*/hooks/**/*.sh`
  • Shipped shell assets and plugin-owned hook scripts: POSIX bash, portable-awk subset, fork-free inner loops; Python only for a mechanical half that outgrew shell, with a declared degrade path.

Placed = `harness-bootstrap`'s shipped rule assets, refreshed byte-identical (asset lane); served = from the personal claude-config repo (predicates in `.claude/guidelines/work-discipline/`). Add a project-specific rule file when a path-scoped pattern emerges (e.g. a SKILL.md authoring convention), then mirror a one-line summary here.

If rule body needs more context than its summary provides during planning, read the rule file directly before designing — `Read .claude/rules/<name>.md`.

## Tech Stack

Markdown-authored Claude Code plugin + self-hosted marketplace — no language runtime or build step.

→ Full stack table, dependency philosophy, architecture rules, observed coding patterns in [`docs/techstack.md`](docs/techstack.md).

## Commands

```bash
# No build system — skills/agents are markdown, loaded by Claude Code's plugin loader.
# Release (bump plugin.json version, sync marketplace description mirror, commit, tag):
/release
```

## Planning

- [`docs/overview.md`](docs/overview.md) — product context, data flow, module index.
- [`docs/techstack.md`](docs/techstack.md) — stack, architecture rules, observed coding patterns.
- [`docs/specs/`](docs/specs/) — feature specs, one `.md` per feature. Filename + heading is the catalog; no index.
- [`docs/work/`](docs/work/README.md) — open cards (`BUG` / `DEBT` / `GAP`, append-only threads), captured via `/super-bootstrap:log`, deleted on resolve; `README.md` holds the thread contract + ID shape.
- [`docs/parked.md`](docs/parked.md) — deferred items with named triggers
- [`docs/test-queue.md`](docs/test-queue.md) — manual-verification queue
- [`docs/outward/`](docs/outward/README.md) — outward threads: next move + waiting-on party, one file per item
- [`docs/terminology.md`](docs/terminology.md) — the project's term home: one canonical word per concept, `_Avoid_` aliases; a doc's first substantive use of a term links this file.
- [`docs/decisions.md`](docs/decisions.md) — closed forks, all domains (history dimension). See its scope header for admission criteria; checked at triage.
- `.claude/rules/` — path-scoped rules, full-body fires on file match (see Rules section above)

> `docs/specs/` = permanent source of truth; working design and plan live as blocks on the owning card's thread.
