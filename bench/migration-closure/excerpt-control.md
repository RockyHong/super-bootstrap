### 3. Find what leans on the moved sections

A **moved section** is a section of the old file that loses its heading in step 5. Run `git grep -n -I -F 'CLAUDE.md' -- . ':!CLAUDE.md'` and give every hit one outcome:

- **Link into `CLAUDE.md#<anchor of a moved section>`** → re-point at `.claude/rules/harness.md#<anchor>`, the path written relative to the linking file. Re-point it wherever it sits — a link left behind breaks. The shipped file has no heading for that anchor → open question.
- **Prose naming a moved section by heading** (`CLAUDE.md § Doc Sync`) in a doc, rule or hook → a proposed edit naming `.claude/rules/harness.md`. No edit where the regular sync or nobody owns the text: a pipeline-owned file or section (§ Pipeline-owned), or a file whose frontmatter declares `dimension: history`.
- **The receipt** (`.claude/super-bootstrap-runway.json`) → no change here; step 5 item 4 writes it.
- **Anything else** → no change.
[…]
**Pipeline-owned** (subject to drift check):
- `.claude/rules/harness.md` — the plugin's workflow doctrine, a whole file: placed and resolved current / stale / fork by [`assets/hooks-ensure-infra.md`](assets/hooks-ensure-infra.md) (§ 2a-hooks), never diffed per section; its report row is § 2a-hooks's
- `docs/techstack.md` skeleton sections: Runtime, Framework, Key Dependencies, Build & Distribution (**seed-once** — mechanics at § 2b; stale facts route to the Phase 3 advisory, § Fact-staleness signal), Edit Discipline (fixed prose — body drift-checked against the template), Staged-Tree Verify (the § header + its note drift-checked against the template; the command block below the note is consumer-declared, project-owned, never diffed), Packages (monorepo tier only — the § header + column shape; table rows are consumer-grown, project-owned)
- `docs/overview.md` skeleton sections: Problem, User, Current State (**seed-once** — the body is filled at GAP card pickup, mechanics at § 2b)
- `docs/decisions.md` scope header (the blockquote + `## Closed Forks` heading)
[…]
**Rot scan (mandatory pre-step on re-run; none on a fresh install).** A fresh install — Phase 1 read the state fresh (§ Existing CLAUDE.md) — runs no scan and writes no rot outcome line. On re-run, before Block 1 renders, run the bundled scanner over every pipeline-owned file in scope, and `CLAUDE.md` — `printf '%s\n' <files> | bash "${CLAUDE_PLUGIN_ROOT}/skills/harness-bootstrap/assets/rot-scan.sh" "${CLAUDE_PLUGIN_ROOT}/skills/harness-bootstrap/assets/rename-map.md"` — leaving out of that list `.claude/rules/harness.md` (re-placed whole by § 2a-hooks) and any file whose leading frontmatter declares `dimension: history` — frozen provenance preserves old literals by construction, so a hit there is undeclinable-once and re-fires every sync (the same predicate the commit door's doc-sync gate carries). The skip is this lane only: those files' pipeline-owned sections stay in the per-section drift check. Each `file<TAB>line<TAB>old<TAB>new` line the scanner prints is a candidate hit. One rot row covers one `old` literal in one file, listing every candidate line that `assets/rename-map.md` § Scan guidance judged migratable, and is appended to `bootstrap-sync-report.md` and surfaced to the user. **State the swept set beside the row count** — `literals N` and `files M`, copied from the scanner's last line. A clean needs that line: the scanner exiting nonzero, a run with no summary line from it, or a summary reading `literals 0` or `files 0` is an instrument failure, recorded as **no rot scan** with its cause, never as a clean: zero rot rows is also what a healthy repo produces, so the report line cannot tell the two apart unless it carries the swept set the scanner printed. The row shape:
[…]
The rot scan runs even when every per-section diff is `✓ current` — a stale slash command literal inside a current-shaped doc is invisible to per-section diff (template hasn't drifted; only the literal inside it has).
[…]
> **Pipeline synced.** {N items updated, M already current.}{If a commit landed: " Its full file list: `git show --stat HEAD`."}{If Skeleton-block migration moved a block: " Migrated {blocks moved} from CLAUDE.md to {destinations} — `CLAUDE.md` now {old line count} → {new line count} lines."}{If rule files added: " Rules: +K seeded, summary updated in CLAUDE.md § Rules."}{If language-server pins inserted, per pin: " `{pin}` pinned — install its language server: `{command}`."}{If language-server pins skipped for a user-scope key, per pin: " `{pin}` not pinned — `~/.claude/settings.json` sets `{key}`; a clone on another machine gets no pin for this language."}
[…]
(from `assets/rename-map.md`)
## Retired files

Placed files whose skeleton no longer ships — the rot scan proposes deletion (`⊘ removed`) rather than a rename.

- `.claude/rules/venue-map.md` — the phase → venue map; `/super-bootstrap:autorun` admits by the one judgment in the plugin's `shared/user-wall.md` instead. Drop the CLAUDE.md § Rules bullet with it.
