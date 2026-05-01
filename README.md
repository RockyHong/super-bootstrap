# super-bootstrap

Bootstrap or sync a **superpowers-style development pipeline** in any repo. Solo-dev opinionated. Project-adaptive.

A single Claude Code skill that scaffolds the doc structure and CLAUDE.md workflow rules that keep documentation and implementation in sync — across multiple Claude sessions and cloud Claude Code.

## What it does

Run `/super-bootstrap` in any repo. The skill:

1. **Quick scan** — detects stack (manifests, structure, git state, existing CLAUDE.md)
2. **Q&A alignment** — confirms understanding before writing anything (project type, users, state, monorepo, etc.)
3. **Scaffold or sync** —
   - Fresh repo: creates `docs/overview.md`, `docs/techstack.md`, `docs/superpowers/{specs,plans}/`, skeleton CLAUDE.md, bootstrap plan
   - Bootstrapped repo: validates each pipeline-owned artifact, syncs only what's drifted, leaves project-owned content alone
4. **Hands off** — pipeline is now live; remaining deep-analysis tasks (techstack distillation, product overview, skill/MCP curation) become `/todo` items for future sessions

One-time / quarterly seed integrator. Repo gets the harness baked in (CLAUDE.md + docs/) — the skill itself isn't needed in-repo long-term. Re-run only for sync drift.

## Why it exists

Anthropic's [`claude-code-setup`](https://claude.com/plugins/claude-code-setup) plugin recommends MCPs/skills/hooks/subagents based on a project scan. Marketplaces (`claude plugin install`, [tonsofskills.com](https://tonsofskills.com), [awesome-skills.com](https://awesome-skills.com)) handle distribution.

Neither scaffolds a **project-adaptive documentation harness** with baked-in doc-sync discipline. That's the gap this skill fills.

The pipeline's real power isn't brainstorm → plan → execute. It's that **docs travel with code, always** — every commit verifies docs aren't stale before landing.

## Install

**Recommended — via marketplace:**

```shell
/plugin marketplace add rockyhong/super-bootstrap
/plugin install super-bootstrap@super-bootstrap
```

**Manual — clone + copy:**

```bash
# Local-only (this device)
mkdir -p ~/.claude/skills/super-bootstrap
cp plugins/super-bootstrap/skills/super-bootstrap/SKILL.md ~/.claude/skills/super-bootstrap/SKILL.md

# Or per-project (committed, available to cloud Claude)
mkdir -p .claude/skills/super-bootstrap
cp plugins/super-bootstrap/skills/super-bootstrap/SKILL.md .claude/skills/super-bootstrap/SKILL.md
```

Claude Code auto-discovers skills via the `description` frontmatter — no registration needed.

## Use

In any Claude Code session, type `/super-bootstrap`. The skill walks Phase 1 → 4. Each phase confirms with you before writing.

For repos that already have the pipeline, the same command runs as a **sync pass** — only drifted artifacts get touched.

## What this writes to your repo

**Always created / modified:**

```
docs/superpowers/specs/         (.gitkeep — temporal spec folder)
docs/superpowers/plans/         (.gitkeep — temporal plan folder)
docs/superpowers/plans/bootstrap.md   (bootstrap task list, deleted at Task 6)
CLAUDE.md                       (creates new, or layers workflow sections onto existing)
.claude/settings.json           (after Task 4 — adds enabledPlugins from your approved batch)
```

**Created only if Q&A confirms:**

```
docs/specs/index.md             (persistent feature spec catalog)
docs/specs/.gitkeep
docs/building.md                (build/distribution instructions)
docs/help/                      (user-facing guides folder)
```

**Auto-commits:** yes — runs `/commit` after each phase. Review the diff before approving. The skill never force-pushes.

**Sensitive files skipped during scan:** `.env*`, `*secret*`, `*credential*`, `*.pem`, `*.key`, `id_rsa*`, `id_ed25519*`, `*.p12`, `*.pfx`, `*.jks`, `*.keystore`, `.npmrc`, `.netrc`, `*.crt`, `*.cer`. Skipped paths surface as `⊘ skipped <path>` so you can verify.

**On re-run (sync mode):** every drifted CLAUDE.md section shows a per-section diff and prompts `Update? (y/n/show full diff)` before overwrite. Project-owned sections are never touched.

## How Task 4 (skill / MCP / hook curation) works

Task 4 is harness-automated. Claude takes the detected stack, queries multiple catalogs, filters to stack-matched picks, and presents one batch for accept/reject/discuss.

Sources queried:

- Anthropic plugin marketplace (`claude-plugins-official`)
- [awesome-skills.com](https://awesome-skills.com) / [skills.sh](https://skills.sh)
- [tonsofskills.com](https://tonsofskills.com) / `ccpi` CLI
- [mcpmarket.com](https://mcpmarket.com) (MCP servers)
- Fast-path: if `claude-code-setup` plugin installed, `/setup` output gets merged

No manual searching. No plugin install gate.

Each non-Anthropic pick shows a **trust block** before you approve:

```
[HOOK]  auto-test@github:randoorg/auto-test
        ★ 4 · last commit 14mo ago · no license
        Permissions: ⚠ runs `npm test` on every PostToolUse
        Why: catches breakage early
        ⚠ HOOK = auto-executes. Audit source before accept.
```

Stars, recency, license, and permission scope so you can spot abandoned or sketchy picks before they land in your `.claude/settings.json`. Hooks are flagged separately because they auto-execute on every tool call. Anthropic-vetted picks (`claude-plugins-official`) skip the trust block.

## Pairs well with

- **`claude plugin install`** — install accepted recommendations from any marketplace
- **`/todo`** (skill) — drives the bootstrap plan one session at a time, keeps context windows clean

## Scope

- **Solo dev only.** Skill includes a hard gate that warns if the repo has >1 active contributor. Pipeline assumes simple branching, no PR self-review, atomic commits, no merge conflicts.
- **Cross-language.** Detects Node, TypeScript, Rust, Python, Go, Ruby, Java/Kotlin, PHP, Dart/Flutter, C/C++, C#/.NET.
- **Idempotent.** Safe to re-run. Sync logic skips current artifacts, diffs drifted ones with user approval.

## Notes

- The skill is markdown only. No scripts, no dependencies. Read it, fork it, modify the templates inside as needed.

## License

MIT
