# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-002` · `DEBT-003` · `GAP-001` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### DEBT-003 — harness-bootstrap skeleton templates ship audit-flagged prose noise and a stack-blind author-guide into every consumer

**Logged:** 2026-06-27 · **Source:** Consumer bootstrap-run audit-harness-edits report (2026-06-27), five findings (F3–F7) triaged against axiom-principles canon — all verified real
**Problem:** Five skeleton-sourced findings across the two scaffold assets. F3: `claude-md-skeleton.md` L78 carries the karpathy-guidelines registry pin (`andrej-karpathy-skills@karpathy-skills`) — install-config detail invisible to agent decisions; if reproducibility needs it, route to `docs/techstack.md`. F5: L101 meta-clause "Summary below so this orchestrator knows the rule exists during planning" sharpens no decision. F6: L137–138 "Skeleton seeded at scaffold; grown sections fill via doc-sync" on both overview.md + techstack.md bullets — origin annotation; procedure already owned by § Doc Sync. F7: `rules-index-skeleton.md` L21 Adding-a-new-rule frontmatter example uses static `src/<scope>/**/*.ts` — scaffolds verbatim into no-src/no-.ts consumers; make stack-aware or use an illustrative placeholder (e.g. `path/to/scope/**`). F4 (heaviest, probe-first): `rules-index-skeleton.md` carries no `paths:` frontmatter, so scaffolded `rules/index.md` loads ambient every session carrying the Adding-a-new-rule author-guide (on-demand content in always-on layer); proposed fix of adding `paths:` is unverified — whether `paths:` actually suppresses the eager load needs a loading-mechanic probe before prescribing; also the active-rules list duplicates `CLAUDE.md` § Rules — trim-before-split applies. Sequence this work with/after DEBT-001 (current branch already restructures `claude-md-skeleton.md`) to avoid double-editing.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md`; `plugins/super-bootstrap/skills/harness-bootstrap/assets/rules-index-skeleton.md`
**Prior:** F3/F5/F6 are clean prose cuts; F7 is an example swap; F4 needs a loading-mechanic probe (does `paths:` suppress eager load for rules/index.md?) before fix, plus active-rules duplication trim.

### DEBT-002 — doc-sync propagation-closure sweep scoped to plugins/, misses root-level pipeline-touchable files

**Logged:** 2026-06-27 · **Source:** DEBT-001 bootstrap tier-split refactor session, caught at /release step (commit 1e724a2)
**Problem:** Doc-sync / refactor propagation-closure greps cover `plugins/` but not root-level files. `marketplace.json` `plugins[0].description` staled after the DEBT-001 tier-split refactor; fixed in 1e724a2, but the sweep scope gap recurs on any future behavior refactor that changes what the plugin or marketplace descriptions narrate.
**Area:** doc-sync procedure; `.claude-plugin/marketplace.json`, root `README.md`
**Prior:** Sweep grep pattern hard-scoped to `plugins/` — extend coverage to root-level pipeline-touchable files.

*(seeded as items are surfaced during reviews, audits, or development)*
