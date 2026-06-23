# Scenario — greenfield seeds permanent `docs/specs/` invisible to `todo`

> **Temporal evidence doc.** Grounds the fix for BUG-001. Delete with the BUG row when the fix merges (per `CLAUDE.md` § Doc Sync temporal cleanup).

## Symptom

After a greenfield `/super-bootstrap` run, `/super-bootstrap:todo` shows only deferred
architecture questions — the actual feature build work is missing from the board. The
forward specs exist on disk but no session can reach them through the pipeline opener.

## Repro (observed)

Repo: `D:\Git\script-captioner`, bootstrapped 2026-06-24. Git history of the greenfield run:

```
f403c95 docs: pin product seed + tech stack    ← overview.md + techstack.md   ✓ in contract
c770c30 chore: scaffold superpowers pipeline    ← backlog + decisions + superpowers/
c83562d docs: seed persistent feature specs     ← 5 files into docs/specs/     ✗ overstep
8c3cb58 docs: seed backlog                       ← GAP-001/002/003              ✗ not empty
```

Resulting `docs/specs/` vs. `todo` reachability:

| `docs/specs/` file | Reachable via `/super-bootstrap:todo`? |
|---|---|
| `p2-sentence-karaoke-render.md` | via GAP-001 (partial) |
| `script-audio-drift.md` | via GAP-002, GAP-003 (partial) |
| **`p1-word-bullet-srt.md`** | **orphaned — no row, not scanned** |
| **`sentence-segmentation.md`** | **orphaned — no row, not scanned** |
| **`aligner-proxy-and-media.md`** | **orphaned — no row, not scanned** |

The three orphaned files describe the core P1 build work. A cold `/super-bootstrap:todo`
surfaces none of it.

## Contract violated

1. **`super-bootstrap` SKILL.md:9** — greenfield *"produces overview.md, techstack.md, and
   an empty backlog.md … **No forward feature list is seeded** — ideas accrue as GAP
   through `/super-bootstrap:log`."* The run wrote 5 permanent specs and pre-seeded GAP rows.
2. **`todo` SKILL.md:3,9** — `todo` scans only `docs/superpowers/specs|plans` +
   `docs/backlog.md`. It **does not scan `docs/specs/`** (permanent SSOT, by design). So any
   forward work that lands there is invisible to the session opener.

## Root cause

The greenfield route conflated three distinct homes:

| Home | Purpose | `todo`-visible? |
|---|---|---|
| `docs/specs/` | permanent SSOT, written by the **spec phase** once behavior is pinned | no (by design) |
| `docs/superpowers/specs/` | temporal work orders | yes |
| `docs/backlog.md` GAP rows | unverified forward ideas | yes |

Greenfield forward design belongs in **GAP rows**. The route dumped it into permanent
`docs/specs/` — an **Axiom I** violation (speculative scaffolding emitted before any code
exists) that lands in an **Axiom VII** blind spot (a truth home outside the scanner → a
cold start cannot reconstruct full open-work state).

## Fix direction (for the resolving session)

- Greenfield `super-bootstrap` must route forward design to **GAP backlog rows**, never to
  `docs/specs/`. Reinforce the Phase-1/Phase-2 contract so the route cannot emit permanent
  specs during ideation.
- Consider a guard: greenfield seeding writes exactly `overview.md` + `techstack.md` +
  empty `backlog.md`; any `docs/specs/*` produced during a greenfield run is a contract breach.
- Verify the fix against this repro: re-run greenfield on an empty repo, assert
  `docs/specs/` stays empty and all forward intent is GAP rows reachable by `/super-bootstrap:todo`.
- script-captioner remediation (separate, that repo): convert the 3 orphaned specs into
  GAP rows (or move to `docs/superpowers/specs/`) so the board reflects real open work.
