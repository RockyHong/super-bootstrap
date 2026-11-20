# bench/migration-closure — micro-test for the legacy → split migration's leftovers: preamble ownership and retired artifacts

Test surface for [`skills/harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
§ Doctrine migration step 3 (the link bullet's display-text rewrite and the prose bullet's narrowed
skip), § Pipeline-owned's techstack / overview preamble line, and § 2b Retired artifacts (with the rot
scan's `(retired)` hit sentence, the Phase 3 sync line's kept-file fragment and
[`assets/rename-map.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/rename-map.md)
§ Retired files). Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. Same protocol and shape as the
sibling [`bench/rule-paths-cochange/`](../rule-paths-cochange/README.md): reading-only, no fixture
repo — the model is handed the governing excerpt plus the on-disk state and asked what the run writes.

**Copy under test:** the in-repo dev copy of `SKILL.md` and `rename-map.md`. Each excerpt is six quoted
passages joined by a `[…]` line, the last one under a `(from `assets/rename-map.md`)` label: migration
step 3 (its heading through the `Anything else` bullet), § Pipeline-owned (its head through the
`docs/decisions.md` line), the § 2b rot-scan paragraph, the § 2b paragraph after the rot-scan row
contract (`The rot scan runs even when …`, and in the arm the § Retired artifacts block after it),
the Phase 3 re-run sync line, and rename-map § Retired files. [`excerpt-arm.md`](excerpt-arm.md) holds
the shipped text, refreshed after the cold-audit fix (the preamble row's identity, retired rows entering
`covered`, the trimmed `harness-meta` row) — each passage byte-exact against the working-tree files (`diff` clean, passage by
passage; `SKILL.md` lines 164-171, 294-299, 608, 630-638 and 796, `rename-map.md` lines 65-71);
[`excerpt-control.md`](excerpt-control.md) holds the same passages at the commit before the change
(`git show HEAD:` at authoring time, `17e96c1`; `SKILL.md` lines 164-171, 294-298, 607, 629 and 786,
`rename-map.md` lines 65-69). Prompt = the scenario file with its `{EXCERPT}` line replaced by the
excerpt file ([`run.sh`](run.sh) `<control|arm> <n> <out-file>`).

## Protocol

Arms run headless (`claude -p --model haiku --tools "" --strict-mcp-config --setting-sources ""`)
with the prompt on stdin, three trials per arm. The scenario body is byte-identical across arms, so
the excerpt is the only variable.

