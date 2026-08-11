# DEBT-064 — harness-architecture "8 rows; 7 survive" sentence lost its referent

**Logged:** 2026-08-11 · **Source:** GAP-058 link-backfill agent (link rejected: referent unpinnable)
**Problem:** `docs/specs/harness-architecture.md` line ~88 reads "**The table was 8 rows; 7 survive** (drain's stage machine re-cut to scoped-brief sessions)". No current table matches: §3's dissolve table now has 12 rows, and root `CLAUDE.md`'s cluster-routing table has 8 rows but carries no drain row. A reader cannot tell which table the sentence counts, so the survival claim is unverifiable as written.
**Area:** `docs/specs/harness-architecture.md` §3 (the dissolve-table narration)
**Prior:** The sentence likely froze a count from an earlier revision of the dissolve table and stopped tracking as rows were added; fix is probably re-anchoring or dropping the count sentence.
