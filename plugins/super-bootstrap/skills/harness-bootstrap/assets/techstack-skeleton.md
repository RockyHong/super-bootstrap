# Tech Stack

> Living doc — **state dimension only** (what the stack *is* now). Skeleton sections (Runtime / Framework / Key Dependencies / Build & Distribution, seeded at scaffold from detected facts; Edit Discipline, fixed prose). Grown sections (Architecture Rules / Coding Patterns) start empty and grow via doc-sync — every commit that touches a relevant area triggers a sync proposal, admitted per § Doc Sync. Rejected stack directions are history, not state → [`docs/decisions.md`](decisions.md), never a section here. See `CLAUDE.md` Doc Sync.

## Runtime

{detected from primary manifest — e.g. Node.js 20+ (ESM), Python 3.12, Rust 1.78, Go 1.22}

## Framework

{detected — e.g. Next.js 14, FastAPI, Axum, Echo. Drop the section if no framework.}

## Key Dependencies

{top-level deps grouped by role — runtime, dev, test, build. Skim from manifest, not exhaustive.}

## Build & Distribution

{commands as they exist in scripts / Makefile / Cargo.toml / etc. — copy verbatim, don't invent.}

{## Packages}

{Monorepo tier only — drop this whole section for a single-package repo. One row per workspace package, seeded at scaffold from workspace-manifest detection; new packages land via doc-sync.}

{| Package | Path | Role | Build command |}
{|---|---|---|---|}
{| {name} | {apps/web} | {what it is — app / shared lib / ui kit} | {per-package build, e.g. `pnpm --filter web build`} |}

## Architecture Rules

> Grows via doc-sync as patterns crystallize. Module boundaries, data flow direction, dependency philosophy, layering rules.

## Coding Patterns

> Grows via doc-sync as patterns crystallize — **descriptive reference**: how this code is actually written, read on demand, safe to be cold. Import style, class-vs-function bias, type usage, recurring idioms. A convention that binds — imperative, obeyed at every code touch — is recorded in `CODING_STANDARDS.md`.

## Edit Discipline

Two edit-tool failure families: bulk replace corrupting on common identifiers (preference order + checklist below), and edits issued against stale file state (§ Stale-state edits).

`Edit replace_all: true` is naive whole-file string replace — no AST, no scope, no token boundaries. Running on common identifiers silently corrupts unrelated code (`state` → `swipe` rewrites `SwipeState` to `SwipeSwipe`, import paths, comments, CSS selectors). The trap is invisible until the next type-check.

**Preference order:**

1. **Per-occurrence Edit with unique surrounding context** — enumerate call sites first (LSP `findReferences` where a server is configured, Grep otherwise); each Edit's `old_string` includes enough context to be unique to that call.
2. **`sed` / scripted bulk replace** — only when term is **8+ chars and unique to the domain** (`Conversation`, `MerchandiseInventory`). Always case-preserving pair: `s/OldName/NewName/g; s/oldName/newName/g; s/OLD_NAME/NEW_NAME/g`. Run build/test cycle immediately.
3. **`Edit replace_all: true`** — only on unique long string literals (URLs, full sentences, hash IDs). Never on identifiers <8 chars. Never on common English words.

**Pre-flight checklist (any bulk replace):**

1. Grep the exact term. Look at count + sample matches.
2. If hits >5 OR length <8 OR common English word → switch to options 1–3.
3. Scan sample matches for false positives (substrings inside other identifiers, string literals, CSS classes overlapping HTML tags, comments).
4. Any doubt → per-occurrence Edit. Caution token cost ≪ silent-corruption debug cost.

**Banned terms for `replace_all`** (always per-occurrence):
`state`, `name`, `data`, `value`, `item`, `key`, `id`, `type`, `props`, `node`, `text`, `link`, `error`, `result`, `body`, `head`, `main`, `time`, `path`, `file`, `index`, `count`, `child`, `style`, `class`, `tag`, `event`, `target`, `source`, `from`, `to`, `next`, `prev`, `init`, `done`.

**Stale-state edits — Read before first Edit, re-Read after mutation:**

An Edit failing `"File has not been read yet"` or `"File has been modified since read"` is a state-tracking failure, not a content failure — retrying the same Edit against the same stale state cannot succeed. Read first; on those errors, re-Read:

- **Read before the first Edit of a file each session** — `Write` always requires a prior Read; `Edit`'s guard is relaxed for newer models (CC 2.1.208+) but reading first remains the discipline — an unread edit is a blind edit.
- **Re-Read after either error class above** before the next Edit of that file.
- **Re-Read after any save that lands behind your read-tracker** — formatter hook, linter-on-commit (prettier / lint-staged repos mutate on every commit), and any file-writing subagent that returned (a skill may have dispatched it): it wrote in its own context, invisible to yours.
- **`git diff` output is not a Read** — after reviewing another agent's edits via diff, Read the file itself before editing it.
- **Two consecutive same-file Edit failures = mandatory re-Read**, no exceptions — the loop is unwinnable without fresh state.

**When a `replace_all` slips through:**

1. `git diff` first — see damage scope.
2. If uncommitted, `git checkout` the file and redo with the right tool.
3. If committed, fix as a NEW commit (preserves mistake in history).
4. Run type-check / lint / test — usually points straight at corruption.

Always run build/test after bulk operations.
