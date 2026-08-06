# DEBT-052 — docs/overview.md grown sections empty in a mature repo

**Logged:** 2026-08-06 · **Source:** DEBT-047 live-run pass — real doc debt surfaced while staging the drain verification wave
**Problem:** `docs/overview.md` § Module Index, § Data Flow, § Key Boundaries carry only their seed blockquotes — zero rows — while the repo ships 14+ skills, 7 agents, shared classify specs, hook assets, and a marketplace manifest. The doc-sync growth loop never seeded them; a cold reader gets no map of what exists.
**Area:** `docs/overview.md` (grown sections only — Problem / User / Current State are current)
**Prior:** derive rows from the live tree (`plugins/super-bootstrap/{skills,agents,shared}/`, `.claude-plugin/`, root `.claude-plugin/marketplace.json`); one line each, no restating SKILL.md contracts (link, don't copy).

## Verdict — auto-fix · 2026-08-06

**Fix-shape:** systematic
**Probe-deps:** none
**Execution:** phased(skip: red, verify) — depth: shape is pinned below (three sections, row sources, granularity, delegation targets), so the implementer derives prose, not approach; closure: one write file plus a bounded read-and-confirm set (root README, plugin README, techstack), and the diff carries no test/runtime surface, so red + verify are structurally empty per `CLAUDE.md` § The envelope.

### Repro (pinned)

> `docs/overview.md` § Module Index, § Data Flow, § Key Boundaries carry only their seed blockquotes — zero rows — while the repo ships 14+ skills, 7 agents, shared classify specs, hook assets, and a marketplace manifest. The doc-sync growth loop never seeded them; a cold reader gets no map of what exists.

> derive rows from the live tree (`plugins/super-bootstrap/{skills,agents,shared}/`, `.claude-plugin/`, root `.claude-plugin/marketplace.json`); one line each, no restating SKILL.md contracts (link, don't copy).

### Root cause (verified)

Gap confirmed against current code, not inferred.

- `docs/overview.md:34-44` — all three grown sections hold their seed blockquote and nothing else. Byte-identical to the shipped seed at `plugins/super-bootstrap/skills/harness-bootstrap/assets/overview-skeleton.md:22-32`, i.e. never grown since scaffold.
- The tree they should map is live: `find plugins -type f` = **60 files** — 13 `SKILL.md` (not 14+, see caveat), 7 agents (`doc-sync-scan`, `plugin-digest`, `premise-closure`, `review-intake`, `todo`, `triage-report`, `triage`), 2 shared specs (`classify-actionable.md`, `grounding-discipline.md`), 2 frozen hook assets (`harness-bootstrap/assets/hooks/commit-channel.{hook.json,sh}`) plus `drain/assets/read-hook.json`, `plugins/super-bootstrap/.claude-plugin/plugin.json`, root `.claude-plugin/marketplace.json`. Repo root also carries `tests/` (2 shell tests) — absent from the card's enumeration.
- Filling them is sanctioned, not a pipeline conflict: `harness-bootstrap/SKILL.md:144` lists `docs/overview.md` grown sections under **Project-owned (never touched)**, so a runway re-run will not clobber the rows.

**Scope constraint the fix must obey — parallel-truth guard.** Two SSOTs already own most of what a naive Module Index would restate, and this repo's own rule (`plugins/super-bootstrap/README.md:87`: pick the canonical home, delete duplication, replace with one-paragraph delegation) plus the card's own "link, don't copy" both bind here:

- `plugins/super-bootstrap/README.md` § Skill catalog — already a per-skill one-line index, explicitly "Index only… Canonical per-skill contract = that skill's `SKILL.md` frontmatter". § Inline vs Dispatch owns dispatch-mode rationale; § Source of truth boundaries owns internal-interface ownership.
- `docs/techstack.md:11` (§ Framework) — owns the layout + the `marketplace.json` `source` install boundary.

So the three sections scope as: **Module Index** = repo-level tree map (top-level dirs + the layers: skills / agents / shared / assets / manifests / tests / docs), one line each, delegating the per-skill catalog by link rather than re-listing 13 rows. **Data Flow** = the invoke→artifact pipeline, which no doc currently owns end-to-end (root README's mermaid covers the `/super-bootstrap` entry only). **Key Boundaries** = the contract surfaces plus links to their homes — Claude Code plugin-loader contract, the `source` install boundary, shipped-skeleton self-containment (`.claude/rules/repo-boundary.md`), frozen-asset install contract, `commit-channel` hook contract — never a restatement of § Source of truth boundaries.

Sibling-card boundary (`DEBT-053`, same drain wave, `docs/techstack.md` § Architecture Rules / § Coding Patterns): disjoint files, no merge collision, but overlapping candidate facts. Division follows the seed blockquotes themselves — overview § Key Boundaries states *what the interfaces and external dependencies are*; techstack § Architecture Rules states *the rules to obey when writing*. Neither restates the other.

### Files (fix surface)

- `docs/overview.md:34-44` — the only write; three grown sections filled in place, seed blockquotes retained above the new rows (they are the section's own growth contract).
- `plugins/super-bootstrap/skills/harness-bootstrap/assets/overview-skeleton.md:22-32` — **explicitly out of scope.** The shipped seed must stay empty; a consumer's overview starts unfilled by design. No `repo-boundary.md` sync-direction propagation applies — this is project-owned content, not a harness section change.
- Row-derivation sources (read-only): `plugins/super-bootstrap/**` live tree; `plugins/super-bootstrap/README.md`; `docs/techstack.md`; `docs/specs/harness-architecture.md` §2 (slot map) and §3 (dissolve table) — link, do not restate.

### Doc Impact

- `plugins/super-bootstrap/README.md` — read-and-confirm; the Module Index must delegate to § Skill catalog, not duplicate it. Expected unchanged.
- `README.md` (root) — read-and-confirm; carries the end-user bundled-skill narration (lines 57, 61). Expected unchanged; flag any contradiction the new map exposes.
- `docs/techstack.md` — read-and-confirm; § Framework owns layout + install boundary. Expected unchanged (its own grown sections are `DEBT-053`, not this card).
- `docs/specs/harness-architecture.md:421` — carries a dated grade-A measurement ("55 files / 319 KB", 2026-07-25) now superseded by 60 files. It is an explicitly dated evidence index (history dimension), so **do not update it** — but do not copy its count into the new rows either.
- `CLAUDE.md:82` / `claude-md-skeleton.md:82` — reference § Module Index only as a card-resolution destination; no change.

### Test Strategy: e2e

No unit surface exists (markdown product, no runtime). The two available human-eyeball-free checks both run against the real repo: (1) every path cited in the new rows resolves — `bash plugins/super-bootstrap/skills/commit/assets/doc-links.sh check` from repo root, which scans `docs/**/*.md` + `README.md` and exits 1 on a broken link, and rides the commit door every commit; (2) row-vs-tree enumeration diffed against `find plugins -type f`. Red is structurally empty per `CLAUDE.md` § The envelope (docs-only diff).
