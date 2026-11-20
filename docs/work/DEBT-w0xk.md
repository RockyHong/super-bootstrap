# DEBT-w0xk — README root-pin drift row omits the CLAUDE.md § Rules line as co-change

**Logged:** 2026-11-20 · **Source:** device note from ComfyUI `workflows/agent` repo (harness-bootstrap 7.0.0 legacy → split migration, then regular sync), 2026-11-19
**Problem:** Root-pinning `/README.md` in ssot-doc-link / dimension-discipline drops nested READMEs (there `prompting/README.md`). `rule-paths-coverage.sh` caught it via `.claude/doc-surface`, but older installs' skeleton `CLAUDE.md` § Rules bullets still restate `README.md`; the drift row does not name that `CLAUDE.md` line as a co-change.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/` rule drift rows, `rule-paths-coverage.sh`
**Prior:** Drift row for the rule `paths:` change names the `CLAUDE.md` § Rules bullet as a co-change.

## Verdict — surface · 2026-11-20

### Findings

- premise age: 8 commits touched `skills/harness-bootstrap/` after the 2026-11-19 observation (33b26aa, e0ae718, 7e10e60, a63c542, e993e9b, 7b6507b, a9ef724, 32c915e). Read for overturn: none touches the per-doc drift bullet, the Registration rule's trigger set, or a `paths:` co-change. 32c915e (rot scan) and a63c542 (legacy migration) are the closest; neither rewrites a § Rules fires-on list on a re-run. The root pin itself is older: 76b43b4 (2026-11-10) pinned `/README.md` in both rule skeletons and in this repo's own `CLAUDE.md`, and gave no consumer-side propagation.
- root cause (gap confirmed against current code): no lane in `SKILL.md` names a consumer `CLAUDE.md` § Rules bullet when the skeleton part of a placed doc rule's `paths:` changes.
  - `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:475`: the placed-doc-rule drift diffs `paths:` "on the skeleton's entries only" and names no co-change surface.
  - `SKILL.md:474` and `:310`: `CLAUDE.md` is "never drift-diffed". The run's only later writes are "registration lines in § Rules / § Planning (§ Registration rule)".
  - `SKILL.md:278`: the Registration rule fires only on an artifact "this run places for the first time or deletes". A rule whose `paths:` changes in place is neither, so its own § Rules bullet (`assets/claude-md-skeleton.md:9,11` lines restate the fires-on list) is never reached.
  - Result: an older install's `fires on `docs/**/*.md`, `README.md`` bullet survives every sync. The rename-map rot scan (`assets/rename-map.md`) scans `CLAUDE.md`, but a bare `README.md` → `/README.md` row would hit every README mention, so it is not a usable lane.
- the card's secondary observation is not in this aim: the root pin dropping a nested `prompting/README.md` was caught by `rule-paths-coverage.sh check` (SKILL.md:794), and the consumer adds the tail entry. The script reads only rule frontmatter and `.claude/doc-surface` (`assets/rule-paths-coverage.sh:41-42`). It does not cause the gap.
- no duplicate: none of the other open cards (`BUG-0zw8`, `BUG-aacw`, `BUG-bqc8`, `BUG-w3aq`, `DEBT-ymdg`) covers a `paths:` co-change. `DEBT-ymdg` (lines 25, 92) keeps open who owns the § Rules summary, with the lean "project". This fix must hold whichever way that question settles. No `docs/decisions.md` row closes this fork.
- scope reach:
  - `SKILL.md:475`: the drift bullet, which gets the co-change clause.
  - `SKILL.md:474`, `:310`: the exception lists for `CLAUDE.md` writes.
  - `SKILL.md:278-292`: the Registration rule, if the co-change goes in as a third trigger.
  - `SKILL.md:684-693`: the sync-report example row.
  - `SKILL.md:730`: the § 2c staged-file list for `CLAUDE.md`.
  - `docs/specs/harness-architecture.md:389-390`: states "a re-run only appends registration lines". This line is already behind `SKILL.md:290`, which also re-points and drops lines.
  - Option C below also touches `assets/rule-paths-coverage.sh` and `tests/rule-paths-coverage.test.sh`.
  - Unchanged after read: `assets/claude-md-skeleton.md` (already `/README.md` (root)) and this repo's own `CLAUDE.md` (updated in 76b43b4).
- attempted: static read of the drift, registration and ownership lanes, the coverage script and the rename map. Stopped at the fork below. The fix widens the run's write boundary into a project-owned file, and it changes runtime behavior stated in a spec. By the spec-touch calibration (condition b), that is not auto-fix.
- excluded as bias input: the card's `**Prior:**` (its fix lean). It was weighed only as option A below.

### Decision needed

- When the skeleton part of a placed doc rule's `paths:` changes, what does the drift row do with that rule's `CLAUDE.md` § Rules bullet?
- options:
  - A. Name the bullet as a co-change and write it on approval. The drift row greps `CLAUDE.md` § Rules for the rule's own bullet. If the fires-on list differs from the rule's resulting skeleton entries, the row names the bullet as a co-change. Approving the row rewrites only that bullet's backticked fires-on list and keeps the consumer-tail parenthetical. The row resolves `updated` only when both surfaces are edited, like a registration row. This widens the run's `CLAUDE.md` writes from "registration lines" to "the named artifact's own § Rules line". `SKILL.md:310`, `:474` and spec `:390` move with it.
  - B. Name the bullet only, and the consumer edits it. The row lists the bullet, and the halt holds until the consumer has edited it by hand. The run's write boundary on `CLAUDE.md` does not change. The stale line cannot survive a completed sync, but each re-run costs the consumer a manual edit.
  - C. Add a mechanical check. A new `rule-paths-coverage.sh` mode compares each placed doc rule's § Rules bullet list against its `paths:` and prints mismatches. The drift row consumes that output under A or B. This is a forcing function in the sense of SKILL.md:802, but it adds a parser for consumer-authored prose. It is an add-on to A or B, not a third resolution.
- recommendation: A, with the detection described in prose. The Registration rule already lets the run touch "only the line of the artifact the row names" (SKILL.md:290). A `paths:` change is the same move as re-pointing a line on a move. The per-row approval keeps the consumer's consent. B adds manual work with no safety gain. Hold C until a consumer-worded bullet is seen to defeat the prose match.
- settles by: user authority on the ownership boundary (product/boundary call). The user decides whether a re-run may rewrite a project-owned `CLAUDE.md` line beyond registration. This interacts with `DEBT-ymdg`'s open question on who owns § Rules. Once ruled, the build routes `full`: it is behavior-shaping skill prose, so `.claude/rules/skill-authoring.md` requires a RED micro-test first. The test is a fixture walk, run headless at the fixture: an older install's `CLAUDE.md` with bare `README.md` bullets → re-run → assert the drift row names the bullet and the bullet ends as `/README.md`. Size: `phased build` (fixture + headless `claude -p` walk).

## Design — 2026-11-20

Settled by the gateway's climb, under the author's "finish all" delegation (no user ruling): **option A.** A placed doc rule's drift row whose `paths:` changes names the consumer `CLAUDE.md` § Rules bullet for that rule as a co-change; on the row's approval the run rewrites that one bullet's fires-on list, and the row resolves `updated` only when both edits land. Source: `SKILL.md:290` (Registration rule, surface 5) already lets a run re-point or drop the one § Rules line of the artifact a row names on a move — a `paths:` change is the same action on the same line, under per-row approval. Holds whichever way DEBT-ymdg settles § Rules ownership, since the write stays row-named and approved. `docs/specs/harness-architecture.md:389-390` ("only appends registration lines") is corrected in the same change.
