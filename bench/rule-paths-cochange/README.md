# bench/rule-paths-cochange — micro-test for the doc-rule `paths:` drift row's `CLAUDE.md` § Rules co-change

Test surface for [`skills/harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
§ 2b Per-doc handling's drifted-section bullet — the clause on a placed doc rule (`ssot-doc-link`,
`dimension-discipline`) whose skeleton `paths:` entries change — together with the § Registration
rule's surface 5 and the § Project-owned `CLAUDE.md` line that bound what a re-run may write in
`CLAUDE.md`. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. Same protocol and shape as the
sibling [`bench/lsp-pin-user-scope/`](../lsp-pin-user-scope/README.md): reading-only, no fixture
repo — the model is handed the governing excerpt plus the on-disk state and asked what the row
carries and writes.

**Copy under test:** the in-repo dev copy of `SKILL.md`. Each excerpt is three quoted passages joined
by a `[…]` line: the § Registration rule (its opening line through the paragraph after the surface
list), the § Project-owned head with its `CLAUDE.md` and doc-rule tail lines, and § 2b Per-doc
handling from its heading through the drifted-section bullet. [`excerpt-arm.md`](excerpt-arm.md) holds
the shipped text — each passage byte-exact against the working-tree file (`diff` clean, passage by
passage; second arm: `SKILL.md` lines 278-292, 309-311 and 471-475 of the working tree, after the
Registration rule item 5 lost its drift-row clause and the § 2b bullet gained the entry-by-entry
comparison, the gloss-ignored and move-only-row clauses and the Block 2 before/after lines); [`excerpt-control.md`](excerpt-control.md) holds the same three passages at the commit
before the change (`git show HEAD:` at authoring time, `8d97cee`). Prompt = the scenario file with its
`{EXCERPT}` line replaced by the excerpt file ([`run.sh`](run.sh) `<control|arm> <n> <out-file>`).

## Protocol

Arms run headless (`claude -p --model haiku --tools "" --strict-mcp-config --setting-sources ""`)
with the prompt on stdin, three trials per arm. The scenario body is byte-identical across arms, so
the excerpt is the only variable. Each answer is four lines: `CO-CHANGE:` (the `CLAUDE.md` lines the
drift row names as co-change, or `NONE`), `CLAUDE_WRITES:` (each `CLAUDE.md` line as written, or
`NONE`), `RESOLUTION:` (the row once every listed write landed), `IF_RULE_ONLY:` (the row when the rule
file is written and no `CLAUDE.md` line is).

- **Scenario 1 — stale bullet** ([`scenario-1.md`](scenario-1.md)). The placed `ssot-doc-link.md`
  `paths:` reads `README.md` where the skeleton now reads `/README.md`; its `CLAUDE.md` § Rules bullet
  restates bare `README.md`. `dimension-discipline.md` and its bullet are current; a `react.md` bullet
  sits beside them. The user approves the drift row. **Axis:** does the row name the bullet as a
  co-change, rewrite it to `/README.md`, and resolve `updated` only when both writes land?
- **Scenario 2 — guard: different rule's bullet** ([`scenario-2.md`](scenario-2.md)). Same rule-file
  drift, but the `ssot-doc-link` bullet already reads `/README.md` (root); the `dimension-discipline`
  bullet restates bare `README.md` while its rule file is current (no drift row). **Axis:** does the
  run keep its hands off a bullet no drift row names, and add no co-change where the drifting rule's
  own bullet already matches? Regression guard, not a RED.
- **Scenario 3 — guard: interleaved-entry row** ([`scenario-3.md`](scenario-3.md)). Added with the
  second arm (wording refresh). The placed `ssot-doc-link.md` `paths:` holds a consumer entry
  (`src/notes/**/*.md`) interleaved among the skeleton's entries; the skeleton entries are otherwise
  current. The `CLAUDE.md` bullet reads `/README.md` (root) with the gloss and matches the skeleton. The
  drift row only moves the interleaved entry into the tail. **Axis:** does the run name no co-change and
  leave the bullet untouched, since the row changes no skeleton entry and the gloss is ignored?
  Regression guard, not a RED.

**Pre-registration** (written before the first trial):

| Scenario | Control expected | Arm expected |
|---|---|---|
| 1 | `CO-CHANGE: NONE`, `CLAUDE_WRITES: NONE`, `RESOLUTION: updated`, `IF_RULE_ONLY: updated` 3/3 — rule file only, bullet untouched | `CO-CHANGE:` the `ssot-doc-link.md` bullet; `CLAUDE_WRITES:` that bullet with `` `/README.md` `` and its `(plus any …)` parenthetical kept, no other line; `RESOLUTION: updated`; `IF_RULE_ONLY:` not `updated` (unresolved / halts) 3/3 |
| 2 | `CO-CHANGE: NONE`, `CLAUDE_WRITES: NONE`, `RESOLUTION: updated` 3/3 | same as control 3/3 — the `dimension-discipline` bullet untouched, no co-change named; `IF_RULE_ONLY: updated` |
| 3 (second arm only; registered before its trials) | not run | `CO-CHANGE: NONE`, `CLAUDE_WRITES: NONE`, `RESOLUTION: updated`, `IF_RULE_ONLY: updated` 3/3 — bullet untouched |

Budget: one wording re-tune of the shipped clause; a second miss on the arm stops the work and
reports.

## Findings

Run 2026-11-20, `claude -p --model haiku --tools "" --strict-mcp-config --setting-sources ""`,
three trials per arm, all trials of a scenario in parallel. Controls ran against the first pass and
are unchanged (control bytes unchanged). The arm ran twice: the first pass against the first wording
(scenarios 1-2, 3/3 GREEN), then the second pass below against the refreshed wording (scenarios 1-3, no
re-tune between); the tables hold the second pass. Lines as returned, `LINE n:` labels dropped; quoted `CLAUDE.md` lines shortened
to the fires-on part with `…` for the bullet's unchanged head and tail (bullet head
`` - **`ssot-doc-link.md`** — fires on ``, tail (plus any `paths:` entries the repo appends), both
present in every arm trial). Raw trial outputs are not kept in the tree.

### Scenario 1 — stale bullet

| Arm | Trial | CO-CHANGE | CLAUDE_WRITES | RESOLUTION | IF_RULE_ONLY |
|---|---|---|---|---|---|
| Control (`8d97cee`) | 1 | NONE | NONE | updated | updated |
| Control | 2 | NONE | NONE | updated | updated |
| Control | 3 | NONE | NONE | updated | updated |
| Arm (shipped, refreshed) | 1 | "- **`ssot-doc-link.md`** — fires on `docs/**/*.md`, `README.md`, `plugins/*/README.md` (plus any `paths:` entries the repo appends)" | - **`ssot-doc-link.md`** — fires on `docs/**/*.md`, `/README.md`, `plugins/*/README.md` (plus any `paths:` entries the repo appends) | updated | unresolved, which halts § 2c like a drifted row |
| Arm | 2 | "- **`ssot-doc-link.md`** — fires on `docs/**/*.md`, `README.md`, `plugins/*/README.md` (plus any `paths:` entries the repo appends)" | - **`ssot-doc-link.md`** — fires on `docs/**/*.md`, `/README.md`, `plugins/*/README.md` (plus any `paths:` entries the repo appends) | updated | unresolved |
| Arm | 3 | "- **`ssot-doc-link.md`** — fires on `docs/**/*.md`, `README.md`, `plugins/*/README.md` (plus any `paths:` entries the repo appends)" | "- **`ssot-doc-link.md`** — fires on `docs/**/*.md`, `/README.md`, `plugins/*/README.md` (plus any `paths:` entries the repo appends)" | updated | unresolved |

### Scenario 2 — guard: different rule's bullet

| Arm | Trial | CO-CHANGE | CLAUDE_WRITES | RESOLUTION | IF_RULE_ONLY |
|---|---|---|---|---|---|
| Control (`8d97cee`) | 1 | NONE | NONE | updated | updated |
| Control | 2 | NONE | NONE | updated | updated |
| Control | 3 | NONE | NONE | updated | updated |
| Arm (shipped, refreshed) | 1 | NONE | NONE | updated | updated |
| Arm | 2 | NONE | NONE | updated | updated |
| Arm | 3 | NONE | NONE | updated | updated |

### Scenario 3 — guard: interleaved-entry row (arm only)

| Arm | Trial | CO-CHANGE | CLAUDE_WRITES | RESOLUTION | IF_RULE_ONLY |
|---|---|---|---|---|---|
| Arm (shipped, refreshed) | 1 | NONE | NONE | updated | updated |
| Arm | 2 | NONE | NONE | updated | updated |
| Arm | 3 | NONE | NONE | updated | updated |

**Verdict (second arm): RED on the control, GREEN on the refreshed arm, 3/3 each, all four columns, scenarios 1-3.** The `8d97cee` wording
leaves the stale `ssot-doc-link` bullet untouched and resolves the row `updated` on the rule file
alone 3/3. The shipped wording names that bullet as the co-change, rewrites only its `README.md`
entry to `/README.md` with the parenthetical kept, and holds the row unresolved when only the rule
file landed, 3/3. The guard holds 3/3 on both arms: the stale `dimension-discipline` bullet, which no
drift row names, stays untouched, and an already-matching `ssot-doc-link` bullet earns no co-change.
Scenario 3 holds 3/3: a row that only moves an interleaved consumer entry into the tail names no
co-change and leaves the matching `/README.md (root)` bullet untouched, with the gloss ignored.

**Declared bounds.**
1. The model rewrote the entry without the skeleton bullet's `(root)` annotation. The clause rewrites
   the bullet's entries, not its annotations, so this matches the text; a consumer bullet reads
   `` `/README.md` `` with no `(root)` after the sync.
2. The § 2c gate no longer carries a co-change sentence, and the Registration rule's item 5 carries no
   drift-row clause; arm trials reached `unresolved` from the § 2b per-doc bullet and the
   § Registration rule's halt line alone.
3. The co-change rides a drift row. An install whose rule file a sync already moved to `/README.md`
   keeps a stale bullet: no drift row fires, so nothing names it (Scenario 2's guard measures that
   the run leaves such a bullet alone).
4. N=3 per arm per scenario, one model tier. Scenario 3 has no control run (arm-only guard).
