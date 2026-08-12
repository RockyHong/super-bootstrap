# DEBT-070 — two shipped surfaces still describe the doc-sync gate as two-legged

**Logged:** 2026-08-13 · **Source:** out-of-scope finding from the `DEBT-069` triage verdict, re-verified at the gateway
**Problem:** The commit door's doc-sync gate has three legs — term-grep, reverse-citer lookup, forward link-target extraction (`plugins/super-bootstrap/skills/commit/SKILL.md:25`, and root [`README.md`](../../README.md):57 narrates all three). Two other shipped surfaces still describe it as two-legged, verbatim `only on a grep- or declared-citer hit`, so a reader landing on either gets a stale mechanism:

- `plugins/super-bootstrap/README.md:83` — the harness-hooks bullet
- `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:250` — the hook inventory table, row 1 (`commit-channel`)

Both are consumer-facing plugin prose, so the stale count ships. The third leg entered at `c9b839f`; these two surfaces were not carried in that change's propagation closure.

**Area:** `plugins/super-bootstrap/README.md:83`; `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:250`. Authoritative wording to match: `plugins/super-bootstrap/skills/commit/SKILL.md:25` · root [`README.md`](../../README.md):57 · the § Doc Sync layer-2 line of [`CLAUDE.md`](../../CLAUDE.md#doc-sync-non-negotiable).
**Prior:** Missed propagation closure on `c9b839f`, not a design disagreement — the two stale surfaces restate a mechanism they do not own.
