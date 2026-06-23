# super-bootstrap

## Development Workflow

Every session runs under the superpowers frame. **The gateway is the gate** — informal input (pasted logs, "just fix this", a one-line ask) does not lower the bar. On any non-trivial code change the gateway's first move is to formalize *before touching code*: ground the problem, then propose + confirm the route. Filing via `/super-bootstrap:log` first still runs steps 2-7.

### Entry Gate (ordered — each step leaves an artifact)

Non-trivial = anything past a single obvious edit. Walk in order; the artifact is what proves the step happened — narration is not an artifact.

| # | Step | Required artifact |
|---|---|---|
| 1 | **Ground** — probe the problem against the real before scoping a fix | Bug/debt → a `docs/backlog.md` card whose root cause is verified against the real artifact (logs, repro, code), not a guess. Feature/refactor → a written problem statement grounded in first principles |
| 2 | **Route** — triage phases (below), check [`docs/decisions.md`](docs/decisions.md) § Closed Forks, propose, **stop for confirm** | A posted route line the user has confirmed |
| 3 | **Red** — for a change with a test surface, write the failing test first | A captured failing-test run (command + red output) before implementation |
| 4 | **Implement** — write code to green | Passing run of the step-3 test |
| 5 | **Verify** — run checks; for harness-file changes (CLAUDE.md, rules, skills, agents) the `audit-harness-edits` pass is the verify artifact | Captured pass output / audit report (`verification-before-completion`) |
| 6 | **Doc-sync** — scan `docs/` for stale behavior | Per § Doc Sync |
| 7 | **Commit** — `/super-bootstrap:commit` | Terminal step |

### Phase triage (which optional phases the route composes)

Routing = which phases this work needs, judged on evidence — not file count, not size labels. Execute, verify, doc-sync and commit are the always-on spine (Entry Gate steps 3-7); brainstorm / spec / plan are the optional phases below, layered on via step 2.

| Phase | Run when | Skip when |
|---|---|---|
| **Brainstorm** | Intent fuzzy, design space unexplored, multiple viable shapes | Intent + approach obvious from repo context or user direction |
| **Spec** | Persistent design surface — behavior worth pinning for future sessions | One-time tactical change, no behavior to document |
| **Plan** | Multi-step, ordering matters, want checkpoint review, half-done risk | Single atomic edit obvious from context |

### Route output (step 2 artifact)

Propose phase composition, justify each skip with repo-grounded evidence:

```
Phases: brainstorm → plan → execute → doc-sync → commit
Skipped: spec (no persistent design surface — internal helper, no behavior contract)
Grounding: <root cause, verified against <artifact>>
Evidence: BUG-042 has clean repro in issue, fix touches one auth helper
Closed forks: none match (or cite the docs/decisions.md entry + how this differs)
OK to proceed?
```

### Phase entailments

If user pushes back on triage → re-evaluate the gate that triggered the disagreement, not the whole route.

**User instructions override Superpowers defaults.** User can add or drop phases.

Spec/plan locations: `docs/superpowers/specs/` and `docs/superpowers/plans/` (temporal). Persistent specs (kept after merge) go to `docs/specs/`.

## Doc Sync (non-negotiable)

Named pipeline step — every route includes it between user review and commit.

Before every commit, scan `docs/` for files describing behavior touched by the diff (specs, overview, techstack, backlog). If any doc looks stale:

1. Report it — doc path, what looks outdated, relevant diff context
2. Resolve together — update or acknowledge it's still accurate
3. Never silently fix. Never silently skip.

**Dimension routing (state XOR history — decide before writing any `docs/` file):**

State docs (`overview.md`, `techstack.md`, specs) hold what is **true now** — never timestamp precedent into them. Route by dimension:

- Decision still **binding** current work → present-tense constraint in the state doc it governs, stripped of when/why-decided. ("Refinement deferred behind the port" — not "on <date> we decided to defer refinement because…").
- Committed change history (what changed / when / why-of-a-change) → **git log + commit messages**. Don't hand-chronicle it into a doc.
- A direction evaluated and **closed** that left no diff (road-not-taken, wall foreseen) and would otherwise be re-proposed → [`docs/decisions.md`](docs/decisions.md).

