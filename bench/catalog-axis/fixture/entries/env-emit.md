# env-emit

Write the project's claimed ports into `.env` so application code reads them instead of
hardcoding them.

## What it does

`env-emit` resolves the lease for the current directory, turns each port in the block
into an environment variable, and writes the set into `.env` between two marker lines:

    # >>> portside
    PORTSIDE_WEB=4001
    PORTSIDE_API=4002
    # <<< portside

Variable names come from the service names in `portside.services.toml`, uppercased and
prefixed. A service the manifest does not name gets a positional name
(`PORTSIDE_PORT_3`) so the block is always complete.

Running `env-emit` twice replaces the block in place. Every byte outside the two marker
lines survives untouched, including comments, ordering, and trailing whitespace.

## Background

The command exists because copying port numbers by hand was the most reliable source of
"works on my machine" in the toolkit's first year: a developer claims 4001, writes 4000
into `.env`, and spends an afternoon on it.

The block-marker shape was chosen over merging variables line by line. A line-merge
reorders the file, so every run produces a diff touching lines nobody edited, and
reviewers stop reading `.env` diffs altogether. A delimited block keeps the diff to the
block, which keeps it readable, which keeps it reviewed.

The `PORTSIDE_` prefix mirrors the key namespace inside the lease file, so a reader
grepping one finds the other. It won over the shorter `PS_` after that prefix turned out
to collide with two unrelated tools people already had on their shells.

## Arguments

- `--file <path>` — target file. Default `.env`. Created if absent, with the block as
  its only content.
- `--prefix <str>` — variable prefix. Default `PORTSIDE_`. Applied before uppercasing,
  so `--prefix app_` yields `APP_WEB`.
- `--stdout` — print the block to standard output and write nothing. Useful for
  `eval "$(env-emit --stdout)"` in a shell wrapper.

## Boundary

`env-emit` writes only between its markers. It will not touch, reorder, or reformat a
line outside them, and it will not remove a variable a developer moved out of the block
by hand — a `PORTSIDE_WEB` above the opening marker is left alone and shadows nothing,
because the block's own copy is written below it.

An unbalanced marker pair — an opening marker with no closing one, or two openings —
aborts the write with a non-zero exit and leaves the file exactly as it was. The
command does not guess where a truncated block was meant to end.
