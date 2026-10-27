# GAP-jsp5 — take over the `ssot-doc-link` rule from claude-config-manager and ship it

**Logged:** 2026-10-27 · **Source:** user — CCM is a dogfood storehouse; graduated artifacts move to their SSOT owner
**Problem:** The commit door's doc-sync guarantee (a restated fact reaches its SSOT home in one hop) rests on the `ssot-doc-link` rule, and `doc-links.sh` plus the doc-sync restatement count assume it. The rule reaches this repo only as a CCM-served copy (`.claude/rules/ssot-doc-link.md` + `.served` sidecar), and harness-bootstrap ships no counterpart, so a plugin-only consumer runs doc-sync without the discipline it rests on. By the consumer-resolvability test (`.claude/rules/repo-boundary.md` § Finding lanes) the rule is this repo's concern. The served body also points at `.claude/guidelines/work-discipline/doc-link-discipline.md`, which a consumer repo lacks, so the shipped copy must carry its predicate self-contained.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/` (new rule skeleton + placement row), `.claude/rules/ssot-doc-link.md` (served → placed dogfood copy, sidecar removed), root `CLAUDE.md` § Rules provenance line
**Prior:** precedent — the doc-consult hook absorb (`docs/decisions.md` closed-fork row "super-bootstrap absorbs the CCM-planted doc-consult hook"): sb ships, then CCM retires its copy with no coverage gap. CCM handoff: `OUT-2e1a`. Feeds `GAP-ym4e`'s authoring-time term registration, which extends this rule.

## Amendment — 2026-10-27 · gateway

`dimension-discipline` is the same case: `doc-links.sh` and the doc-sync scan treat `dimension: history` frontmatter as frozen provenance, and only that rule tells an author to declare it; the shipped CLAUDE.md skeleton carries the routing summary, not the classify step, the frontmatter declaration or the tripwire. Proposed to CCM as a second takeover; `config-overlay` sent as an open question (no sb dependency, but it fires on harness-bootstrap's settings/hook output). Rulings return on `OUT-2e1a`.

## Amendment — 2026-10-27 · CCM reply note (`OUT-2e1a`)

Scope settled: ship `ssot-doc-link` and `dimension-discipline` together, built from the served copies as they stand — CCM confirms they match its sources byte for byte. `config-overlay` stays out (storehouse-owned). After the release lands, the author notifies CCM so it retires its copies.
