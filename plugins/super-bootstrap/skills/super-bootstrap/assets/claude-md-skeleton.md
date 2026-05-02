# {Project Name}

## Development Workflow

Before starting any work, **assess the task size and propose a route for the user to confirm.** Present it like:

```
This looks [small/medium/large] because [reason].
Route: [steps]
Impact: [what changes, how many files, risk level]
OK to proceed?
```

### Routes

**Small** — Single file, clear intent, no design decisions
→ implement → user review → doc sync → `/commit`

**Medium** — Multi-file, some design choices, completable in one session
→ Brainstorm (quick, inline) → implement → user review → doc sync → `/commit`

**Large** — Multi-session, architectural, unclear scope
→ Full pipeline: brainstorm → spec → plan → execute → user review → doc sync → `/commit`
→ Specs go to `docs/superpowers/specs/`, plans to `docs/superpowers/plans/`

The user always picks the route.

**User instructions override Superpowers defaults.**

### Doc Sync (non-negotiable)

This is a named pipeline step — every route includes it between user review and commit.

**Before every commit**, scan `docs/` for files that describe behavior touched by the diff (specs, overview, techstack, backlog). If any doc is potentially stale:

1. Report it to the user — doc path, what looks outdated, relevant diff context
2. Resolve together — update the doc or acknowledge it's still accurate
3. Never silently fix. Never silently skip. Stale docs are worse than missing ones.

**Temporal cleanup:** If the current work completes a feature branch, delete its spec and plan files from `docs/superpowers/specs/` and `docs/superpowers/plans/`. These are work orders — once merged, they're noise.

**Backlog cleanup:** If the current work resolves a `BUG-###`, `DEBT-###`, or `GAP-###` item from `docs/backlog.md`, delete that item from the file. Git history is the archive — keep `backlog.md` as a list of what's still open.

This is the pipeline's core discipline. Implementation without doc sync is incomplete.

## Context Hygiene

Multi-needle recall (cross-file reasoning, remembering earlier decisions) degrades past ~200k input tokens regardless of model version. Token cost is solved by prompt cache (~90% savings on hits); quality is the remaining constraint. Rules:

- **Subagent-first** when work is verbose — reading 10+ files, running noisy test suites, parallel-safe chunks, fresh-eye review. Subagent gets fresh context window; orchestrator stays sharp. Skip for <3-5k token tasks (init overhead 5-15k tokens swamps gain).
- **Compact while warm.** Run `/compact` only inside cache TTL (5min default, 1hr extended). Idle compact pays full price to summarize then writes back — wasteful. If you've been away, prefer `/clear` over `/compact`.
- **Clear on topic shift.** Cache is wasted across topic boundaries anyway. Free quality reset.
- **Split sessions** when next phase is a different domain. Cheaper and sharper than dragging accumulated context.
- **Park before /clear** mid-implementation. Write a short handoff note (current state, next step, open questions) so the next session can resume.

Default ordering when context feels heavy: subagent dispatch → compact (if warm) → clear (if cold or topic shifted) → park (if mid-implementation work at risk).

## Coding Principles

