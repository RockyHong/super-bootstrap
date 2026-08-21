# Probe prompt — catalog axis, tier measurement

Hand the body below to a cold judge agent verbatim. Nothing else from this directory
travels with it.

---

You are auditing one documentation catalog for row-to-entry-file drift.

## What to read

Read exactly these, and nothing else in the repository:

- `bench/catalog-axis/fixture/index.md`
- every file under `bench/catalog-axis/fixture/entries/` that `index.md` names

Do **not** read `bench/catalog-axis/fixture/ANSWER-KEY.md`, `bench/catalog-axis/README.md`,
`bench/catalog-axis/axis-draft.md`, or any other file in `bench/catalog-axis/`. Do not
search the repository for related material. The catalog and its entry files are the
whole evidence surface; anything else you open invalidates the run.

## The axis

Apply the axis below exactly as written. It is the whole specification — no other
convention, house style, or doc-review instinct applies.

### The catalog predicate and its comparison

````markdown
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
````

(The shipped lines below cite the predicate as `assets/catalog-predicate.md`; its
body is the block above — there is no such file to open.)

### What to extract while reading

````markdown
- Catalog rows and their entry files — for each doc (or section) passing the catalog
  predicate in `assets/catalog-predicate.md`: per row, the **claim set** (what the row
  asserts about its entry — behavior, arguments, defaults, refusals) and, for the entry
  file that row resolves to, the **section roster** (`##`/`###` headings plus what each
  section states). Extract per row against its own file; this pairing is never a
  whole-corpus load. Needed for Step 2's catalog-row checks.
````

### Findings to raise

Raise a finding at **P0** for either of:

````markdown
- Catalog row asserts something its entry file's corresponding section states the
  negation of (catalog predicate: `assets/catalog-predicate.md`)
- Catalog row omits a whole named section of its entry file that states a
  contract/constraint (`## Arguments`/`## Boundary`/`## Rules`-class) the row's reader
  would violate unseen
````

Raise a finding at **P1** for:

````markdown
- Catalog row omits a whole named descriptive section of its entry file
````

Rider on both levels:

````markdown
The catalog-row checks compare row against entry file per row, per file — never a
whole-corpus load. Compare by content, not by heading token: rhetorical-role headings
(`## The fact`, `## Failure modes`, `## Boundary` used as a label) are routinely
covered by a row that never uses their words. The commit door's `doc-sync-scan` covers
the diff-touched slice of this class; this axis is the whole-surface carrier — the two
doors do not double-claim it.
````

## Procedure

1. Read `index.md`. Establish, from its own header, where its entry files live, and
   confirm the catalog predicate holds.
2. For each row in order: resolve the row to its entry file, read that file whole,
   extract the row's claim set and the file's section roster, and hold one against the
   other. Finish the row before moving to the next; do not batch the files.
3. Emit findings.

## Output

Return the findings list and nothing else — no preamble, no summary, no counts, no
per-row narration, no restatement of the axis.

One line per finding, in catalog-row order, in exactly this form:

    row <name> | <contradiction|omission-P0|omission-P1> | <entry section> | <one-line evidence>

- `<name>` — the row's entry name as the catalog writes it.
- `<entry section>` — the entry file's `##` heading involved, written as it appears.
- `<one-line evidence>` — one line: for a contradiction, what the row asserts and what
  the section states instead; for an omission, what the omitted section carries.

A row with nothing to report produces **no line**. Do not write `none`, do not list
clean rows, do not acknowledge them.

If no row in the catalog yields a finding, return the single word `clean`.
