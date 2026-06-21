# Tech Stack

> Living doc — **state dimension only** (what the stack *is* now). Skeleton sections (Runtime / Framework / Key Dependencies / Build & Distribution) seeded at scaffold from detected facts. Grown sections (Architecture Rules / Coding Patterns) start empty and grow via doc-sync — every commit that touches a relevant area triggers a sync proposal. Rejected stack directions are history, not state → [`docs/decisions.md`](decisions.md), never a section here. See `CLAUDE.md` Doc Sync.

## Runtime

No language runtime, no build step. The product is markdown: skills are `SKILL.md` files with YAML frontmatter, agents and shared fragments are markdown, loaded directly by Claude Code's plugin loader.

## Framework

Claude Code plugin architecture. A root `.claude-plugin/marketplace.json` declares the self-hosted marketplace; `plugins/super-bootstrap/.claude-plugin/plugin.json` declares the plugin. Layout: `plugins/super-bootstrap/{skills,agents,shared}`. The `source` field in `marketplace.json` (`./plugins/super-bootstrap`) is the install boundary — only that subtree ships to installers; repo-root files (this doc, CLAUDE.md, backlog) are dev-workspace-only and never reach a user's project.

## Key Dependencies

- **[superpowers](https://github.com/obra/superpowers)** — the workflow pipeline (brainstorm → spec → plan → execute) baked into the scaffolded CLAUDE.md.
- **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — `karpathy-guidelines` skill invoked before code edits (coding principles).
- Discovery sources for `/super-bootstrap:resolve-plugins`: Anthropic plugin marketplace, MCP registry, everything-claude-code, awesome-claude-skills, VoltAgent/awesome-agent-skills (see README § Sources).

## Build & Distribution

No build. Distribution is git + Claude Code marketplace:

```
/plugin marketplace add rockyhong/super-bootstrap
/plugin install super-bootstrap@super-bootstrap
```

Versioned via the `/release` skill (bumps `marketplace.json` + `plugin.json` versions, commits, tags). Published by pushing to `github.com/RockyHong/super-bootstrap`; installs with `autoUpdate` pull the new version.

## Architecture Rules

> Grows via doc-sync as patterns crystallize. Module boundaries, data flow direction, dependency philosophy, layering rules.

## Coding Patterns

> Grows via doc-sync as patterns crystallize. Import style, error handling convention, naming, class-vs-function bias, type usage.

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