Behavioral guardrails to reduce common LLM coding mistakes. Adapted from [Andrej Karpathy's observations](https://github.com/forrestchang/andrej-karpathy-skills) (via `forrestchang/andrej-karpathy-skills`). Bias toward caution over speed; for trivial tasks use judgment.

### 1. Think Before Coding

Don't assume. Don't hide confusion. Surface tradeoffs.

- State assumptions explicitly. If uncertain, ask.
- If multiple valid interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If 200 lines could be 50, rewrite.

Test: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

Touch only what you must. Clean up only your own mess.

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- When your changes orphan imports/vars/functions, remove them. Don't remove pre-existing dead code unless asked.

Test: every changed line traces directly to the user's request.

### 4. Goal-Driven Execution

Define success criteria. Loop until verified.

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## Edit Discipline — Renames & Replace-All

`Edit replace_all: true` is naive whole-file string replace — no AST, no scope, no token boundaries. Running on common identifiers silently corrupts unrelated code (`state` → `swipe` rewrites `SwipeState` to `SwipeSwipe`, import paths, comments, CSS selectors). The trap is invisible until the next type-check.

### Rule (preference order)

1. **LSP rename** — symbol-aware, scope-respecting. Best for typed languages (TS, Rust, Go, Java, Python with pyright, C#).
2. **Per-occurrence Edit with unique surrounding context** — when LSP unavailable. Find each call site via Grep, Edit each with enough surrounding text that `old_string` is unique to that call.
3. **`sed` or scripted bulk replace** — only when term is **8+ characters and unique to the domain** (`Conversation`, `MerchandiseInventory`). Always case-preserving pair: `s/OldName/NewName/g; s/oldName/newName/g; s/OLD_NAME/NEW_NAME/g`. Run build/test cycle immediately.
4. **`Edit replace_all: true`** — only on unique long string literals (URLs, full sentences, hash IDs). Never on identifiers shorter than 8 characters. Never on common English words.

### Pre-flight checklist (any bulk replace)

1. Grep the exact term. Look at count + sample matches.
2. If hits >5 OR length <8 OR common English word → switch to options 1–3.
3. Scan sample matches for false positives (substring inside other identifiers, inside string literals, inside CSS class names that overlap with HTML tags, inside comments).
4. If any doubt remains → per-occurrence Edit. Token cost of caution is far less than cost of debugging silent corruption.

### Banned terms for `replace_all` (always per-occurrence review)

`state`, `name`, `data`, `value`, `item`, `key`, `id`, `type`, `props`, `node`, `text`, `link`, `error`, `result`, `body`, `head`, `main`, `time`, `path`, `file`, `index`, `count`, `child`, `style`, `class`, `tag`, `event`, `target`, `source`, `from`, `to`, `next`, `prev`, `init`, `done`.

### When a `replace_all` slips through

1. `git diff` first — see damage scope.
2. If uncommitted, `git checkout` the file and redo with the right tool.
3. If committed, fix as a NEW commit, not amend (preserves mistake in history).
4. Run type-check / lint / test — usually points straight at remaining corruption.

### Build/test as safety net

Always run after bulk operations. TS: `pnpm check && pnpm test`. Rust: `cargo check && cargo test`. Python: `pyright && pytest`. Go: `go vet && go test ./...`.

## Solo Dev Assumptions

This project is operated by a single developer across multiple Claude Code sessions.

- **No PR self-review** — commit directly to working branch
- **Simple branching** — `main` + feature branches, no rebasing
- **No force push** — every commit is sacred, no rewriting history
- **Session isolation** — each Claude session commits only its own changes
- **No merge conflicts expected** — if one occurs, stop and ask the user

## Project Structure

```
{detected tree — top-level only, brief annotations}
```

## Tech Stack

- **Runtime**: {detected, e.g., Node.js 20+, ESM}
- **Framework**: {detected, e.g., Next.js 14}
{...other detected layers, one bullet each}

> Full techstack analysis pending — see `docs/superpowers/plans/bootstrap.md` task list.

## Commands

```bash
{detected from scripts/Makefile/Cargo — only what exists right now}
```

## Git Notes

- **Only commit current session's changes** — if unrelated uncommitted changes exist from prior work, leave them alone
- **Atomic commits** — one logical change per commit
- **Conventional commits** — `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`

## Planning

- `docs/overview.md` — Product context, data flow, module index (once written)
- `docs/techstack.md` — Tech choices and architecture rules (once written)
{- `docs/specs/` — **Persistent feature specs** — one `.md` per feature, source of truth for what it does and why. Folder + filenames are the catalog (no index file). Each spec starts with `# {Feature Name}` + a one-paragraph intro, so `head -n3 docs/specs/*.md` gives a quick scan.}
{- `docs/backlog.md` — **Deferred items** — `BUG-###` / `DEBT-###` / `GAP-###` queue, deleted on resolve}
- `docs/superpowers/specs/` — Design specs from brainstorming (temporal — deleted after merge)
- `docs/superpowers/plans/` — Implementation plans (temporal — deleted after merge)

{plus any existing docs references}

> **Two kinds of specs:** `docs/specs/` = permanent source of truth (updated as features evolve). `docs/superpowers/specs/` = temporal work orders (deleted after merge).
