# sp-bootstrap

Bootstrap or sync a **superpowers-style development pipeline** in any repo. Solo-dev opinionated. Project-adaptive.

A single Claude Code skill that scaffolds the doc structure and CLAUDE.md workflow rules that keep documentation and implementation in sync — across multiple Claude sessions and cloud Claude Code.

## What it does

Run `/sp-bootstrap` in any repo. The skill:

1. **Quick scan** — detects stack (manifests, structure, git state, existing CLAUDE.md)
2. **Q&A alignment** — confirms understanding before writing anything (project type, users, state, monorepo, etc.)
3. **Scaffold or sync** —
   - Fresh repo: creates `docs/overview.md`, `docs/techstack.md`, `docs/superpowers/{specs,plans}/`, skeleton CLAUDE.md, bootstrap plan
   - Bootstrapped repo: validates each pipeline-owned artifact, syncs only what's drifted, leaves project-owned content alone
4. **Hands off** — pipeline is now live; remaining deep-analysis tasks (techstack distillation, product overview, etc.) become `/todo` items for future sessions

## Why it exists

Anthropic's [`claude-code-setup`](https://claude.com/plugins/claude-code-setup) plugin recommends MCPs/skills/hooks/subagents based on a project scan. Marketplaces (`claude plugin install`, [tonsofskills.com](https://tonsofskills.com), [awesome-skills.com](https://awesome-skills.com)) handle distribution.

Neither scaffolds a **project-adaptive documentation harness** with baked-in doc-sync discipline. That's the gap this skill fills.

The pipeline's real power isn't brainstorm → plan → execute. It's that **docs travel with code, always** — every commit verifies docs aren't stale before landing.

## Install

Drop the skill into Claude Code's skill directory:

```bash
# Local-only (this device)
mkdir -p ~/.claude/skills/sp-bootstrap
cp SKILL.md ~/.claude/skills/sp-bootstrap/SKILL.md

# Or per-project (committed, available to cloud Claude)
mkdir -p .claude/skills/sp-bootstrap
cp SKILL.md .claude/skills/sp-bootstrap/SKILL.md
```

Claude Code auto-discovers skills via the `description` frontmatter — no registration needed.

## Use

In any Claude Code session, type `/sp-bootstrap`. The skill walks Phase 1 → 4. Each phase confirms with you before writing.

For repos that already have the pipeline, the same command runs as a **sync pass** — only drifted artifacts get touched.

## Pairs well with

- **`claude-code-setup`** (Anthropic plugin) — run after sp-bootstrap Task 4 for skill/MCP/hook recommendations matched to your stack
- **`claude plugin install`** — install recommendations from any marketplace
- **`/todo`** (skill) — drives the bootstrap plan one session at a time, keeps context windows clean

## Scope

- **Solo dev only.** Skill includes a hard gate that warns if the repo has >1 active contributor. Pipeline assumes simple branching, no PR self-review, atomic commits, no merge conflicts.
- **Cross-language.** Detects Node, TypeScript, Rust, Python, Go, Ruby, Java/Kotlin, PHP, Dart/Flutter, C/C++, C#/.NET.
- **Idempotent.** Safe to re-run. Sync logic skips current artifacts, diffs drifted ones with user approval.

## Notes

- Task 4 (Skill Resolution) currently mentions `/resolve-claude-config` — that's a fork-specific command from the [<private-origin>](https://github.com/<private-origin>) origin repo. Replace with `/setup` (claude-code-setup plugin) or marketplace browsing for your own setup.
- The skill is markdown only. No scripts, no dependencies. Read it, fork it, modify the templates inside as needed.

## License

MIT
