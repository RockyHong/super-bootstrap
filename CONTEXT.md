# Ecosystem Context (May 2026)

Snapshot of the Claude Code skill/plugin ecosystem captured at extraction time. The point of this doc is so future sessions in this repo don't have to re-research the landscape — decisions about Task 4 adapter, publication path, marketplace registration, etc. can be made with this background loaded cold.

## TL;DR

| Layer | Status | Conclusion for sp-bootstrap |
|---|---|---|
| Project scan → recommend skills/MCP/hooks/subagents | **Solved** by Anthropic | swap Task 4 to delegate, don't reinvent |
| Skill registry / catalog | **Over-served** (5+ awesome-lists, 2849+ indexed skills) | reference, don't bundle |
| Distribution / install | **Solved** (`claude plugin install`, ccpi, antigravity npm) | use existing |
| Project-adaptive harness scaffold (overview, techstack, specs/, plans/, CLAUDE.md inject) | **GAP** | sp-bootstrap fills this |
| Doc-sync discipline baked into CLAUDE.md | **GAP** | sp-bootstrap fills this |

## What already exists (don't reinvent)

### Discovery / recommendation

- **[`claude-code-setup`](https://claude.com/plugins/claude-code-setup)** — Anthropic official plugin. Read-only project scan. Recommends across 5 categories: MCP servers, skills, hooks, subagents, slash commands. Detects via `package.json`, language files, directory patterns. Generates 1–2 top recommendations per category, or 3–5 on focused asks. Read-only — does not modify codebase.
- **[Capability Discovery skill](https://mcpmarket.com/tools/skills/capability-discovery)** — scans CLAUDE.md, agents, skills, quality commands before execution.
- **[Discover Projects skill](https://mcpmarket.com/tools/skills/project-discovery-indexing)** — repo indexing, identifies git repos + CLAUDE.md projects.

### Marketplaces / registries

- **[Anthropic plugins official marketplace](https://github.com/anthropics/claude-plugins-official)** — official source, `claude plugin install <slug>@<market>`.
- **[Discover plugins docs](https://code.claude.com/docs/en/discover-plugins)** — official docs for plugin discovery + marketplace registration.
- **[claudemarketplaces.com](https://claudemarketplaces.com/)** — directory sorted by installs + GitHub stars.
- **[awesome-skills.com](https://awesome-skills.com/)** — 1030+ skills, links + descriptions.
- **[claudecodeplugins.io](https://claudecodeplugins.io/)** — Claude Code Skills Hub.
- **[skills.sh](https://skills.sh)** (Vercel-maintained) — searchable directory across the ecosystem.

### Awesome-list / sink-kitchen repos

- **[hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)** — broad: skills, hooks, slash-commands, agent orchestrators, applications, plugins.
- **[travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills)** — curated skills + tools focused on Claude Code.
- **[ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills)** — features LangSmith, MCP Builder, Playwright, etc.
- **[BehiSecc/awesome-claude-skills](https://github.com/BehiSecc/awesome-claude-skills)** — security-focused (VibeSec, OWASP).
- **[VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)** — 1000+ skills, multi-tool compat (CC/Cursor/Gemini/Codex). Hand-curated, no installer.
- **[sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills)** — 1400+ skills, npm installer (`npx antigravity-awesome-skills`), `--category --risk --tags` filters, role bundles (Web Wizard, Security Engineer, OSS Maintainer).
- **[jeremylongshore/claude-code-plugins-plus-skills](https://github.com/jeremylongshore/claude-code-plugins-plus-skills)** — 423 plugins, 2849 skills, 177 agents. Ships `ccpi` CLI npm package manager (`ccpi search devops`, `ccpi install <pack>`). Marketplace at [tonsofskills.com](https://tonsofskills.com).
- **[alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills)** — 232+ skills across multiple coding agents.
- **[GetBindu/awesome-claude-code-and-skills](https://github.com/GetBindu/awesome-claude-code-and-skills)**, **[Chat2AnyLLM/awesome-claude-skills](https://github.com/Chat2AnyLLM/awesome-claude-skills)**, **[jezweb/claude-skills](https://github.com/jezweb/claude-skills)**, **[glebis/claude-skills](https://github.com/glebis/claude-skills)** — additional collections.

## What sp-bootstrap uniquely owns

None of the above scaffold a **project-adaptive documentation harness** with baked-in doc-sync discipline. They recommend skills, install skills, list skills — but they don't give a project the structural scaffolding (`docs/overview.md`, `docs/techstack.md`, `docs/superpowers/{specs,plans}/`, `CLAUDE.md` workflow rules) that keeps a Claude Code session honest across multiple sessions.

Specifically unique:

| Feature | Why no one else does it |
|---|---|
| Two kinds of specs (temporal vs persistent) | not a known industry distinction |
| Doc-sync as named pipeline step ("docs travel with code") | most tools focus on code generation, not doc/code coupling |
| Solo-dev hard gate | most tools assume team workflows |
| Adaptive scaffolding (specs/ + building.md + help/ only when warranted) | Q&A-driven, not template-stamped |
| Skeleton CLAUDE.md with workflow engine + stub sections | claude-code-setup recommends; doesn't author CLAUDE.md |

## Pending decisions for this repo

### 1. Task 4 (Skill Resolution) adapter swap

`SKILL.md:511` currently says `Run /resolve-claude-config`. That's a fork-specific command from the [<private-origin>](https://github.com/<private-origin>) origin. Options:

- **(a) Adapter dispatch.** Detect catalog source: <private-origin> fork → `/resolve-claude-config`; Anthropic plugin installed → `/setup` (claude-code-setup); else → manual recommendation (link to awesome-skills.com).
- **(b) Hardcode `/setup`.** Simpler. Lose the fork path. Acceptable if you don't expect users to also have <private-origin>.
- **(c) Make Task 4 description-only.** Drop the command, just say "match stack to skills using your discovery tool of choice". Most generic, least helpful.

Recommendation: (a) but cheap — a 5-line conditional in Task 4 prose, not a real plugin system.

### 2. Publication path

- **GitHub public + Claude plugin marketplace.** Standard. Register via `marketplace.json` ([example](https://github.com/anthropics/claude-plugins-official/blob/main/.claude-plugin/marketplace.json)).
- **Submit to existing sink-kitchens.** PR to `hesreallyhim/awesome-claude-code` and `travisvn/awesome-claude-skills`. Free distribution, no own marketplace required.
- **Both.** Standard play.

### 3. Naming

- Keep `sp-bootstrap` (current frontmatter `name`)? Pros: continuity with <private-origin>, "sp" = superpowers shorthand.
- Rebrand for broader audience? "sp" reads as private jargon to outsiders. Candidates: `bootstrap-pipeline`, `superpowers-bootstrap`, `claude-pipeline-bootstrap`.

### 4. Origin reference

README currently links back to `<private-origin>`. Keep, drop, or rename the link target if the origin repo is renamed/restructured?

### 5. Eat own dogfood?

Run `/sp-bootstrap` on this greenfield itself? Would scaffold `docs/`, fill in `CLAUDE.md`, write a bootstrap plan. Meta but valid sanity check that the skill works on a fresh repo.

## Reference: origin repo unique value

The [<private-origin>](https://github.com/<private-origin>) origin still uniquely owns (for context — these stay there, not part of sp-bootstrap):

- Declarative project skill manifest (`must-have.txt` committed, like package.json for Claude)
- Reconciliation / drift detection (manifest vs reality)
- Per-project plugin disable (cuts device-wide plugin token bloat in stack-mismatched projects)
- Hook distribution dual-track (device + project)
- Inbox curation pipeline (private workflow)

These could become a separate productized layer eventually, but that's deferred. sp-bootstrap stands alone without them.

## Quick-resume orientation for new session

1. **Read** `README.md` (positioning), then `SKILL.md` (the actual skill), then this file (background).
2. **Pick** a pending decision from §"Pending decisions" above.
3. **If touching SKILL.md content**, run the doc-sync principle the skill itself prescribes: scan for stale references, report before silently fixing.
