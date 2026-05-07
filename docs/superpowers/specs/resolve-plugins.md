# Spec: Extract `resolve-plugins` Skill

## Motivation

`/harness-bootstrap` Phase 3c (curate skill / MCP / hook) does work that has nothing to do with doc scaffolding:

- Live-queries 6 upstream sources (Anthropic, MCP registry, ECC, awesome-claude-skills, VoltAgent, jeffallan)
- Dedupes by canonical name across sources
- Computes trust tiers per pick (🛡 / ★ / 🆕 / ⚠)
- Diffs against `.claude/settings.json` pinned set
- Writes `enabledPlugins` + `extraKnownMarketplaces`

This is a distinct concern from Phase 3a (folders) and 3b (pipeline doc drift). Coupling it inside `/harness-bootstrap` forces users through Phase 1 quick-scan + Phase 2 Q&A + Phase 3a-b drift just to refresh picks against drifted upstream sources.

User has recurring real need: refresh picks without doc-sync ceremony.

## Goal

Extract Phase 3c into standalone `resolve-plugins` skill. `/harness-bootstrap` invokes the new skill instead of inlining the logic. Single source of truth for plugin curation logic.

## Non-Goals

- Not a generic plugin manager. No install/uninstall device-side. `claude plugin install` stays as separate concern.
- No new sources, no new trust tiers — straight extraction of current Phase 3c logic.
- No CLAUDE.md/doc-sync changes. Scope locked to Phase 3c boundary.

## Naming Rule (general convention)

| Prefix shape | Tier | Frequency | Examples |
|---|---|---|---|
| `sb-*` | In-flight ops | High (per-session, per-commit) | `sb-commit`, `sb-todo` |
| Self-explanatory verb-noun | Bootstrap / system / lifecycle | Low (rare invocations) | `super-bootstrap`, `harness-bootstrap`, `resolve-plugins` |

**Why:** `sb-` shorthand is amortized by repetition. Lifecycle-tier skills fire rarely — must read clearly cold without prefix knowledge.

**Apply:** name = `resolve-plugins`. Not `sb-plugins` (would imply per-commit cadence — wrong signal).

Document rule in `plugins/super-bootstrap/README.md` § Naming.

## Interface

### Inputs (files-as-contract — no in-memory handoff)

- `docs/techstack.md` § Runtime / Framework / Key Dependencies — drives stack-matched picks.
- `docs/overview.md` § User / Current State — drives workflow picks (passive — minor signal).
- Phase 2 Q4 (external tools) is **NOT** re-asked. Skill reads workflow signal from existing `.claude/settings.json` pinned set + `docs/overview.md`. If neither has signal, prompt user once with the same Q4 MCQ from harness Phase 2.
- `.claude/settings.json` pinned set — for delta computation.

If `docs/techstack.md` missing → fail loud with redirect: "No `docs/techstack.md` found. Run `/harness-bootstrap` first to seed the harness." No silent fallback.

### Output

- `.claude/settings.json` updated (`enabledPlugins` + `extraKnownMarketplaces`).
- Sync report to user.
- Optional commit via `/sb-commit` if delta non-empty (mirror harness 3d behavior for the picks-only case).

### Phases

```
Phase 1: Read docs/techstack.md + docs/overview.md (or fail-loud)
Phase 2: Live-query source pool (parallel WebFetch/Bash)
Phase 3: Dedupe + trust signals + filter to matched picks
Phase 4: Diff vs pinned, present batch to user
Phase 5: Apply approved → write settings.json + commit if delta
```

Reuse exact logic from current harness Phase 3c. Move, don't rewrite.

## Drift-Prevention Contract

**Hard rule:** harness Phase 3c becomes one Skill invocation. No copy-paste of source-pool list, trust-tier definitions, dedupe rules, or batch-presentation format.

After extraction:
- Source pool list lives ONLY in `resolve-plugins` SKILL.md.
- Trust tier definitions (🛡 / ★ / 🆕 / ⚠) live ONLY in `resolve-plugins` SKILL.md.
- Dedupe + batch format live ONLY in `resolve-plugins` SKILL.md.
- Harness 3c content: one paragraph saying "delegate to `resolve-plugins`" + reasoning for the delegation point.

**Verification command** (post-execution):

```bash
# These strings should appear ONLY in resolve-plugins SKILL.md, not in harness-bootstrap SKILL.md
grep -n "claude-plugins-official\|modelcontextprotocol/registry\|affaan-m/everything-claude-code\|ComposioHQ/awesome-claude-skills\|VoltAgent/awesome-agent-skills\|Jeffallan/claude-skills" plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md

# Expect: zero matches (all live in resolve-plugins SKILL.md now)
```

## Edge Cases

- **No `docs/techstack.md`** → redirect to `/harness-bootstrap`. Don't silently scan manifests — different skill, different responsibility.
- **Empty pinned set** (`.claude/settings.json` no `enabledPlugins`) → run as fresh curation, propose all matched picks as `+ add`.
- **Source pool partial failure** (one source 404 / rate limit) → continue with remaining sources, note inline. Mirror current Phase 3c.
- **All sources unreachable** → fail loud, report "no sources available for live-query." Don't write stale-pin diff. User can retry.
- **No delta after curation** → report `✓ all pinned picks current` and skip commit.

## Out of Scope (defer)

- Caching live-query results. Future optimization if calls feel slow.
- Selective source pool (`--sources anthropic,ecc`). Future flag.
- Lock file (`plugin-lock.json`) for reproducible resolves. Future if drift between teammates becomes a concern.

## Open Questions

- Should `resolve-plugins` auto-commit, or always end with sync report and let user choose `/sb-commit`? **Proposal:** auto-call `/sb-commit` at end if delta non-empty. Same pattern as `/harness-bootstrap` 3d. User reviews diff at commit-time. Confirm in plan review.

- Where does the workflow-tools signal (Q4 in harness) come from on standalone runs? **Proposal:** read from existing pinned picks (Notion MCP pinned → docs-heavy workflow inferred) + overview.md text. If insufficient, prompt user once with original Q4 MCQ. Confirm in plan review.