**Temporal cleanup:** if work completes a feature branch, delete its spec and plan files from `docs/superpowers/specs/` and `docs/superpowers/plans/`. Once merged, they're noise.

**Backlog cleanup:** if work resolves a `BUG-###` / `DEBT-###` / `GAP-###` from `docs/backlog.md`, delete that item — including a shipped feature-`GAP`, which now belongs to the product narrative (Problem / Current State / Module Index). Git history is the archive.

## Coding Principles

Before writing, reviewing, or refactoring code, invoke the `karpathy-guidelines` skill.

It owns four principles (think-before-coding, simplicity-first, surgical-changes, goal-driven-execution). Skill body is upstream — don't paraphrase it here. Pin lives in `.claude/settings.json` (`andrej-karpathy-skills@karpathy-skills`).

## Edit Discipline — Renames & Replace-All

Rename preference order: LSP rename → per-occurrence Edit → `sed` (unique 8+ char literals) → `replace_all` (long unique literals only).

Banned-terms list + pre-flight checklist + recovery protocol: [`docs/techstack.md` § Edit Discipline](docs/techstack.md#edit-discipline).

## Context Hygiene

When context heavy: subagent first (clean window), compact while warm, clear on topic shift. Park mid-implementation state to docs before `/clear`.

## Finding Triage — Log vs Fix Now

Decide on two axes: **context budget** (is the window heavy?) and **topic distance** (on-goal, or far blast radius?).

- Context heavy **OR** off-topic / far blast → **log** via `/super-bootstrap:log`.
- On-topic **AND** context clean **AND** fix small + safe → **fix now**.

Surface a real fork to the user as an MCQ with the recommended path badged `(recommended)`. No real fork (trivial fix or trivial tangent) → act and mention, skip the MCQ.

## Rules (auto-load on file match)

`.claude/rules/*.md` files attach to file reads via `paths:` frontmatter — full-body rule fires at the decision moment, zero ambient cost when irrelevant. Summary below so this orchestrator knows the rule exists during planning.

- **`dimension-discipline.md`** — fires on `docs/**/*.md`, `README.md`
  • Before editing a prose doc, classify what it owns: state (overwrite in place) vs history (append-only, git's job).
- **`ssot-doc-link.md`** — fires on `docs/**/*.md`, `README.md`
  • Link each concept to its SSOT home as you write — born-linked, not back-filled.

Both served from the personal claude-config repo (predicates in `.claude/guidelines/work-discipline/`). Add a project-specific rule file when a path-scoped pattern emerges (e.g. a SKILL.md authoring convention), then mirror a one-line summary here.

## Tech Stack

Markdown-authored Claude Code plugin + self-hosted marketplace — no language runtime or build step.

→ Full stack table, dependency philosophy, architecture rules, coding patterns in [`docs/techstack.md`](docs/techstack.md).

## Commands

```bash
# No build system — skills/agents are markdown, loaded by Claude Code's plugin loader.
# Release (bump marketplace.json + plugin.json, commit, tag):
/release
```

## Git Notes

- Only commit current session's changes — leave unrelated uncommitted work alone
- Atomic commits — one logical change per commit
- Conventional commits — `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`
- No PR self-review — commit directly. Main + feature branches. No force push.
- Merge conflict → stop and ask.

## Planning

- [`docs/overview.md`](docs/overview.md) — product context, data flow, module index. Skeleton seeded at scaffold; grown sections fill via doc-sync.
- [`docs/techstack.md`](docs/techstack.md) — stack, architecture rules, coding patterns. Skeleton seeded at scaffold; grown sections fill via doc-sync.
- [`docs/backlog.md`](docs/backlog.md) — open items (`BUG-###` / `DEBT-###` / `GAP-###`), captured via `/super-bootstrap:log`, deleted on resolve.
- [`docs/decisions.md`](docs/decisions.md) — closed forks / rejected directions, all domains (history dimension). See its scope header for admission criteria; checked at triage.
- `docs/superpowers/specs/` — design specs from brainstorming (temporal — deleted after merge)
- `docs/superpowers/plans/` — implementation plans (temporal — deleted after merge)
- `.claude/rules/` — path-scoped rules, full-body fires on file match (see Rules section above)

> **Two kinds of specs:** `docs/specs/` = permanent source of truth. `docs/superpowers/specs/` = temporal work orders.
