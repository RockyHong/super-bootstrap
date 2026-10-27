# Probe prompt — restatement axis, RED (current skill text)

Hand the body below the rule to a cold judge agent verbatim, with read-only tools.
Nothing else from this directory travels with it. The skill text inside is copied
verbatim from `plugins/super-bootstrap/skills/check-docs-consistency/SKILL.md`
(§ Step 1, § Step 2, § Report Format) and its assets `dimension-predicate.md`,
`catalog-predicate.md`, `link-predicate.md` as of the RED run; regenerate this file if
any of them changes before the run.

---

You are running a documentation consistency scan over one small project's docs.

## What to read

The project's doc surface is exactly these six files, all under
`bench/restatement-axis/fixture/`:

- `README.md`
- `docs/overview.md`
- `docs/operations.md`
- `docs/sensors.md`
- `docs/door-interlock.md`
- `docs/recipes.md`

Treat `bench/restatement-axis/fixture/` as the repository root: every path the docs
cite resolves relative to it. Read these files and nothing else. Do **not** read
`bench/restatement-axis/fixture/ANSWER-KEY.md`, any other file under
`bench/restatement-axis/`, or anything elsewhere in the repository, and do not search
the repository for related material. Anything else you open invalidates the run. The
project has no `CLAUDE.md`, no orchestration files, no tracker, and no prior report.

## The procedure

Apply Step 1 and Step 2 below exactly as written. Where they say "Glob `**/*.md`
across the repo", the discovered set is the six files above. Skip Step 2.5 (the
project keeps no tracker) and do not write any file: return the report as your reply
instead of writing it to `.review/`.

````markdown
### Step 1: Discover and Read All Docs (one pass)

Glob `**/*.md` across the repo, then post-filter to the Doc Surface set — drop paths under the excluded trees, including the scan's own `.review/` reports. Glob takes one positive pattern, so the exclusion is a filter on the result list, not a glob argument. The orchestration files (`CLAUDE.md`, `.claude/agents/*.md`, `.claude/skills/**/SKILL.md`) fall inside this set — Step 1 mines them for path references and ownership statements specifically.

Read each file once. While reading, extract everything into a working set:

**Universal extractions (every project):**

- Cross-references (file paths, `§Section` refs, markdown links to other docs)
- Doc/file path references in orchestration files (CLAUDE.md, agent MDs, skill MDs)
- Ownership/guardrail statements in CLAUDE.md
- Temporal-doc conventions in CLAUDE.md (which dirs are delete-after-merge / temporal — e.g. spec/plan/handoff locations)
- Feature/module names mentioned across multiple docs
- File paths referenced in any doc
- Each prose doc's dimension — state-SSOT (truth-now) vs history-SSOT (dated chronicle) — per the classify predicate in `assets/dimension-predicate.md`. Skip harness MDs (CLAUDE.md, skill/agent/rule files — own no-precedent discipline). Needed for Step 2's P2 dimension-pollution check.
- Catalog rows and their entry files — for each doc (or section) passing the catalog predicate in `assets/catalog-predicate.md`: per row, the **claim set** (what the row asserts about its entry — behavior, arguments, defaults, refusals) and, for the entry file that row resolves to, the **section roster** (`##`/`###` headings plus what each section states). Extract per row against its own file — never a whole-corpus load. Needed for Step 2's P0/P1 catalog-row checks.

**Project-aware extractions (discover from what exists):**

- API endpoint patterns (`GET /...`, `POST /...`) if the project has backend docs
- Database/schema paths if the project has data docs
- Component/module names if the project has frontend/architecture docs
- Field/concept names that appear in multiple docs (potential mismatch surface)
- Screen/route names if the project has UI docs
- Config/env references if the project has deployment docs

The goal: build a map of "what references what" across the doc surface. Don't predetermine the categories — discover them from what the project actually documents.

For each concept named across multiple docs, also note its defining (home) doc — where it is actually specified, not merely mentioned. Required for Step 2's P3 link-gap check.

### Step 2: Cross-Reference

