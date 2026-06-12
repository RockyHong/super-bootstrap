# Tech Stack

> Living doc. Skeleton sections (Runtime / Framework / Key Dependencies / Build & Distribution) seeded at scaffold from detected facts. Grown sections (Architecture Rules / Coding Patterns / Rejected Alternatives) start empty and grow via doc-sync — every commit that touches a relevant area triggers a sync proposal. See `CLAUDE.md` Doc Sync.

## Runtime

{detected from primary manifest — e.g. Node.js 20+ (ESM), Python 3.12, Rust 1.78, Go 1.22}

## Framework

{detected — e.g. Next.js 14, FastAPI, Axum, Echo. Drop the section if no framework.}

## Key Dependencies

{top-level deps grouped by role — runtime, dev, test, build. Skim from manifest, not exhaustive.}

## Build & Distribution

{commands as they exist in scripts / Makefile / Cargo.toml / etc. — copy verbatim, don't invent.}

## Architecture Rules

> Grows via doc-sync as patterns crystallize. Module boundaries, data flow direction, dependency philosophy, layering rules.

## Coding Patterns

> Grows via doc-sync as patterns crystallize. Import style, error handling convention, naming, class-vs-function bias, type usage.

## Rejected Alternatives

> Grows via doc-sync when a decision documents what was considered and dropped, and why.

## Edit Discipline

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
