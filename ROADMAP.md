# super-bootstrap Roadmap

Temporal decisions log + execution order. Migrates into pipeline (`docs/superpowers/plans/`) if/when this repo dogfoods itself, else deleted at completion.

## Decisions

### D0 — Scope

**super-bootstrap is a harness orchestrator.** Auto-wires Claude-side tooling per repo state. Menu is extensible. User interacts with the harness, not the underlying tools.

Always-on menu:
- techstack adapt → CLAUDE.md sections
- doc-sync discipline → CLAUDE.md non-negotiable
- temporal flow scaffold → `docs/superpowers/specs|plans/`
- adaptive persistent docs → Q&A-driven (`docs/specs/`, `building.md`, `help/`)
- skill/MCP/hook recommendations → Task 4 adapter

ICP framing: harness automation is invisible to user. ICP only shapes interface (questions, output verbosity), not machinery selection.

### D0b — Graphify

**Out of scope now. Future extension.** Not wired into super-bootstrap. When graphify proven stable in other repo, build a separate companion command/skill that rewires graphify into an existing super-bootstrapped repo (re-edits CLAUDE.md, scaffolds `docs/graph/`, adds workflow integration line).

Rationale: keep super-bootstrap tight, avoid coupling to in-flight tooling.

### D0c — Lifecycle

**One-time / quarterly seed integrator.** Installed globally, runs on demand. Repo gets harness baked in (CLAUDE.md + docs/) — skill itself not needed in repo long-term. Re-run only for sync drift.

Implication: name signals one-time/seed (not persistent tool), repo doesn't need skill committed locally.

### D1 — Naming

**Locked: `super-bootstrap`.**

Rationale: short, "bootstrap" captures one-time/seed nature, "super" hints at superpowers lineage without being insider-opaque (`sp-` was). Trade: searches for "bootstrap" hit CSS framework noise — non-issue within Claude skill marketplace.

Rename touches: `SKILL.md` frontmatter `name`, `README.md` title + body refs, repo dir name (defer to publication phase).

### D4b — CONTEXT.md handling

**Locked: keep now, delete at publication shift.** Internal background doc — useful while decisions are in flight. Reveals private extraction history, not appropriate for clean public release. Delete (or move to gitignored archive) as part of D8 publication phase.

### D3 — Dogfood

**Locked: no dogfood.** Repo is a payload carrier (ships `SKILL.md` for outsiders) — not a product with code/feature lifecycle. Harness was designed for repos with code; this repo doesn't fit target shape. Use `ROADMAP.md` for temporal execution tracking, delete on completion.

### D2 — Task 4 (Skill / MCP / Hook Resolution)

**Locked: harness-internal curation, fully automated, single-batch user confirm.**

- super-bootstrap is **thin orchestrator** — does NOT own catalog data.
- Claude (in current session) curates using: detected stack from Task 1 + web tools + ecosystem knowledge.
- `/setup` (claude-code-setup plugin) used as fast-path internal optimization if installed; not user-facing prerequisite.
- User sees one batch with rationale per pick → accept all / reject specific / discuss.
- Drop `/resolve-claude-config` reference entirely (fork-only, kept private).

**Curation sources (must be documented in SKILL.md Task 4 + README transparency section):**
- Anthropic plugin marketplace (`claude-plugins-official`)
- [awesome-skills.com](https://awesome-skills.com)
- [skills.sh](https://skills.sh)
- [tonsofskills.com](https://tonsofskills.com) / `ccpi`
- [mcpmarket.com](https://mcpmarket.com) (MCP servers)
- Optional: `/setup` if claude-code-setup plugin present

Filter rule: stack-matched only, drop generic/spray suggestions.

## Open Questions (ordered by dependency)

1. ~~Naming~~ → **D1 locked: `super-bootstrap`.**
2. ~~Task 4 adapter~~ → **D2 locked: harness-internal curation, batch confirm, sources documented.**
3. ~~Dogfood~~ → **D3 locked: no dogfood.**
4. ~~Origin scrub (README)~~ → **D4 done.** README §Notes bullet removed. SKILL.md refs handled in D6.
5. ~~Branch rename~~ → **D5 done.** `master` → `main`.
6. ~~SKILL.md + README edits~~ → **D6 done.** `name` → `super-bootstrap`, title updated, Task 4 rewritten per D2, all `/resolve-claude-config` refs scrubbed, README rewritten with curation transparency section, internal name refs renamed.
7. **Park TODOs** — graphify rewire skill, publication path (marketplace.json + awesome-list PRs).
8. **Publication** — last mile. Includes: delete `CONTEXT.md`, delete `ROADMAP.md`, register marketplace, awesome-list PRs.

## Execution Plan

Top-down. Each step gates next. No parallel.

## Wet Test Plan (run in fresh session, not this one)

**Target:** `<user-repo>` (real personal repo).

**Pre-flight (one time):**

```powershell
# Install skill globally so /super-bootstrap is discoverable
mkdir -Force ~/.claude/skills/super-bootstrap
cp <repo>\SKILL.md ~/.claude/skills/super-bootstrap/SKILL.md
```

**Procedure:**

1. Open fresh Claude Code session in `<user-repo>`.
2. Type `/super-bootstrap`.
3. Walk through Phase 1 → 4. Answer Q&A as it comes.
4. Note anything that breaks, feels wrong, or needs polish.

**Validation checklist:**

- [ ] Phase 1 detects Chrome Extension stack (manifest.json + package.json combo)
- [ ] Phase 2 Q&A flow makes sense for this repo type
- [ ] Phase 3 scaffolds expected `docs/` + `CLAUDE.md`
- [ ] Task 4 auto-curates skills/MCPs (no `/resolve-claude-config` refs)
- [ ] Sync re-run is idempotent (run twice, second pass = no-op)
- [ ] No fork-specific leaks (greps clean for `resolve-claude-config`, `<private-origin>`)

**Issue logging:**

Bring findings back to this repo's session. Append to ROADMAP under new section `## Wet Test Findings` with: line ref, problem, fix idea.

**After test passes (cleanup at D8):**

- Delete `CONTEXT.md`, `ROADMAP.md`
- Decide marketplace target (Q8c)
- Decide awesome-list PRs (Q8d)
- Rename repo dir `sp-bootstrap` → `super-bootstrap` (Q8a, last)