All validations run against the extracted set. Every finding comes from comparing what one doc says against what another doc says — contradictions, orphans, mismatches. The P2 dimension-pollution check is intra-doc: it inspects a single doc's dimension purity rather than comparing a cross-doc pair. Deduplicate: same file+line appears once under the highest-priority match.

**P0 — Would Cause Bugs If Trusted:**

- Cross-reference to nonexistent doc or section (broken link)
- Same concept defined differently in two docs (contradictory definitions)
- API endpoint/route in one doc but missing or different in another
- Schema/field in one doc that contradicts another doc's schema
- Catalog row asserts something its entry file's corresponding section states the negation of (catalog predicate: `assets/catalog-predicate.md`)
- Catalog row omits a whole named contract-class section of its entry file — a constraint its reader would violate unseen (contract-class per `assets/catalog-predicate.md`)

**P1 — Would Waste Dev Cycles:**

- Concept referenced as if it exists but has been removed or renamed in another doc
- Component/module in one catalog but missing from another
- Catalog row omits a whole named descriptive section of its entry file (descriptive per `assets/catalog-predicate.md`)
- Orphan doc (not referenced by any other file, not an index)
- Stale doc/file path in orchestration files (referenced file missing, glob has no matches)
- Removed feature/screen still referenced elsewhere
- Stale temporal artifact — a spec/plan/handoff doc in a delete-after-merge location with no matching active work. The set of delete-after-merge dirs comes from the project's own convention (extracted in Step 1)

**P2 — Slow-Burn Confusion:**

- Field/concept name mismatch for the same thing across docs (e.g., `targetLang` vs `targetLanguage`)
- Ownership contradiction in CLAUDE.md (two docs claiming to own the same concern)
- Internal terminology leaking where user-facing language is expected (or reverse)
- Handoff/WIP folder with no matching feature branch
- Dimension pollution — a prose doc breaks state XOR history per the audit predicate in `assets/dimension-predicate.md`: (a) chronicle crawl-in (timestamps / "was X, now Y" / decision-dated prose accumulating in a persistent state-SSOT doc), (b) stale workspace doc (a vaporizable/status doc gone out-of-date against what it tracks), (c) state leak into history (a decision-timeline doc carrying persistent knowledge that belongs in a state-SSOT home). Harness MDs excluded (Step 1). Surface the doc + polluting lines; the fix (overwrite / move to git / restate as present-tense constraint) is the user's call

**P3 — Cosmetic / Completeness:**

- Doc section referenced in index but empty or stub
- Feature documented in specs but absent from overview module index
- Missing link to a concept's home doc — a link-candidate concept in doc A (per the predicate in `assets/link-predicate.md`: B defines it, A uses it substantively, A is not a catalog/index) carries no link to its SSOT home B. Surface as a suggestion; which link to add is the user's call.
````

## The assets the steps cite

The steps cite three asset files by path. Their bodies follow; there are no such
files for you to open.

### `assets/dimension-predicate.md`

````markdown
# Doc Dimension Predicate — State XOR History

A prose doc or section owns one **dimension**: *state* (what is true now) or
*history* (a dated chronicle of what was decided when), never both. Mix them and
every sentence forces the reader to ask "true now, or a past record I'm
mis-trusting as current?" — dimension pollution.

## Classify — state vs history

- **State-SSOT** — what is true *now*. Kept current by overwriting stale facts in
  place. Overview, techstack, architecture, backlog rows, status fields.
- **History-SSOT** — a timeline / decision chronicle: what was decided when, why,
  prior values. Append-only. Git (log + commit messages) is the canonical home —
  free, drift-proof.

## Route — where each dimension goes

1. **State → overwrite in place.** The state-SSOT carries truth-now; on change,
   replace the stale fact, don't append a "was X, now Y" note.
2. **History → git.** A hand-maintained "what happened when" prose chronicle is a
   derivative of git (maintaining it by hand edits the derivative — SSOT
   violation). Drop it. Where a rationale is genuinely expensive to reconstruct
   from diffs, a one-line pointer to the commit beats re-prosing it.
