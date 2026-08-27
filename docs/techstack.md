# Tech Stack

> Living doc — **state dimension only** (what the stack *is* now). Skeleton sections (Runtime / Framework / Key Dependencies / Build & Distribution, seeded at scaffold from detected facts; Edit Discipline, fixed prose). Grown sections (Architecture Rules / Coding Patterns) start empty and grow via doc-sync — every commit that touches a relevant area triggers a sync proposal, admitted per § Doc Sync. Rejected stack directions are history, not state → [`docs/decisions.md`](decisions.md), never a section here. See [`CLAUDE.md` Doc Sync](../CLAUDE.md#doc-sync-non-negotiable).

## Runtime

No build step, no runtime dependency. The product is markdown: skills are `SKILL.md` files with YAML frontmatter, agents and shared fragments are markdown, loaded directly by [Claude Code's plugin loader](overview.md#key-boundaries). Python 3 is an optional runtime two skill assets invoke for zero-dispatch mechanical extraction (`help`'s menu, `todo`'s board render); each degrades — manual scan or agent dispatch — when `python3` is absent.

## Framework

Claude Code plugin architecture. A root `.claude-plugin/marketplace.json` declares the self-hosted marketplace; `plugins/super-bootstrap/.claude-plugin/plugin.json` declares the plugin. Layout: `plugins/super-bootstrap/{skills,agents,shared}`. `plugin.json` declares **no** `skills` array, so the loader discovers `skills/*/` itself and every folder ships — an explicit array is an allowlist, and any folder left out of it never loads, with no error. The `source` field in `marketplace.json` (`./plugins/super-bootstrap`) is the [install boundary](overview.md#key-boundaries) — only that subtree ships to installers; repo-root files (this doc, CLAUDE.md, the `docs/work/` cards) are dev-workspace-only and never reach a user's project.

## Key Dependencies

- **[super-bootstrap](https://github.com/RockyHong/super-bootstrap)** (self-pin) — core pin: the scaffolded CLAUDE.md routes every door through `/super-bootstrap:*` and the committed `commit-channel.sh` names `/super-bootstrap:commit`, so the project pin must resolve them on any boundary without the authoring device's user-scope settings (fresh clone, cloud session).
- **[mattpocock-skills](https://github.com/mattpocock/skills)** — **paired pin**, a class of its own beside the core pin: `/super-bootstrap:harness-bootstrap` seeds it on a fresh install; on a sync it renders a declinable [`⊕ new` row](../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md) (default accept) — a repo drops it by setting `"mattpocock-skills@mattpocock": false` in `.claude/settings.json`, never by deleting the key (a deleted key returns as that same row on the next sync). Dropping breaks nothing: no runway door depends on it and [no surface the pipeline commits into a consumer repo names its commands](specs/harness-architecture.md#4-the-seam-runtime-orthogonal-setup-time-composed), so the drop is a settings edit with no doc change. `/super-bootstrap:resolve-plugins` offers it for drop and never re-proposes it once dropped. Operating posture: [`docs/specs/mattpocock-coexistence.md`](specs/mattpocock-coexistence.md).
- **No process harness is a dependency.** The scaffolded CLAUDE.md's route rows name disciplines, not process-harness skill entries, so any process harness other than the paired pin above ([superpowers](https://github.com/obra/superpowers) or another) is an ordinary `/super-bootstrap:resolve-plugins` candidate the user may take or drop. Rationale + cut map: [`docs/specs/harness-architecture.md`](specs/harness-architecture.md).
- Discovery sources for `/super-bootstrap:resolve-plugins`: Anthropic plugin marketplace, MCP registry, everything-claude-code, awesome-claude-skills, VoltAgent/awesome-agent-skills (see [README § Sources](../README.md#sources)).

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
- **Gateway-inline vs dispatched lanes** — closure-judged (not diff-size-judged): build phases dispatch to clean subagents; transcription applies inline; parallel within a phase only; writer run mode keyed on path overlap. → [`CLAUDE.md` § Dispatch](../CLAUDE.md#dispatch--who-holds-each-phase)

## Coding Patterns

> Grows via [doc-sync](../CLAUDE.md#doc-sync-non-negotiable) as patterns crystallize. Import style, error handling convention, naming, class-vs-function bias, type usage.

- **POSIX-bash asset dialect** — shell code assets use POSIX `bash`; on a PowerShell-primary device, run via the Bash tool or rewrite in its idiom. → [`release/SKILL.md`](../.claude/skills/release/SKILL.md)
- **Portable-awk asset dialect** — shipped awk programs stay in the subset every consumer `awk` accepts: no interval expressions (`{n,}` / `{n,m}`), explicit `[ \t]` over POSIX classes, `tolower()` only behind the lead-byte probe (a Latin-1 / cp1252 ctype rewrites UTF-8 lead bytes; letters of every script must survive slugging). Consumer `awk` resolves to mawk on Debian/Ubuntu (1.3.4-20200120 on 20.04/22.04) and one-true-awk on macOS (pre-2019 builds), both of which read `{3,}` as literal braces — a regex that leans on them fails silently, never with a parse error. Construct lock: [`tests/doc-links.test.sh`](../tests/doc-links.test.sh); the cross-awk behavior check runs under Docker (`debian:bullseye-slim` + `original-awk` / `mawk` / `gawk`), not in the suite. → [`commit/assets/doc-links.sh`](../plugins/super-bootstrap/skills/commit/assets/doc-links.sh)
- **Fork-free inner loops in shell assets** — a shipped shell asset that walks a whole doc surface keeps subprocesses out of its per-item loops: per-file derived tables (heading-slug lists) are computed in one pass and memoized (bash-3.2-safe `eval`-keyed variables — no `declare -A`), and helpers return through globals rather than stdout, since a stdout return costs a command substitution per call. Cost scales as items × forks, and a fork is ~10-20 ms on msys/Git-Bash hosts, so one helper fork per link is what pushes a whole-surface pass past the Bash tool's 120 s default. Construct lock: [`tests/doc-links.test.sh`](../tests/doc-links.test.sh). → [`commit/assets/doc-links.sh`](../plugins/super-bootstrap/skills/commit/assets/doc-links.sh)
- **Python mechanical-extraction assets** — where a skill's mechanical half (parse + classify + render, zero judgment) outgrows shell, it ships as a Python 3 script invoked via `python3 "${CLAUDE_PLUGIN_ROOT}/…"`, UTF-8/LF output, stdout = the product and stderr = diagnostics, with a declared degrade path when `python3` is absent. → [`help/assets/render-menu.py`](../plugins/super-bootstrap/skills/help/assets/render-menu.py), [`todo/assets/render-board.py`](../plugins/super-bootstrap/skills/todo/assets/render-board.py)

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
- **Re-Read after any save that lands behind your read-tracker** — formatter hook, linter-on-commit (prettier / lint-staged repos mutate on every commit), and any file-writing subagent that returned (a skill may have dispatched it): it wrote in its own context, invisible to yours. Prevention half — sequencing the writer dispatch itself — in [`dispatch-run-mode.md`](../.claude/guidelines/work-discipline/dispatch-run-mode.md).
- **`git diff` output is not a Read** — after reviewing another agent's edits via diff, Read the file itself before editing it.
- **Two consecutive same-file Edit failures = mandatory re-Read**, no exceptions — the loop is unwinnable without fresh state.

**When a `replace_all` slips through:**

1. `git diff` first — see damage scope.
2. If uncommitted, `git checkout` the file and redo with the right tool.
3. If committed, fix as a NEW commit (preserves mistake in history).
4. Run type-check / lint / test — usually points straight at corruption.

Always run build/test after bulk operations.
