# bench/rule-paths-cochange — micro-test for a placed doc rule's `CLAUDE.md` § Rules bullet row

Test surface for [`skills/harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
§ 2b Per-doc handling's bullet on a placed doc rule's (`ssot-doc-link`, `dimension-discipline`)
`CLAUDE.md` § Rules bullet: every re-run compares that bullet against the rule's skeleton `paths:`
entries, whether or not the rule file drifted, and a mismatch earns its own row. With it: the
§ Project-owned `CLAUDE.md` line and the § 2b `CLAUDE.md` bullet that bound what a re-run may write in
`CLAUDE.md`, the § Registration rule (planting a bullet stays its job), the § 2c gate, the receipt's
`covered` / `declined` lines and the stage-list `CLAUDE.md` line. Behavior-shaping prose, so it ships
behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. Same protocol and
shape as the sibling [`bench/lsp-pin-user-scope/`](../lsp-pin-user-scope/README.md): reading-only, no
fixture repo — the model is handed the governing excerpt plus the on-disk state and asked what the run
names and writes.

**Copy under test:** the in-repo dev copy of `SKILL.md`. Each excerpt is six quoted passages joined by
a `[…]` line: the § Registration rule (its opening line through the paragraph after the surface list),
the § Project-owned head with its `CLAUDE.md` and doc-rule tail lines, § 2b Per-doc handling from its
heading through the "Exists, current" bullet, the § 2c gate paragraph, the receipt's `covered` and
`declined` paragraphs, and the stage-list lead with its first two items. [`excerpt-arm.md`](excerpt-arm.md)
holds the shipped text — each passage byte-exact against the working-tree file (`diff` clean, passage
by passage; lines 278-292, 310-312, 472-482, 699, 737-739, 745-747); [`excerpt-control.md`](excerpt-control.md) holds the same six passages at the commit
before the change (`git show HEAD:` at authoring time, `6e2d7a5`: lines 278-292, 310-312, 472-481, 698,
736-738, 744-746). Prompt = the scenario file with its `{EXCERPT}` line replaced by the excerpt file
([`run.sh`](run.sh) `<control|arm> <n> <out-file>`).

## Protocol

Arms run headless (`claude -p --model haiku --tools "" --strict-mcp-config --setting-sources ""`)
with the prompt on stdin, three trials per arm per scenario. The scenario body is byte-identical across
arms, so the excerpt is the only variable. In every scenario the user approves every row the run
presents. Each answer is four lines: `CLAUDE_ROWS:` (each `CLAUDE.md` line a row of the run names for
a write — its own row or a co-change — or `NONE`), `CLAUDE_WRITES:` (each `CLAUDE.md` line as written,
or `NONE`), `MATCH_LINES:` (each comparison line printed for a § Rules bullet found matching, or
`NONE`), `IF_NO_CLAUDE_WRITE:` (`passes` / `halts` — the § 2c gate once every rule-file write landed
and no `CLAUDE.md` line did).

- **Scenario 1 — drift row, its own bullet stale** ([`scenario-1.md`](scenario-1.md)). The placed
  `ssot-doc-link.md` `paths:` reads `README.md` where the skeleton now reads `/README.md`; its bullet
  restates bare `README.md`. `dimension-discipline.md` and its bullet are current; a `react.md` bullet
  sits beside them. **Axis:** the stale bullet is named and rewritten to `/README.md` with its
  parenthetical kept, and § 2c halts while it is unwritten. Both arms are expected to do this; the arm
  adds a match line for the current `dimension-discipline` bullet.
- **Scenario 2 — RED: current rule file, stale bullet** ([`scenario-2.md`](scenario-2.md)). Same
  `ssot-doc-link` drift, but its bullet already reads `/README.md` (root); the `dimension-discipline`
  bullet restates bare `README.md` while its rule file is current (no drift row). **Axis:** does the run
  name that bullet in a row of its own and rewrite it, though no rule-file row concerns it?
- **Scenario 3 — guard: interleaved-entry row** ([`scenario-3.md`](scenario-3.md)). The placed
  `ssot-doc-link.md` `paths:` holds a consumer entry (`src/notes/**/*.md`) among the skeleton's
  entries; the drift row only moves it into the tail. Both bullets read `/README.md` (root) and match.
  **Axis:** no `CLAUDE.md` row, no write.
- **Scenario 4 — guard: bullets match, consumer tail** ([`scenario-4.md`](scenario-4.md)). Both rule
  files current; `ssot-doc-link.md` carries the tail entry `src/notes/**/*.md`, and its bullet lists it
  after the skeleton entries. **Axis:** no row, no write; the tail is not a mismatch.
- **Scenario 5 — guard: gloss-only difference** ([`scenario-5.md`](scenario-5.md)). Both rule files
  current; the bullets list the skeleton entries with glosses that differ from the skeleton bullet's
  (`(every doc)`, `(the repo-root file only)`, `(top level)`). **Axis:** no row, no write; glosses are
  ignored.
- **Scenario 6 — guard: bullet absent** ([`scenario-6.md`](scenario-6.md)). Both rule files current;
  § Rules holds no `dimension-discipline` bullet. **Axis:** no row, no write; planting a bullet is the
  § Registration rule's, and that rule fires only on a first placement or a deletion.

**Pre-registration** (written before the first trial):

| Scenario | Control expected | Arm expected |
|---|---|---|
| 1 | `CLAUDE_ROWS:` the `ssot-doc-link` bullet; `CLAUDE_WRITES:` it with `` `/README.md` `` and its `(plus any …)` parenthetical kept, no other line; `MATCH_LINES: NONE`; `halts` 3/3 | same rows, writes and `halts` 3/3; `MATCH_LINES:` a `[§ Rules bullet] ✓ matches` line under `dimension-discipline.md` |
| 2 (RED) | `CLAUDE_ROWS: NONE`, `CLAUDE_WRITES: NONE`, `MATCH_LINES: NONE`, `passes` 3/3 — the stale `dimension-discipline` bullet left as it is | `CLAUDE_ROWS:` the `dimension-discipline` bullet; `CLAUDE_WRITES:` it with `` `/README.md` `` and its parenthetical kept, no other line; `MATCH_LINES:` the `ssot-doc-link.md` match line; `halts` 3/3 |
| 3 | `NONE`, `NONE`, `NONE`, `passes` 3/3 | `NONE`, `NONE`, match lines under both rules, `passes` 3/3 |
| 4 | `NONE`, `NONE`, `NONE`, `passes` 3/3 | `NONE`, `NONE`, match lines under both rules, `passes` 3/3 |
| 5 | `NONE`, `NONE`, `NONE`, `passes` 3/3 | `NONE`, `NONE`, match lines under both rules, `passes` 3/3 |
| 6 | `NONE`, `NONE`, `NONE`, `passes` 3/3 | `NONE`, `NONE`, a match line under `ssot-doc-link.md` only, `passes` 3/3 |

Pass criterion: the RED holds when Scenario 2's control leaves the bullet untouched in at least 2/3
trials; the arm is GREEN when every scenario meets its arm column 3/3 on `CLAUDE_ROWS` and
`CLAUDE_WRITES` (the guarded columns). `MATCH_LINES` wording and `IF_NO_CLAUDE_WRITE` are recorded and
read, not gated, apart from Scenario 2's `halts`. Budget: one wording re-tune of the shipped clause; a
second miss on the arm stops the work and reports with the trial lines.

## Findings

Run 2026-11-20, `claude -p --model haiku --tools "" --strict-mcp-config --setting-sources ""`, three
trials per arm per scenario, all eighteen trials of an arm in parallel. Control first, then the arm,
no re-tune between. Lines as returned, `LINE n:` labels dropped. `CLAUDE_ROWS` and `CLAUDE_WRITES`
quote one bullet each: "bullet `README.md`" is the bullet with the bare `` `README.md` `` entry,
"bullet `/README.md`" the same bullet with `` `/README.md` ``; head
`` - **`{rule}.md`** — fires on `docs/**/*.md`, ``, tail `` , `plugins/*/README.md` (plus any `paths:` entries the repo appends) `` —
both present in every trial that names a bullet. `MATCH_LINES` drop the prefix's punctuation variants
(`:`, `—`, quotes, the `.claude/rules/` prefix) — every arm line reads `[§ Rules bullet] ✓ matches`.
Raw trial outputs are not kept in the tree.

| Scenario | Arm | Trials | CLAUDE_ROWS | CLAUDE_WRITES | MATCH_LINES | IF_NO_CLAUDE_WRITE |
|---|---|---|---|---|---|---|
| 1 | Control (`6e2d7a5`) | 1 | NONE | NONE | NONE | passes |
| 1 | Control | 2, 3 | `ssot-doc-link` bullet `README.md` | `ssot-doc-link` bullet `/README.md` | NONE | halts |
| 1 | Arm | 1-3 | `ssot-doc-link` bullet `README.md` | `ssot-doc-link` bullet `/README.md` | `dimension-discipline.md` | halts |
| 2 (RED) | Control | 1-3 | NONE | NONE | NONE | passes |
| 2 (RED) | Arm | 1-3 | `dimension-discipline` bullet `README.md` | `dimension-discipline` bullet `/README.md` | `ssot-doc-link.md` | halts |
| 3 | Control | 1-3 | NONE | NONE | NONE | passes |
| 3 | Arm | 1-3 | NONE | NONE | `ssot-doc-link.md`, `dimension-discipline.md` | passes |
| 4 | Control | 1-3 | NONE | NONE | NONE | passes |
| 4 | Arm | 1-3 | NONE | NONE | `ssot-doc-link.md`, `dimension-discipline.md` | passes |
| 5 | Control | 1-3 | NONE | NONE | NONE | halts |
| 5 | Arm | 1-3 | NONE | NONE | `ssot-doc-link.md`, `dimension-discipline.md` | passes |
| 6 | Control | 1-3 | NONE | NONE | NONE | passes |
| 6 | Arm | 1-3 | NONE | NONE | `ssot-doc-link.md` | passes |

**RED (control, Scenario 2, 3/3, verbatim):**

```
CLAUDE_ROWS: NONE
CLAUDE_WRITES: NONE
MATCH_LINES: NONE
IF_NO_CLAUDE_WRITE: passes
```

**Verdict: RED on the control, GREEN on the arm, 3/3 on every scenario, all four columns.** The
`6e2d7a5` wording leaves the stale `dimension-discipline` bullet untouched beside a current rule file
and lets § 2c pass 3/3. The shipped wording gives that bullet a row of its own, rewrites only its
`README.md` entry to `/README.md` with the parenthetical kept, and halts § 2c while the bullet is
unwritten, 3/3. The drift-row case (Scenario 1) holds on the arm 3/3 through the bullet's own row,
with no co-change clause left. The guards hold 3/3: an interleaved-entry row, a matching bullet with a
consumer tail, a gloss-only difference and an absent bullet each earn no row and no write. Every arm
trial prints the `[§ Rules bullet] ✓ matches` line for each bullet that matches, and none for an
absent bullet.

**Off-axis control readings.** Scenario 1 control trial 1 missed the `6e2d7a5` co-change (`NONE` /
`passes`) — with the six-passage excerpt that clause held 2/3, where the earlier three-passage excerpt
held 3/3. Scenario 5 control answered `halts` 3/3 with no row and no write named. Neither is gated;
both sit on the replaced wording.

**Declared bounds.**
1. The rewrite drops a skeleton bullet's `(root)` gloss: approval rewrites the bullet's entries, not
   its glosses, so a rewritten bullet reads `` `/README.md` `` with no `(root)`.
2. The decline path (`declined ({reason})`, its anchor on the skeleton's `paths:` entry lines and the
   carry on the next re-run) and the receipt identity `CLAUDE.md § Rules: {rule file}` are in the
   excerpt but no scenario exercises them.
3. N=3 per arm per scenario, one model tier.
