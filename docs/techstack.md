# Tech Stack

> Living doc — **state dimension only** (what the stack *is* now). Skeleton sections (Runtime / Framework / Key Dependencies / Build & Distribution, seeded at scaffold from detected facts; Edit Discipline, fixed prose). Grown sections (Architecture Rules / Coding Patterns) start empty and grow via doc-sync — every commit that touches a relevant area triggers a sync proposal. Rejected stack directions are history, not state → [`docs/decisions.md`](decisions.md), never a section here. See `CLAUDE.md` Doc Sync.

## Runtime

No language runtime, no build step. The product is markdown: skills are `SKILL.md` files with YAML frontmatter, agents and shared fragments are markdown, loaded directly by Claude Code's plugin loader.

## Framework

Claude Code plugin architecture. A root `.claude-plugin/marketplace.json` declares the self-hosted marketplace; `plugins/super-bootstrap/.claude-plugin/plugin.json` declares the plugin. Layout: `plugins/super-bootstrap/{skills,agents,shared}`. The `source` field in `marketplace.json` (`./plugins/super-bootstrap`) is the install boundary — only that subtree ships to installers; repo-root files (this doc, CLAUDE.md, the `docs/work/` cards) are dev-workspace-only and never reach a user's project.

## Key Dependencies

- **[super-bootstrap](https://github.com/RockyHong/super-bootstrap)** (self-pin) — core pin: the scaffolded CLAUDE.md routes every door through `/super-bootstrap:*` and the committed `commit-channel.sh` names `/super-bootstrap:commit`, so the project pin must resolve them on any boundary without the authoring device's user-scope settings (fresh clone, cloud session).
- **[andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — core pin. `karpathy-guidelines` is the default coding standard; the always-scaffolded `CODING_STANDARDS.md` overrides it only where sections fill.
- **No process harness is a dependency.** The scaffolded CLAUDE.md's route rows name disciplines, not process-harness skill entries, so a process harness ([superpowers](https://github.com/obra/superpowers) or another) is an ordinary `/super-bootstrap:resolve-plugins` candidate the user may take or drop. Rationale + cut map: [`docs/specs/harness-architecture.md`](specs/harness-architecture.md).
- Discovery sources for `/super-bootstrap:resolve-plugins`: Anthropic plugin marketplace, MCP registry, everything-claude-code, awesome-claude-skills, VoltAgent/awesome-agent-skills (see README § Sources).

## Build & Distribution

No build. Distribution is git + Claude Code marketplace:

```
/plugin marketplace add rockyhong/super-bootstrap
/plugin install super-bootstrap@super-bootstrap
```

Versioned via the `/release` skill. `plugin.json` is the single version source — Claude Code resolves a plugin's version from `plugin.json` first, so `marketplace.json` carries no `version`; `/release` bumps `plugin.json` and re-syncs the marketplace `plugins[0].description` mirror from `plugin.json`, then commits + tags. Published by pushing to `github.com/RockyHong/super-bootstrap`; installs with `autoUpdate` pull the new version.

## Architecture Rules

> Grows via doc-sync as patterns crystallize. Module boundaries, data flow direction, dependency philosophy, layering rules.

- **Dispatch-shell + typed-agent split** — skills with bounded-judgment verbs route through a dispatch shell + typed agent pair; monolithic skill bodies don't own execution judgment. → [`skill-authoring.md`](../.claude/rules/skill-authoring.md)
- **Frozen-asset versioning** — shipped assets are placed by mechanical copy/merge at release time and never regenerated, eliminating inter-repo drift. → [`ensure-infra.md`](../plugins/super-bootstrap/skills/drain/assets/ensure-infra.md)
- **Skeleton/dogfood sync direction** — dogfood-harness edits carry their shipped-skeleton counterpart in the edit's closure; skeletons must be self-contained (no dogfood-only wiring). → [`repo-boundary.md`](../.claude/rules/repo-boundary.md)
- **Gateway-inline vs dispatched lanes** — closure-judged (not diff-size-judged): build phases dispatch to clean subagents; transcription applies inline; parallel within a phase only; create-new-file subagents foreground. → [`CLAUDE.md` § Dispatch](../CLAUDE.md#dispatch--who-holds-each-phase)

## Coding Patterns

> Grows via doc-sync as patterns crystallize. Import style, error handling convention, naming, class-vs-function bias, type usage.

- **POSIX-bash asset dialect** — code assets use POSIX `bash`; on a PowerShell-primary device, run via the Bash tool or rewrite in its idiom. → [`release/SKILL.md`](../.claude/skills/release/SKILL.md)

## Edit Discipline

Two edit-tool failure families: bulk replace corrupting on common identifiers (preference order + checklist below), and edits issued against stale file state (§ Stale-state edits).

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

**Stale-state edits — Read before first Edit, re-Read after mutation:**

An Edit failing `"File has not been read yet"` or `"File has been modified since read"` is a state-tracking failure, not a content failure — retrying the same Edit against the same stale state cannot succeed. Read first; on those errors, re-Read:

- **Read before the first Edit of a file each session** — `Write` always requires a prior Read; `Edit`'s guard is relaxed for newer models (CC 2.1.208+) but reading first remains the discipline — an unread edit is a blind edit.
- **Re-Read after either error class above** before the next Edit of that file.
- **Re-Read after any save that lands behind your read-tracker** — formatter hook, linter-on-commit (prettier / lint-staged repos mutate on every commit), and any file-writing subagent that returned (a skill may have dispatched it): it wrote in its own context, invisible to yours. Prevention half — sequencing the writer dispatch itself — in [`dispatch-run-mode.md`](../.claude/guidelines/work-discipline/dispatch-run-mode.md).
- **`git diff` output is not a Read** — after reviewing another agent's edits via diff, Read the file itself before editing it.
- **Two consecutive same-file Edit failures = mandatory re-Read**, no exceptions — the loop is unwinnable without fresh state.

**When a `replace_all` slips through:**

1. `git diff` first — see damage scope.
2. If uncommitted, `git checkout` the file and redo with the right tool.
3. If committed, fix as a NEW commit (preserves mistake in history).
4. Run type-check / lint / test — usually points straight at corruption.

Always run build/test after bulk operations.