- **Scenario 1 — pre-5.10 overview preamble** ([`scenario-1.md`](scenario-1.md)). Re-run on a split
  repo whose `docs/overview.md` blockquote still reads `GAP-card pickup` and links
  ``[`CLAUDE.md` Doc Sync](../CLAUDE.md#doc-sync-non-negotiable)``; every listed section matches.
  Answer: `PREAMBLE_ROW:`, `LINK_AFTER:`, `PICKUP_AFTER:`. **Axis:** does the run raise a drift row for
  the preamble and leave it reading the skeleton's link and `GAP card pickup`?
- **Scenario 2 — `harness-meta` block** ([`scenario-2.md`](scenario-2.md)). Re-run; `docs/overview.md`
  carries a `<!-- harness-meta: … -->` block above its (current) blockquote. Answer: `ROWS:`,
  `ASKS_USER:`, `ON_DISK_AFTER_YES:`, `REPORTED:`. **Axis:** is a `⊘ removed` row proposed, asked, and
  only the block removed on yes?
- **Scenario 3 — untouched skeleton `AGENTS.md`** ([`scenario-3.md`](scenario-3.md)). Re-run; root
  `AGENTS.md` is the retired skeleton verbatim (`git show 1a1c999^:…/agents-md-skeleton.md`). Same
  answer shape. **Axis:** is `⊘ removed` proposed with a confirm, and the file deleted on yes?
- **Scenario 4 — guard: `AGENTS.md` with consumer sections** ([`scenario-4.md`](scenario-4.md)). Same
  as 3 plus an appended `## This repo` section of three repo facts. **Axis:** is the file kept (no
  removal proposed) and, in the arm, named in the sync line? Regression guard for the removal; the
  `REPORTED:` line is the arm's addition.
- **Scenario 5 — migration step 3** ([`scenario-5.md`](scenario-5.md)). Legacy repo at step 3; three
  `git grep` hits: a link in `docs/specs/billing.md`, a link in the overview preamble, prose
  `CLAUDE.md § Doc Sync` under overview § Module Index. Answer: `HIT 1..3:` outcome — line after.
  **Axis:** does a re-pointed link's display text change to `.claude/rules/harness.md`, and does prose in
  a grown section of a file with pipeline-owned sections take a proposed edit?

**Pre-registration** (written before the first trial):

| Scenario | Control expected | Arm expected |
|---|---|---|
| 1 | `PREAMBLE_ROW: NONE`, link and `GAP-card pickup` unchanged 3/3 — RED | a preamble row `⚠ drifted`; `LINK_AFTER:` ``[`.claude/rules/harness.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable)``; `PICKUP_AFTER: GAP card pickup` 3/3 |
| 2 | `ROWS: NONE`, `ASKS_USER: n/a`, `ON_DISK_AFTER_YES: UNCHANGED`, `REPORTED: NONE` 3/3 — RED | one `⊘ removed` row for the `docs/overview.md` `harness-meta` block; `ASKS_USER: yes`; the block (marker through `-->`) removed, nothing else; `REPORTED: NONE` 3/3 |
| 3 | `ROWS: NONE`, `ASKS_USER: n/a`, `UNCHANGED`, `REPORTED: NONE` 3/3 — RED | `AGENTS.md` `⊘ removed` (a `registration:` row beside it allowed); `ASKS_USER: yes`; `AGENTS.md` deleted; `REPORTED: NONE` 3/3 |
| 4 | `ROWS: NONE`, `ASKS_USER: n/a`, `UNCHANGED`, `REPORTED: NONE` 3/3 | `ROWS: NONE`, `ASKS_USER: n/a`, `UNCHANGED` 3/3; `REPORTED:` a sentence naming `AGENTS.md` kept |
| 5 | hits 1-2 `re-point` with display text still `CLAUDE.md`; hit 3 `no change` (file with pipeline-owned sections) 3/3 — RED on display text and hit 3 | hits 1-2 `re-point` with display text `.claude/rules/harness.md`; hit 3 `proposed edit` naming `.claude/rules/harness.md` 3/3 |

Budget: one wording re-tune of the shipped text; a second miss on the arm stops the work and reports.

## Findings

Run 2026-11-20, `claude -p --model haiku --tools "" --strict-mcp-config --setting-sources ""`,
three trials per arm, all 30 trials in parallel, one pass — no re-tune. The arm rows below are a re-run
on the refreshed `excerpt-arm.md` (18 trials in parallel: three per scenario, six on Scenario 4); the
control rows are the first pass's. Lines as returned, `LINE n:` /
`HIT n:` labels dropped; in Scenario 5 the overview blockquote's head is shortened to
`> Living doc. … See` (the elided text came back byte-equal to the hit in every trial). Raw trial
outputs are not kept in the tree.

### Scenario 1 — pre-5.10 overview preamble

| Arm | Trial | PREAMBLE_ROW | LINK_AFTER | PICKUP_AFTER |
|---|---|---|---|---|
| Control (`17e96c1`) | 1 | NONE | [`CLAUDE.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable) | fill at GAP-card pickup |
| Control | 2 | NONE | [`.claude/rules/harness.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable) | fill at GAP-card pickup |
| Control | 3 | NONE | [`.claude/rules/harness.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable) | fill at GAP-card pickup |
| Arm (shipped) | 1 | docs/overview.md: preamble, stale (link display text and "GAP-card" differ from the skeleton) | [`.claude/rules/harness.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable) | GAP card pickup |
| Arm | 2 | docs/overview.md: preamble — stale | [`.claude/rules/harness.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable) | fill at GAP card pickup |
| Arm | 3 | docs/overview.md: preamble — stale | [`.claude/rules/harness.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable) | fill at GAP card pickup |

### Scenario 2 — `harness-meta` block

| Arm | Trial | ROWS | ASKS_USER | ON_DISK_AFTER_YES | REPORTED |
|---|---|---|---|---|---|
| Control (`17e96c1`) | 1 | `.claude/rules/venue-map.md` — `⊘ removed` (written only if the file is placed; my disk check failed, so I could not confirm it is present) | yes | `.claude/rules/venue-map.md` | NONE |
| Control | 2 | NONE | n/a | UNCHANGED | NONE |
| Control | 3 | NONE | n/a | UNCHANGED | NONE |
| Arm (shipped) | 1 | `docs/overview.md § <!-- harness-meta` — `⊘ removed` | yes | deletes the `<!-- harness-meta` block in `docs/overview.md`, from its marker line through the closing `-->` (3 lines plus the opening line); every other line untouched, and `AGENTS.md` is not touched because it is absent. | NONE |
| Arm | 2 | ⊘ removed — identity `docs/overview.md § <!-- harness-meta`, status pending your y/n (resolves `updated` on y, `declined (reason)` on n) | yes | removes lines 3–6 of `docs/overview.md` (the `<!-- harness-meta` block through its closing `-->`), leaves every other line untouched, and deletes no file (no `AGENTS.md` exists) | NONE |
| Arm | 3 | `docs/overview.md § <!-- harness-meta` — ⊘ removed (asked y/n; resolves updated on y, declined on n). No row from this walk for `.claude/rules/venue-map.md`; that retire line belongs to § 2a-scale, which I haven't seen. | yes | from `docs/overview.md`, the `<!-- harness-meta:` … `-->` comment block is removed, all other lines untouched; `AGENTS.md` is absent, so nothing else is removed by this walk. | NONE |

### Scenario 3 — untouched skeleton `AGENTS.md`

| Arm | Trial | ROWS | ASKS_USER | ON_DISK_AFTER_YES | REPORTED |
|---|---|---|---|---|---|
| Control (`17e96c1`) | 1 | NONE | n/a | UNCHANGED | NONE |
| Control | 2 | NONE | n/a | UNCHANGED | NONE |
| Control | 3 | NONE | n/a | UNCHANGED | NONE |
| Arm (shipped) | 1 | `AGENTS.md` — `⊘ removed` (proposed; resolves `updated` on y, `declined (reason)` on n) | yes | `AGENTS.md` deleted from the repo root | NONE |
| Arm | 2 | AGENTS.md — ⊘ removed (proposed; resolves `updated` on y, `declined ({reason})` on n) | yes | AGENTS.md (repo root) deleted | NONE |
| Arm | 3 | `AGENTS.md` — `⊘ removed` (pending the user's y/n; y resolves `updated`, n resolves `declined ({reason})`) | yes | `AGENTS.md` (repo-root file deleted) | NONE |

### Scenario 4 — guard: `AGENTS.md` with consumer sections

| Arm | Trial | ROWS | ASKS_USER | ON_DISK_AFTER_YES | REPORTED |
|---|---|---|---|---|---|
| Control (`17e96c1`) | 1 | NONE | n/a | UNCHANGED | NONE |
| Control | 2 | NONE | n/a | UNCHANGED | NONE |
| Control | 3 | `.claude/rules/venue-map.md` — `⊘ removed` (only if the file is placed in the repo; the run does not list `AGENTS.md`) | yes | `.claude/rules/venue-map.md` removed if present; root `AGENTS.md` UNCHANGED | NONE |
| Arm (shipped) | 1 | NONE | n/a | UNCHANGED | `AGENTS.md` kept — it holds content of this repo beside the retired plugin contract; the runway no longer ships or reads it. |
| Arm | 2 | NONE | n/a | UNCHANGED | `AGENTS.md` kept — it holds content of this repo beside the retired plugin contract; the runway no longer ships or reads it. |
| Arm | 3 | NONE | n/a | UNCHANGED | `AGENTS.md` kept — it holds content of this repo beside the retired plugin contract; the runway no longer ships or reads it. |
| Arm | 4 | NONE | n/a | UNCHANGED | `AGENTS.md` kept — it holds content of this repo beside the retired plugin contract; the runway no longer ships or reads it. |
| Arm | 5 | NONE | n/a | UNCHANGED | `AGENTS.md` kept — it holds content of this repo beside the retired plugin contract; the runway no longer ships or reads it. |
| Arm | 6 | NONE | n/a | UNCHANGED | `AGENTS.md` kept — it holds content of this repo beside the retired plugin contract; the runway no longer ships or reads it. |

### Scenario 5 — migration step 3

| Arm | Trial | HIT 1 | HIT 2 | HIT 3 |
|---|---|---|---|---|
| Control (`17e96c1`) | 1 | re-point — Every change to the matcher follows [`CLAUDE.md` Doc Sync](../../.claude/rules/harness.md#doc-sync-non-negotiable). | re-point — > Living doc. … See [`CLAUDE.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable). | proposed edit — - `src/match/` — the matcher; a change here is committed per .claude/rules/harness.md § Doc Sync. |
| Control | 2 | re-point — Every change to the matcher follows [`CLAUDE.md` Doc Sync](../../.claude/rules/harness.md#doc-sync-non-negotiable). | re-point — > Living doc. … See [`CLAUDE.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable). | proposed edit — - `src/match/` — the matcher; a change here is committed per .claude/rules/harness.md § Doc Sync. |
| Control | 3 | re-point — Every change to the matcher follows [`CLAUDE.md` Doc Sync](../../.claude/rules/harness.md#doc-sync-non-negotiable). | re-point — > Living doc. … See [`CLAUDE.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable). | proposed edit — - `src/match/` — the matcher; a change here is committed per .claude/rules/harness.md § Doc Sync. |
| Arm (shipped) | 1 | re-point — Every change to the matcher follows [`.claude/rules/harness.md` Doc Sync](../../.claude/rules/harness.md#doc-sync-non-negotiable). | re-point — > Living doc. … See [`.claude/rules/harness.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable). | proposed edit — - `src/match/` — the matcher; a change here is committed per .claude/rules/harness.md § Doc Sync. |
| Arm | 2 | re-point — Every change to the matcher follows [`.claude/rules/harness.md` Doc Sync](../../.claude/rules/harness.md#doc-sync-non-negotiable). | re-point — > Living doc. … See [`.claude/rules/harness.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable). | proposed edit — - `src/match/` — the matcher; a change here is committed per .claude/rules/harness.md § Doc Sync. |
| Arm | 3 | re-point — Every change to the matcher follows [`.claude/rules/harness.md` Doc Sync](../../.claude/rules/harness.md#doc-sync-non-negotiable). | re-point — > Living doc. … See [`.claude/rules/harness.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable). | proposed edit — - `src/match/` — the matcher; a change here is committed per .claude/rules/harness.md § Doc Sync. |

**Verdict: RED on the control, GREEN on the arm, 3/3 each, on scenarios 1, 2, 3 and Scenario 5's
display text; Scenario 4's guard holds 3/3 on the control and 6/6 on the arm.** The `17e96c1` wording writes no preamble row
and leaves `GAP-card pickup` 3/3; the shipped wording raises a preamble drift row and lands the
skeleton's link and `GAP card pickup` 3/3. The control proposes no removal of the `harness-meta` block
or the skeleton `AGENTS.md` 3/3; the arm proposes one `⊘ removed` row, asks first, and removes only the
block or the file 3/3. With consumer sections in `AGENTS.md`, neither arm proposes a removal; the arm
names the kept file in the sync line 6/6. In migration step 3 the control re-points the link target
and keeps `CLAUDE.md` as display text 3/3; the arm rewrites the display text too 3/3.

**Declared bounds.**
1. Scenario 5 hit 3 is not a RED: the control already proposes the edit for prose under a grown section
   3/3, against the pre-registered `no change`. The prose bullet's narrowed skip ships as a clarity
   change with no measured behavior delta on this tier.
2. Scenario 1's `LINK_AFTER` on the control: trials 2-3 re-point the link and its display text although
   the run is a re-run and the control writes no preamble row — the model applied migration step 3's
   link bullet to a sync. The pre-registered `unchanged` held only for the display text in trial 1.
   `PREAMBLE_ROW` and `PICKUP_AFTER` carry the RED.
3. Arm rows name the verdict `stale`, not `⚠ drifted`: the excerpt carries no verdict vocabulary.
   Control trials 2-1 and 4-3 proposed a `venue-map.md` removal for a file the scenario never placed —
   noise outside the axis, no `harness-meta` or `AGENTS.md` removal.
4. Scenario 4's `REPORTED:` spreads at N=3: with the `AGENTS.md` row of `rename-map.md` § Retired files
   trimmed to kind + location + reason, the kept line came back 2/6 (0/3, then 2/3); with the row's
   `Removed only when it holds no consumer-authored content.` clause in place it came back 6/6 on the
   pre-fix excerpt and 6/6 on this re-run. That clause restates § 2b Retired artifacts' predicate on
   purpose — it is the measured cue for the keep-and-report branch — and stays in the row.
5. Judged-match is judgment: N=3 per arm per scenario (six on the arm's Scenario 4), one model tier, one consumer-content shape
   (an appended section). A consumer edit inside a shipped section is not measured.
