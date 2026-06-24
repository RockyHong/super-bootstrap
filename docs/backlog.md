# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-002` · `DEBT-001` · `GAP-001` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

**Row shape** — stable ID + frozen claim, newest at top. When resolved, **delete the row** — git history is the archive.

```
### {BUG|DEBT|GAP}-### — {one-line summary}

**Logged:** {date} · **Source:** {where this surfaced}
**Problem:** {what's broken / rotting / missing}
**Area:** {files or module}
**Prior:** {one-line suspected cause or proposed fix — optional}
```

The claim is write-once — captured at the richest-context moment, read cold by later sessions. Sessions that pick a row up work from it; working history lives in specs/plans, not on the row.

---

## Open

### DEBT-001 — bootstrap pipeline has bundled concerns + wrong detection key; needs tier-split + dogfood refactor

**Logged:** 2026-06-25 · **Source:** architectural review deferred from BUG-002 session (2026-06-25); separated per Axiom IV (one unit, one goal)
**Problem:** `/super-bootstrap` greenfield bundles three distinct concerns in one bespoke flow: generic-harness install, tech curation, and product ideation Q&A. Detection keys on code-presence, so a mature-but-undocumented repo gets no overview/techstack seed. The design diverges from the axioms canon and accumulates drift in a 487-line skill with existing forcing-functions (drift-check, migration tables, re-run idempotency). Proposed locked design (grounded in session discussion):
  1. **Unified detection** — key on SEED-DOC presence (overview.md + techstack.md present and substantive?), not code-presence. Absent → install + seed; present → skip to curation. Collapses the complex Phase-0 greenfield gate.
  2. **Two-tier harness install** — TIER-1: generic (CLAUDE.md frame + todo/log pipeline + empty backlog + docs/superpowers/ skeleton; tech-agnostic, installs first on any no-seed-doc repo). TIER-2: tech curation (resolve-plugins, tech-specific rules, release skill; runs after techstack.md exists). CLAUDE.md write relocates out of harness-bootstrap scaffold into tier-1 (single write); harness-bootstrap reduces to tier-2 curation only.
  3. **Bootstrap writes zero product content** — greenfield seeds exactly 2 GAP cards: "pin down product overview" and "decide techstack" (blocked on the overview card). Generic-titled; product idea captured at PICKUP via brainstorm, not at bootstrap. The bespoke Phase-1 ideation Q&A dissolves into "the first brainstorm reached through the normal door". Dogfood: bootstrap uses its own pipeline (log → todo → brainstorm) to establish the product.
  4. **Method routed at PICKUP not capture** — cards carry `Prior: HINT` (not locked route); triage decides: no code → brainstorm; code present + undocumented → distill-repo-essence. Honors backlog.md's "no phase prescription" principle.
  5. **Autonomous tier-1, no consent gate** — invoking the command IS consent. One post-hoc heads-up line in done-summary: what was written/changed (CLAUDE.md, settings.json) + "review with git diff". Disclosure + reconciliation-enabler for users with existing harness taste.
  6. **Two silent correctness moves** (not gates): git-init if absent (so the promised git diff exists); re-run idempotency (detect existing cards, don't re-spawn them).
  Non-goals: no roadmap tier (parallel truth home rots; cards are transient + self-consuming); no clobber gate (uncommitted hand-authored config overwritten = user's risk).
**Area:** `plugins/super-bootstrap/skills/super-bootstrap/SKILL.md` + `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md`
**Prior:** design locked in session dialogue grounded in axioms canon (2026-06-25); pickup warrants grounding + spec + plan phases given scope (487-line skill restructure, migration tables, re-run idempotency, drift-check forcing-functions all in play).
