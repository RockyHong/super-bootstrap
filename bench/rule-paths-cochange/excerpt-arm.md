**Registration rule** (2a / 2a-scale / 2b plantings, 2a-scale / 2b-adopt deletions): a durable artifact this run places for the first time or deletes earns its own sync-report row — status `⊕ new` for a planting, `⊘ removed` for a deletion:

```
registration: {artifact} → {surfaces, or none}
```

`{surfaces}` names the consumer-authored surfaces that enumerate the artifact's class — a table or list carrying one entry per member (a glob that already covers the artifact needs no edit and is not a surface; a curated shortlist of a few files is not an enumeration). Grep each of five places for the artifact's path and for its parent directory string (`docs/`, `.claude/skills/`), and name every place whose hit is such a list:

1. `.claude/rules/*.md` `paths:` frontmatter entries that name paths literally
2. root `README.md` — any table or list naming `docs/` paths
3. `docs/**/README.md` and `docs/overview.md` § Module Index
4. `.claude/rules/*.md` bodies — any table or list naming `docs/` paths (ownership / routing)
5. `CLAUDE.md` § Rules (one bullet per path-scoped rule file) and § Planning (one index line per doc) — project-owned registration surfaces, where the section exists. Planting → append the artifact's bullet / index line at the end of the section's list when the section holds none for it; move or deletion → re-point or drop that artifact's own line. The run touches only the line of the artifact the row names and rewrites no other line

The row resolves `updated` once every named surface is edited, before § 2c runs, in the same commit — or `none`, earned only when all five greps return nothing. An unresolved row halts § 2c like a drifted one. The 2a-hooks step sits outside this rule, scripts and `.claude/rules/harness.md` included: the `.claude/settings.json` and `.gitignore` entries that step already writes are its registration.

[…]

**Project-owned** (never touched):
- `CLAUDE.md` — the whole file: seeded once from `assets/claude-md-skeleton.md` when the run finds none (§ 2b; placeholders per § 2b Placeholders), consumer-edited from then on, never drift-diffed. The run's only later writes are registration lines in § Rules / § Planning (§ Registration rule) and a placed doc rule's own § Rules bullet, rewritten on that rule's approved `paths:` drift row (§ 2b Per-doc handling); a legacy-state file is rewritten once, on the user's confirm, by § Doctrine migration
- `.claude/rules/ssot-doc-link.md`, `.claude/rules/dimension-discipline.md` `paths:` tail — the entries after the skeleton's last `paths:` entry (a consumer adds one to fire the rule on a folder its `.claude/doc-surface` declares — Phase 3 § Doc-rule coverage)

[…]

**Per-doc handling:**

- **Missing** → fill placeholders, write.
- **`CLAUDE.md`** → absent → fill placeholders (§ Placeholders), write. Present → no diff and no section row: the file stays as the consumer left it, apart from the § Rules / § Planning registration lines this run's plantings and deletions earn (§ Registration rule) and a placed doc rule's § Rules bullet its approved `paths:` drift row rewrites (next bullet).
- **Exists, drifted in pipeline-owned section** → diff that section vs template — only the part § Pipeline-owned marks drift-checked (a section whose body is consumer-owned, such as `docs/techstack.md` § Staged-Tree Verify's command block or § Packages' rows, diffs its header and fixed note only; a placed doc rule — `ssot-doc-link`, `dimension-discipline` — diffs its `paths:` list on the skeleton's entries only: entries after the skeleton's last one are its consumer tail, which leaves the file `✓ current` and which no drift row removes or reverts, while an entry interleaved among the skeleton's entries is drift, and approving the row moves it into the tail; when the row changes the skeleton's own entries — a row that only moves interleaved entries into the tail changes none — and the rule's `CLAUDE.md` § Rules bullet restates a fires-on list that does not match the resulting skeleton entries, compared entry by entry with a parenthetical gloss after an entry ignored, the row names that bullet as its co-change and Block 2 shows the bullet's before and after lines beside the rule's diff — approving the row rewrites the bullet's skeleton entries to the resulting ones, keeps its consumer-tail entries, its other text and every other line, and the row resolves `updated` only once the rule file and the bullet are both written) — present to user, get approval per section, write approved.
