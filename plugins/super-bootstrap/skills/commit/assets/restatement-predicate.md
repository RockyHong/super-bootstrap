# Restatement Predicate — One Fact, K Copies

A fact stated in K places drifts on the first edit that reaches fewer than K of
them. A one-hop link from each copy to a single home keeps K copies honest: the
reader lands on the home, and an editor finds every copy by its link. The count
of unlinked copies per fact is the structural SSOT-drift signal; this predicate
defines what counts.

## Fact vs pointer

- **Fact** — a claim's content: a value, default, rule, sequence, or contract,
  written as the question it answers ("what is the default retry count?"). Two
  lines answering the same question are copies of one fact, whatever their
  wording — and still copies when their answers differ.
- **Copy** — a line a reader could act on the fact from alone. A home is a copy.
- **Pointer** — a line naming where the fact lives and carrying none of its
  content ("the retry policy has its own section", "see the install guide"). A
  pointer is not a copy.

## Counting

- **Scope** — the copies in the scan scope, every scope doc read whole, so a
  second copy inside the same doc counts. Copies outside the scope are out of
  reach.
- **Not counted** — a catalog or index row and an ephemeral doc, per
  [`link-predicate.md`](../../check-docs-consistency/assets/link-predicate.md)
  guards 3–4; frozen provenance (a `dimension: history` doc, a card thread).
- **Home** — the copy that the other copies link to, or the section that defines
  the fact. A same-doc home is a section, and its link is an anchor link. When no
  copy is designated, the home is `none`.

## Finding

A fact is a restatement finding when **K ≥ 2** and at least one copy lacks a
one-hop link to a single home on its asserting line. A copy in a doc whose earlier
asserting line already links the same home counts as linked. A fact whose every non-home
copy links one hop to the same home is a linked restatement — not a finding.

Report per finding: the fact (one line), K, every location (`path:line`, section),
the home or `none`, and which copies lack the link.
