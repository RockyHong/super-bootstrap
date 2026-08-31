## Scan

1. **Read the surface owner.** Read the consumer's **CLAUDE.md § Doc Sync** — it owns the doc-surface definition and write boundary; the residual (step 4) homes against that surface. If absent, default the surface to `docs/**` plus behavior-narrating prose outside it (root `README`, plugin READMEs — `plugins/*/README.md` — where the repo ships plugins, manifest description fields the diff's behavior changes).

2. **Extract what the diff asserts** — each posture, default, or contract it states, written as the question it answers ("how does X get installed?", "which door owns Y?", "what is the default for Z?"). Both added and removed lines carry claims: a removed old term is exactly what a stale doc still names; a new file is all-added lines, so every claim in it is diff content; an unchanged context line inside a hunk is a claim too.

3. **Judge the scope docs.** Read every scope file whole — a declared citer of a changed doc is the highest-prior candidate class. Per diff question, set each scope doc's answer beside the diff's. Two docs answering one question differently is staleness, and the untouched doc is the stale one — its own prose reads as current until you have the diff's answer beside it. A scope doc that itself appears in the diff: judge its unchanged sections against the diff's claims — same-commit edits can contradict each other. For each candidate, record path + what looks outdated (one line) + the relevant diff hunk.

4. **New-assertion residual (diff-scoped).** Two lanes over the diff's *new* asserting lines:
   - **Linked line** — its target file is in your scope (the gate extracts targets mechanically). Set the asserting line beside the target section item by item — lists and rosters compare per entry, not by gist. A link is a pointer, not proof of agreement: a target disagreeing with the asserting line, with no declared supersession naming which side binds, is a candidate.
   - **Unlinked line** — grep the doc surface for the question it answers, targeted by the claim's own terms; a file whose leading frontmatter declares `dimension: history` is frozen provenance — leave it out of this grep. An existing doc answering the same question differently — or the same fact now stated in two homes — is a candidate.

   Bounded by the diff's new lines, never by the surface's size.

5. **Judge staleness, don't just match.** A term hit is a lead, not a verdict — read the prose and decide whether the diff actually made it wrong. A doc that still describes current behavior is not stale — but "current" means current *after* this diff lands, which is what step 3 settles for claims.

## Output contract

Return exactly one shape:

**`stale-docs`** — candidates found:
- `candidates`: per item — `path`, `outdated` (one line), `hunk` (relevant diff excerpt)
- `note`: "surface only — the gateway resolves each with the user, then commits"

**`clean`** — the surface is consistent with the diff; nothing stale.

When a candidate is too ambiguous to judge, include it under `stale-docs` with the ambiguity named in `outdated` — a false positive costs a glance; a missed stale doc ships.

## Rules

- **Read-only.** Never edit, stage, or commit. Surface candidates; the gateway resolves with the user.
- **Whole-diff, scoped surface.** You receive the full integrated diff — judge it as one; never assume another pass covers part of it. The doc side stays scoped: the dispatched scope plus residual-targeted greps, never a whole-surface walk.
- **Judge, don't grep-and-dump.** Every candidate names a concrete staleness, not a bare term match.
