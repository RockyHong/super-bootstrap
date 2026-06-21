# Work Discipline — Tier 1 Subcategory

Universal principles for how Claude behaves at the work moment — tool-use safety, doc/info hygiene, AI-product integration patterns, cross-cutting craft rules.

Part of the `.claude/guidelines/` Tier 1 tree. The sibling subtrees — `axiom-principles/` (timeless principles) and `claude-shape/` (current factual snapshot) — are device-planted to `~/.claude/guidelines/`, not served into consumer projects.

## Principles

| Principle | Summary | File |
|---|---|---|
| Doc Impact mirror | Work-scope artifact lists adjacent docs that may need updates. Implementer mirrors or records "confirmed unchanged." Anti-drift at change-time. | [`doc-impact-mirror.md`](doc-impact-mirror.md) |
| Edit discipline (renames & replace-all) | `replace_all` is naive whole-file string replace; corrupts on common identifiers. LSP-first preference order, banned-terms list, pre-flight checklist, slip-through recovery. | [`edit-discipline.md`](edit-discipline.md) |
| Trust upstream defaults | Default = upstream canonical wiring as shipped. Empirically prove canonical fails before authoring downstream overlay; date-stamp every overlay as decay debt. Applies to plugins, MCPs, SDKs, framework presets, library defaults. | [`trust-upstream-defaults.md`](trust-upstream-defaults.md) |
| Runtime parity | Place ambient-behavior config at the level where every target runtime loads it. Name runtimes, identify their loading layers, pick the lowest-common layer. Document parity exceptions explicitly when intentionally placing in a partial-coverage layer. | [`runtime-parity.md`](runtime-parity.md) |
| Model tiering | Unspecified `agent()` model inherits the main-loop tier; cost scales with fan-out width. Pre-launch tier audit (small retrieves / mid judges / top thinks), centrality amplifier (direction-setting steps tier to top regardless of own shape), width axis (tier pins cap unit price, fan-out constants cap volume), named-launch corollary (scriptPath via local copy; stop-first when none), resume cache-key corollary. | [`model-tiering.md`](model-tiering.md) |
| Path portability | Context-loaded docs express filesystem locations portably — never hardcoded absolute machine paths (a clone/relocation mis-primes every reader). Relativize, don't re-absolutize. Canonical conventions block; setup-doc carve-out. | [`path-portability.md`](path-portability.md) |
| Scan-tracker annotation | Post-analysis layer cross-references scan findings against a project tracker — never a filter. Overlap→tag vocabulary, delete-on-close git-log verification, annotate-ambiguous-anyway. Invoking skill supplies its domain index targets + report section. | [`scan-tracker-annotation.md`](scan-tracker-annotation.md) |
| Scan workflow fan-out | Sizing pre-flight (four filesystem proxies) feeds an escalation ladder: rung 1 inline solo (default), rung 2 fan-out readers + barrier judge, rungs 3–5 named-deferred. Attention-fit, not surface size; default-with-override; width sized against budget. Fan-out contract: decomposition, hard report-schema output, merge rule, reader/judge tier split. | [`scan-workflow-fanout.md`](scan-workflow-fanout.md) |
| Doc link discipline | Link-candidate predicate for SSOT-home doc links (real home + substantive use + not-a-catalog). Shared by the emit rule (`ssot-doc-link`) at authoring time and `check-docs-consistency` P3 at audit time; predicate lives here, action with each. | [`doc-link-discipline.md`](doc-link-discipline.md) |
| Doc dimension discipline | Classify state vs history + route + audit predicate (chronicle crawl-in / stale workspace / state leak). Work-moment expression of the doc-dimension-ssot axiom. Shared by the emit rule (`dimension-discipline`) at authoring time and `check-docs-consistency` at audit time; predicate lives here, action with each. | [`doc-dimension-discipline.md`](doc-dimension-discipline.md) |
