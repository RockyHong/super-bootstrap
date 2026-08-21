# Catalog-axis draft — graft text for `check-docs-consistency`

Three pieces, in the skill's own register, ready to land. (a) is a new asset body,
(b) is one bullet under Step 1's universal extractions, (c) is three bullets across the
Step 2 P-tables. Nothing else in the skill moves.

---

## (a) `assets/catalog-predicate.md` — candidate body

```markdown
# Catalog Predicate — Index Rows That Summarize an Entry File

A **catalog** is a doc whose rows each stand in for one sibling file. The row is the
retrieval surface: a reader cut-tests the row's summary to decide whether to open the
file at all. A row carrying prose beyond the pointer therefore makes claims — and a
claim can drift from the file it claims about, in two directions: it can state the
opposite of what the file states, or it can leave out a whole part of the file the
reader would then never learn exists.

## Catalog predicate

A doc (or a section of one) is a catalog when **both** hold:

1. **Every row resolves to exactly one sibling file.** Resolution is mechanical, not a
   judgment about intent: either a markdown link whose target exists, or a backticked
   name that resolves to an existing file under the directory the catalog's own header
   names ("each entry is `reference/<name>.md`", "each row maps to that skill's
   `SKILL.md`"). Linkage is incidental — existence is the test. A row naming nothing, a
   row naming a directory or a concept, and a row naming several files all fail.
2. **Rows carry prose beyond the pointer.** The row asserts something about the entry —
   what it does, what it takes, what it refuses. A bare-pointer row (name plus path, no
   claim) asserts nothing that can drift and is out of scope.

Fail either → not a catalog; run no row-to-entry comparison on it. Judge per section,
not per file: a catalog section inside a larger prose doc qualifies on its own, and a
prose doc that merely names files in a sentence does not become one.

## The comparison

Per row, per entry file — never a whole-corpus load. For one row: read the row, read
the file it resolves to, hold one against the other, emit findings, move on. The pair
is the working unit, so the axis costs one entry-file read per row and fits both the
single-pass inline run and a fanned-out shard.

Two shapes:

- **Contradiction** — the row asserts X; the entry file's corresponding section states
  not-X. The corresponding section is found by content, not by name: the row's claim
  about collision handling is checked against whatever section handles collisions.
- **Omission** — a whole named section of the entry file has no representative in the
  row at all. Not "the row is shorter than the file" (a summary is meant to be), but
  "an entire named section's subject never appears in the row".

## Heading tokens are not the comparison surface

Section headings are frequently rhetorical roles rather than topic labels —
`## The fact`, `## Failure modes`, `## What this buys you`, and `## Boundary` used
as a label rather than as a subject. Their tokens share no vocabulary with a row
that covers them perfectly well.

Compare **content**: does the row carry what this section says? A row reading
"aborts on an unreadable lockfile rather than regenerating it" covers a
`## Failure modes` section, and flagging it because the words "failure modes" are
absent from the row is a false positive. Heading-token overlap is a search hint,
never a finding.

## Contract-class vs descriptive

An omitted section is levelled by what the section carries, not by its heading:

- **Contract-class** — the section states a constraint, refusal, default, or required
  argument the row's reader would violate having never opened the file (`## Arguments`,
  `## Boundary`, `## Rules`, `## Limits`, and anything doing that job under another
  name). A reader who trusted the row acts wrongly.
- **Descriptive** — the section explains, motivates, or gives background (`## Background`,
  `## Why`, `## History`, a rationale section). A reader who trusted the row is
  under-informed, not wrong.

## Boundary

Applies to authored prose catalogs wherever the project keeps them — READMEs with a
component or skill catalog, an overview module index, a `docs/` entry index. Harness
MDs carry their own discipline and are not entry files for this purpose unless a
catalog row explicitly stands in for one.
```

---

## (b) Step 1 — one bullet under **Universal extractions (every project)**

```markdown
- Catalog rows and their entry files — for each doc (or section) passing the catalog
  predicate in `assets/catalog-predicate.md`: per row, the **claim set** (what the row
  asserts about its entry — behavior, arguments, defaults, refusals) and, for the entry
  file that row resolves to, the **section roster** (`##`/`###` headings plus what each
  section states). Extract per row against its own file; this pairing is never a
  whole-corpus load. Needed for Step 2's catalog-row checks.
```

---

## (c) Step 2 — three bullets

Under **P0 — Would Cause Bugs If Trusted**:

```markdown
- Catalog row asserts something its entry file's corresponding section states the
  negation of (catalog predicate: `assets/catalog-predicate.md`)
- Catalog row omits a whole named section of its entry file that states a
  contract/constraint (`## Arguments`/`## Boundary`/`## Rules`-class) the row's reader
  would violate unseen
```

Under **P1 — Would Waste Dev Cycles**:

```markdown
- Catalog row omits a whole named descriptive section of its entry file
```

Rider, in the P-table's surrounding prose (Step 2 preamble):

```markdown
The catalog-row checks compare row against entry file per row, per file — never a
whole-corpus load. Compare by content, not by heading token: rhetorical-role headings
(`## The fact`, `## Failure modes`, `## Boundary` used as a label) are routinely
covered by a row that never uses their words. The commit door's `doc-sync-scan` covers
the diff-touched slice of this class; this axis is the whole-surface carrier — the two
doors do not double-claim it.
```