3. **Binding past decision → present-tense constraint.** A decision made earlier
   that still *binds* future work is a live constraint, not a record. State it
   present-tense in the state-SSOT, stripped of when/why-decided. "Refinement is
   deferred behind the port" — not "on <date> we decided to defer refinement
   because…".
4. **Verification stamps stay.** A stamp recording *when a fact was last checked*
   (probed / measured on date) is current-state metadata — it tells the reader the
   fact's freshness. Not history pollution.

## Audit predicate — pollution shapes

A doc shows dimension pollution when any holds:

1. **Chronicle crawl-in** — timestamps / "was X, now Y" / decision-dated prose
   accumulating in a persistent state-SSOT doc.
2. **Stale workspace doc** — a vaporizable / status doc gone out-of-date against
   the reality it claims to track.
3. **State leak into history** — a history / decision-timeline doc carrying
   persistent or cross-dimension knowledge that belongs in a state-SSOT home.

## Boundary

Applies to authored prose docs (overview, techstack, architecture, backlog,
READMEs) wherever the project keeps them — not harness MDs (skills / agents /
rules carry their own no-precedent discipline).
````

### `assets/catalog-predicate.md`

````markdown
# Catalog Predicate — Index Rows That Summarize an Entry File

A **catalog** is a doc whose rows each stand in for one sibling file. The row is
the retrieval surface: a reader cut-tests the row's summary to decide whether to
open the file at all. A row carrying prose beyond the pointer therefore makes
claims, and a claim drifts in two directions — it states the opposite of what the
file states, or it leaves out a whole part of the file the reader then never
learns exists.

## Catalog predicate

A doc — or a section of one — is a catalog when **both** hold:

1. **Every row resolves to exactly one sibling file.** Resolution is mechanical,
   not a judgment about intent: a markdown link whose target exists, or a
   backticked name that resolves to an existing file under the directory the
   catalog's own header names ("each entry is `reference/<name>.md`", "each row
   maps to that skill's `SKILL.md`"). Existence is the test; linkage is
   incidental. A row naming nothing, a directory, a concept, or several files
   fails.
2. **Rows carry prose beyond the pointer.** The row asserts something about the
   entry — what it does, what it takes, what it refuses. A bare-pointer row (name
   plus path, no claim) asserts nothing that can drift.

Fail either → not a catalog; run no row-to-entry comparison on it. Judge per
section, not per file: a catalog section inside a larger prose doc qualifies on
its own, and a prose doc that merely names files in a sentence does not become
one.

## The comparison

Per row, per entry file — never a whole-corpus load. Read the row, read the file
it resolves to, hold one against the other, emit, move on. The pair is the
working unit, so the axis costs one entry-file read per row and fits the
single-pass inline run and a fanned-out shard alike.

Two shapes:

- **Contradiction** — the row asserts X; the entry file's corresponding section
  states not-X. The corresponding section is found by content, not by name: a
  row's claim about collision handling is checked against whatever section
  handles collisions.
- **Omission** — a whole named section of the entry file has no representative in
  the row. Not "the row is shorter than the file" (a summary is meant to be), but
  "an entire named section's subject never appears in the row".

## Heading tokens are not the comparison surface

Section headings are frequently rhetorical roles rather than topic labels —
`## The fact`, `## Failure modes`, `## What this buys you`, `## Boundary` used as
a label rather than as a subject. Their tokens share no vocabulary with a row
that covers them perfectly well.

Compare **content**: does the row carry what this section says? A row reading
"aborts on an unreadable lockfile rather than regenerating it" covers a
`## Failure modes` section, and flagging it for missing the words "failure modes"
is a false positive. Heading-token overlap is a search hint, never a finding.

## Contract-class vs descriptive

An omitted section levels by what it carries, not by its heading:

- **Contract-class** — the section states a constraint, refusal, default, or
  required argument the row's reader would violate having never opened the file
  (`## Arguments`, `## Boundary`, `## Rules`, `## Limits`, and anything doing that
  job under another name). A reader who trusted the row acts wrongly.
