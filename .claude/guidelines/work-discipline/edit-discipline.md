# Edit Discipline — Renames, Replace-All & Stale State

Two edit-tool failure families: bulk replace corrupting on common identifiers (§ Preference order), and edits issued against stale file state (§ Stale-state edits).

`Edit replace_all: true` is naive whole-file string replace — no AST, no scope, no token boundaries. Running on common identifiers silently corrupts unrelated code (`state` → `swipe` rewrites `SwipeState` to `SwipeSwipe`, import paths, comments, CSS selectors). Trap invisible until next type-check.

## Preference order

1. **LSP rename** — symbol-aware, scope-respecting. Best for typed languages (TS, Rust, Go, Java, Python with pyright, C#).
2. **Per-occurrence Edit with unique surrounding context** — when LSP unavailable. Grep call sites; each Edit's `old_string` includes enough context to be unique to that call.
3. **`sed` / scripted bulk replace** — only when term is **8+ chars and unique to the domain** (`Conversation`, `MerchandiseInventory`). Always case-preserving pair: `s/OldName/NewName/g; s/oldName/newName/g; s/OLD_NAME/NEW_NAME/g`. Run build/test cycle immediately.
4. **`Edit replace_all: true`** — only on unique long string literals (URLs, full sentences, hash IDs). Never on identifiers <8 chars. Never on common English words.

## Pre-flight checklist (any bulk replace)

1. Grep the exact term. Look at count + sample matches.
2. If hits >5 OR length <8 OR common English word → switch to options 1–3.
3. Scan sample matches for false positives (substrings inside other identifiers, string literals, CSS classes overlapping HTML tags, comments).
4. Any doubt → per-occurrence Edit. Token cost ≪ silent-corruption debug cost.

## Banned terms for `replace_all` (always per-occurrence)

`state`, `name`, `data`, `value`, `item`, `key`, `id`, `type`, `props`, `node`, `text`, `link`, `error`, `result`, `body`, `head`, `main`, `time`, `path`, `file`, `index`, `count`, `child`, `style`, `class`, `tag`, `event`, `target`, `source`, `from`, `to`, `next`, `prev`, `init`, `done`.

## Stale-state edits — Read before first Edit, re-Read after mutation

An Edit failing `"File has not been read yet"` or `"File has been modified since read"` is a state-tracking failure, not a content failure — retrying the same Edit against the same stale state cannot succeed. Read first; on those errors, re-Read:

- **Read before the first Edit of a file each session** — the tool contract requires it; an Edit without a prior Read trips the guard and buys a forced round-trip.
- **Re-Read after either error class above** before the next Edit of that file.
- **Re-Read after any save the harness mutates behind you** — formatter hook, linter-on-commit (prettier / lint-staged repos mutate on every commit).
- **Two consecutive same-file Edit failures = mandatory re-Read**, no exceptions — the loop is unwinnable without fresh state.

## When a `replace_all` slips through

1. `git diff` first — see damage scope.
2. If uncommitted, `git checkout` the file and redo with the right tool.
3. If committed, fix as a NEW commit (preserves mistake in history).
4. Run type-check / lint / test — usually points straight at corruption.
