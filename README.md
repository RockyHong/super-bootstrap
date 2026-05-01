# super-bootstrap

Skip the per-project Claude setup grind. One command picks your skills, writes `CLAUDE.md`, pins your config, **and gives Claude a route-aware workflow** (small tasks stay light; large ones lean on the [superpowers](https://github.com/obra/superpowers) pipeline). Workflow, not just a toolbelt.

## Install

In Claude Code:

```
/plugin marketplace add rockyhong/super-bootstrap
/plugin install super-bootstrap@super-bootstrap
```

## How it works

Run in any repo:

```
/super-bootstrap
```

Then it walks these phases:

1. **Scan + Q&A** — detects stack, asks ~6 questions to confirm
2. **Curate** — picks skills/MCPs matched to your stack, trust signals per pick
3. **Scaffold** — writes `CLAUDE.md`, pins config, drops in pipeline workspace
4. **Handoff** — Claude routes by task size: small → direct implement, medium → quick brainstorm, large → full [superpowers](https://github.com/obra/superpowers) pipeline (brainstorm → spec → plan → execute). Doc-sync gate fires on every commit regardless of route, blocking stale-doc commits
5. **Done** — start building. Harness keeps Claude in sync as you go.

Auto-commits each phase. Re-run anytime to sync drift.

```mermaid
flowchart TD
    repo["your repo<br/>(e.g. TS + React + Postgres)"]
    repo --> scan["1. Scan + Q&A<br/>~6 questions, ~2 min"]
    scan --> curate["2. Curate skills/MCPs<br/>matched to stack"]
    curate --> scaffold["3. Scaffold config"]
    scaffold --> handoff["4. Handoff to Claude"]
    handoff --> done["5. Done<br/>harness keeps Claude<br/>in sync as you build"]

    curate -.->|example picks| picks["react-expert<br/>postgres-pro<br/>Linear MCP<br/>commit-commands"]
    scaffold -.->|writes| files["CLAUDE.md<br/>.claude/settings.json<br/>docs/superpowers/"]
    handoff -.->|drives with| engine["route triage<br/>+ doc-sync gate<br/>(superpowers for large tasks)"]
```

## What it touches

- **`CLAUDE.md`** — layered, not overwritten. Pipeline sections added or synced; your existing sections untouched. Per-section diff shown before every write.
- **`.claude/settings.json`** — merges `enabledPlugins` + `extraKnownMarketplaces`. Other settings preserved.
- **`.claude/` plugin cache** — lands next session when Claude Code auto-resolves the new plugins.
- **`docs/superpowers/{specs,plans}/`** — new pipeline workspace. `/todo` skill (bundled) scans this for active work.
- **`docs/backlog.md`** *(adaptive)* — single tracker for deferred BUG/DEBT/GAP items, scaffolded if you opt in during Q&A.

Plugin also bundles `/todo` (active work scanner) and `/commit` (session-isolated, doc-sync-gated, conventional, no push). Both encode the harness rules so the handoff isn't broken on fresh machines.

## Scope

Best for solo devs juggling multiple repos who want quick Claude bootstrap per project.

Supports a wide range of stacks — picks pulled from Anthropic's marketplace, awesome-skills, tonsofskills, and mcpmarket, matched to your detected stack. Sensitive files (`.env*`, `*.key`, `*credential*`, etc.) skipped from scan.

## References

| Tool | Role |
|---|---|
| [superpowers](https://github.com/obra/superpowers) | Workflow pipeline (brainstorm → spec → plan → execute) baked into the CLAUDE.md |
| [claude-code-setup](https://claude.com/plugins/claude-code-setup) | Anthropic's plugin recommender — fast-path source if installed |
| [Anthropic plugin marketplace](https://claude.com/plugins) | Vetted skills, MCPs, hooks, subagents |
| [awesome-skills](https://awesome-skills.com) | Community skill catalog |
| [tonsofskills](https://tonsofskills.com) | Community skill catalog (`ccpi` CLI) |
| [mcpmarket](https://mcpmarket.com) | MCP server catalog |

## License

MIT
