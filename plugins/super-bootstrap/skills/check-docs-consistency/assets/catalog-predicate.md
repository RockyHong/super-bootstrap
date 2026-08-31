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
