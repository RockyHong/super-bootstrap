# {Project Name}

<!--
  Skeleton target: every line earns its always-on slot.
  Length is downstream of that — opinionated lean, ~120 lines.
  Path-scoped patterns live in .claude/rules/ (full-body, fires on file match).
  Reference material (code patterns, examples) lives in docs/techstack.md.
  CLAUDE.md is the orchestrator brief — workflow gates + always-on rules + rules index.
-->

## Development Workflow

Before any work, **assess size, propose a route, wait for the user to confirm:**

```
This looks [small/medium/large] because [reason].
Route: [steps]
Impact: [what changes, how many files, risk level]
OK to proceed?
```

### Routes

**Small** — single file, clear intent, no design decisions
→ implement → user review → doc sync → `/sb-commit`

**Medium** — multi-file, some design choices, one session
→ Brainstorm (quick, inline) → implement → user review → doc sync → `/sb-commit`

**Large** — multi-session, architectural, unclear scope
→ Full pipeline: brainstorm → spec → plan → execute → user review → doc sync → `/sb-commit`
→ Specs go to `docs/superpowers/specs/`, plans to `docs/superpowers/plans/`

User picks the route. **User instructions override Superpowers defaults.**

## Doc Sync (non-negotiable)

Named pipeline step — every route includes it between user review and commit.

Before every commit, scan `docs/` for files describing behavior touched by the diff (specs, overview, techstack, backlog). If any doc looks stale:

1. Report it — doc path, what looks outdated, relevant diff context
2. Resolve together — update or acknowledge it's still accurate
3. Never silently fix. Never silently skip.

**Temporal cleanup:** if work completes a feature branch, delete its spec and plan files from `docs/superpowers/specs/` and `docs/superpowers/plans/`. Once merged, they're noise.

{**Backlog cleanup:** if work resolves a `BUG-###` / `DEBT-###` / `GAP-###` from `docs/backlog.md`, delete that item. Git history is the archive.}

## Coding Principles

- **Think before coding.** State assumptions. If multiple valid interpretations exist, present them — don't pick silently. If unclear, stop and ask.
- **Simplicity first.** Minimum code that solves it. No speculative abstraction, no flexibility nobody asked for, no error handling for impossible scenarios.
- **Surgical changes.** Touch only what you must. Don't refactor adjacent code, don't reformat, match existing style. Remove orphans your changes create — leave pre-existing dead code alone.

## Edit Discipline — Renames & Replace-All

`Edit replace_all: true` is naive whole-file string replace — no AST, no scope, no token boundaries. Running on common identifiers silently corrupts unrelated code (`state` → `swipe` rewrites `SwipeState` to `SwipeSwipe`, import paths, comments, CSS selectors). The trap is invisible until the next type-check.

**Preference order:**

