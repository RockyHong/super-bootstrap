You are executing one step of a repo-sync skill. The governing text of that step is below, quoted from the skill (`[…]` marks a cut between quoted passages):

---
{EXCERPT}
---

The run is a re-run sync of a consumer repo that was bootstrapped months ago. State on disk right now:

The shipped skeleton `assets/rules-ssot-doc-link-skeleton.md` frontmatter:

```yaml
paths:
  - "docs/**/*.md"
  - "/README.md"
  - "plugins/*/README.md"
```

The placed `.claude/rules/ssot-doc-link.md` frontmatter (everything else in the file is byte-identical to the skeleton):

```yaml
paths:
  - "docs/**/*.md"
  - "/README.md"
  - "plugins/*/README.md"
  - "src/notes/**/*.md"
```

The placed `.claude/rules/dimension-discipline.md` is byte-identical to its skeleton (its `paths:` already reads `docs/**/*.md`, `/README.md`, `plugins/*/README.md`).

The consumer's `CLAUDE.md` § Rules section reads:

```markdown
## Rules (auto-load on file match)

- **`dimension-discipline.md`** — fires on `docs/**/*.md`, `/README.md` (root), `plugins/*/README.md` (plus any `paths:` entries the repo appends)
  • Before editing a prose doc, classify what it owns: state (overwrite in place) vs history (append-only, git's job).
- **`ssot-doc-link.md`** — fires on `docs/**/*.md`, `/README.md` (root), `plugins/*/README.md`, `src/notes/**/*.md` (plus any `paths:` entries the repo appends)
  • Link each concept to its SSOT home as you write — born-linked, not back-filled.
- **`react.md`** — fires on `src/components/**/*.tsx`
  • One component per file.
```

The drift check finds both placed rule files current: no row concerns a rule file. The user approves every row the run presents.

Answer in exactly four lines, nothing else:

LINE 1: `CLAUDE_ROWS: ` followed by each `CLAUDE.md` line that any row of this run names for a write — as its own row or as a co-change of another row — quoted, or `CLAUDE_ROWS: NONE`.
LINE 2: `CLAUDE_WRITES: ` followed by each `CLAUDE.md` line exactly as it reads after the run writes it, or `CLAUDE_WRITES: NONE` if the run writes no `CLAUDE.md` line.
LINE 3: `MATCH_LINES: ` followed by each per-section comparison line the run prints for a `CLAUDE.md` § Rules bullet it compared and found matching, each prefixed with the rule file it sits under, or `MATCH_LINES: NONE`.
LINE 4: `IF_NO_CLAUDE_WRITE: ` followed by `passes` or `halts` — the § 2c gate's outcome if every rule-file write the approved rows call for has landed but no `CLAUDE.md` line has been written.