- **Descriptive** — the section explains, motivates, or gives background
  (`## Background`, `## Why`, a rationale section). A reader who trusted the row
  is under-informed, not wrong.

## Boundary

Applies to authored prose catalogs wherever the project keeps them — a README's
component or skill catalog, an overview module index, a `docs/` entry index.
Harness MDs carry their own discipline and are not entry files here unless a
catalog row explicitly stands in for one. The commit door's doc-sync judgment
covers the diff-touched slice of this class; this axis is the whole-surface
carrier — the two doors do not double-claim it.
````

### `assets/link-predicate.md`

````markdown
# Link Predicate — SSOT-Home Links

Prose docs reference each other by authored markdown link to the concept's single
home. A link is a *reference to one home* (SSOT) — unlike copying the definition
into the referring doc, which forks the truth and drifts on first edit. The link
is also the retrieval breadcrumb: a reader (human or agent) lands on the home
instead of reconstructing it from a partial mention.

## Link-candidate predicate

A concept used in doc A is a link-candidate to doc B when **all four** hold:

1. **Real home** — B *defines* the concept (B is its SSOT home), not merely
   mentions it. A link points at the definition, never at another passing use.
2. **Substantive use** — A leans on the concept (builds on it, assumes it,
   sends the reader to it), not a passing token that happens to match a name.
   Enumerative mention is not yet substantive: where prose catalogs many
   concepts in one breath (overview/guardrail rosters), link only the
   concepts A goes on to build on, not every name.
3. **A is not a catalog/index** — index docs enumerate many concepts by design
   and are not expected to link every entry. The predicate targets prose that
   *uses* concepts, not registries that *list* them — frozen tracker/backlog rows
   count as registries, not candidate prose.
4. **A is not ephemeral** — temporal docs (specs / plans in delete-after-merge
   locations) die on merge; the linking overhead doesn't earn its keep, same as
   catalog/index.

Fail any one → not a candidate. The guards are the noise filter: without them
every shared token reads as a missing link.

## Home selection edges

- **Two homes (concept vs surface).** A concept defined as an idea in one doc and
  as a surface (endpoint, storage, schema) in another → the link points at the
  **concept-definition** home; the surface home is a different concern.
- **Contradicting home.** If the candidate home contradicts the using line, do not
  link — that is a consistency defect (the docs disagree), not a missing link.
  Resolve the contradiction first.

## Boundary

Applies to authored prose docs (overview, architecture, specs, backlog, READMEs)
wherever the project keeps them — not harness MDs (skills / agents / rules carry
their own discipline).
````

## Output

Return the report in the skill's Report Format below and nothing else — no preamble
and no narration outside it. Omit the Cross-Reference Annotations section and the
"New vs already tracked" summary line (no tracker). Give every finding its file(s) and
line(s). An empty priority table stays in place with no rows.

````markdown
# Doc Consistency Report

**Date:** {today}
**Project:** {project name}
**Docs checked:** {list of docs read}

## P0 — Would Cause Bugs If Trusted

| # | File(s) | Line(s) | Finding |
|---|---------|---------|---------|

## P1 — Would Waste Dev Cycles

| # | File(s) | Line(s) | Finding |
|---|---------|---------|---------|

## P2 — Slow-Burn Confusion

| # | File(s) | Line(s) | Finding |
|---|---------|---------|---------|

## P3 — Cosmetic

| # | File(s) | Line(s) | Finding |
|---|---------|---------|---------|

## Cross-Reference Annotations

**Post-scan layer.** The scan ran blind to the tracker — these annotations only
add context for triage. They do not modify or suppress findings.
{Omit this section when the project keeps no tracker.}

| # | Finding (short) | Tag | Detail |
|---|-----------------|-----|--------|

## Summary

- P0: {count}
- P1: {count}
- P2: {count}
- P3: {count}
- Total: {count}
- New vs already tracked: {n new, n tracked, n potential regressions} {omit without tracker}

## Recommended Actions

{For each P0/P1 finding: what to fix and which doc owns the truth.}
{For borderline items: the question to resolve and who should decide.}
````