1. **LSP rename** — symbol-aware, scope-respecting. Best for typed languages (TS, Rust, Go, Java, Python with pyright, C#).
2. **Per-occurrence Edit with unique surrounding context** — when LSP unavailable. Grep call sites; each Edit's `old_string` includes enough context to be unique to that call.
3. **`sed` / scripted bulk replace** — only when term is **8+ chars and unique to the domain** (`Conversation`, `MerchandiseInventory`). Always case-preserving pair: `s/OldName/NewName/g; s/oldName/newName/g; s/OLD_NAME/NEW_NAME/g`. Run build/test cycle immediately.
4. **`Edit replace_all: true`** — only on unique long string literals (URLs, full sentences, hash IDs). Never on identifiers <8 chars. Never on common English words.

**Pre-flight checklist (any bulk replace):**

1. Grep the exact term. Look at count + sample matches.
2. If hits >5 OR length <8 OR common English word → switch to options 1–3.
3. Scan sample matches for false positives (substrings inside other identifiers, string literals, CSS classes overlapping HTML tags, comments).
4. Any doubt → per-occurrence Edit. Caution token cost ≪ silent-corruption debug cost.

**Banned terms for `replace_all`** (always per-occurrence):
`state`, `name`, `data`, `value`, `item`, `key`, `id`, `type`, `props`, `node`, `text`, `link`, `error`, `result`, `body`, `head`, `main`, `time`, `path`, `file`, `index`, `count`, `child`, `style`, `class`, `tag`, `event`, `target`, `source`, `from`, `to`, `next`, `prev`, `init`, `done`.

**When a `replace_all` slips through:**

1. `git diff` first — see damage scope.
2. If uncommitted, `git checkout` the file and redo with the right tool.
3. If committed, fix as a NEW commit (preserves mistake in history).
4. Run type-check / lint / test — usually points straight at corruption.

Always run build/test after bulk operations.

## Context Hygiene

Multi-needle recall degrades past ~200k input tokens. Sweet spot: ≤80k = 100% recall, 200-300k = 95%. Cache solves token cost; quality is the constraint.

- **Subagent-first for verbose work** — reading 10+ files, noisy test suites, parallel-safe chunks, fresh-eye review. Subagent gets a clean window; orchestrator stays sharp. Skip for <3-5k token tasks (init overhead swamps gain).
- **Compact while warm.** `/compact` only inside cache TTL (5min default, 1hr extended). Idle compact pays full price to summarize. If away, prefer `/clear`.
- **Clear on topic shift.** Cache wasted across topic boundaries anyway. Free quality reset.
- **Park before /clear** mid-implementation. Short handoff note (state, next step, open questions) so next session resumes.

Default order when context heavy: subagent → compact (warm) → clear (cold/topic-shifted) → park (mid-implementation at risk).

## Rules (auto-load on file match)

`.claude/rules/*.md` files attach to file reads via glob frontmatter — full-body rule fires at the decision moment, zero ambient cost when irrelevant. Summary below so this orchestrator knows the rule exists during planning.

{seeded by sp-bootstrap based on Phase 1 stack signals — examples:}

{- **`rules/<framework>.md`** — fires on `{framework component glob}`}
{  • {one-line key rule}}
{  • {one-line key rule}}

{- **`rules/mv3.md`** — fires on `src/background/**`, `src/content/**`}
{  • {one-line key rule}}
{  • {one-line key rule}}

{If rule body needs more context than its summary provides during planning, read the rule file directly before designing — `Read .claude/rules/<name>.md`.}

## Solo Dev Assumptions

Single developer across multiple Claude Code sessions.

- No PR self-review — commit directly to working branch
- Simple branching — `main` + feature branches, no rebasing
- No force push — every commit is sacred
- Session isolation — each Claude session commits only its own changes
- No merge conflicts expected — if one occurs, stop and ask

## Tech Stack

{detected one-line summary, e.g. "Node 20 + Next 14 + Postgres + pnpm"}

→ Full stack table, dependency philosophy, architecture rules, coding patterns in [`docs/techstack.md`](docs/techstack.md).

## Commands

```bash
{detected from scripts/Makefile/Cargo — only what exists right now}
```

## Git Notes

- Only commit current session's changes — leave unrelated uncommitted work alone
- Atomic commits — one logical change per commit
- Conventional commits — `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`

## Planning

- [`docs/overview.md`](docs/overview.md) — product context, data flow, module index. Skeleton seeded at scaffold; grown sections fill via doc-sync.
- [`docs/techstack.md`](docs/techstack.md) — stack, architecture rules, coding patterns. Skeleton seeded at scaffold; grown sections fill via doc-sync.
{- [`docs/specs/`](docs/specs/) — persistent feature specs, one `.md` per feature. Filename + heading is the catalog; no index.}
{- [`docs/backlog.md`](docs/backlog.md) — deferred items (`BUG-###` / `DEBT-###` / `GAP-###`), deleted on resolve.}
- `docs/superpowers/specs/` — design specs from brainstorming (temporal — deleted after merge)
- `docs/superpowers/plans/` — implementation plans (temporal — deleted after merge)
- `.claude/rules/` — path-scoped rules, full-body fires on file match (see Rules section above)

> **Two kinds of specs:** `docs/specs/` = permanent source of truth. `docs/superpowers/specs/` = temporal work orders.
