# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-002` · `DEBT-004` · `GAP-002` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### GAP-002 — release-init is a one-shot generator with no update/sync channel for already-bootstrapped consumers

**Logged:** 2026-06-28 · **Source:** surfaced while routing DEBT-004 (the /release version-mirror SSoT fix) 2026-06-28
**Problem:** `release-init` generates `.claude/skills/release/SKILL.md` as a one-shot product — step 1 is detect-existing → blind overwrite, no update path. When the upstream template improves, already-bootstrapped consumer repos (any project type — web/app/anything, not necessarily Claude plugins) have no way to pull template improvements into their existing generated skill without a full overwrite that discards their customizations. Note: DEBT-004's fix is Claude-plugin/self-hosted-marketplace specific and deliberately does NOT go into the generic template — so this is a generator-hygiene gap (no update channel for template improvements), not a vehicle to ship the DEBT-004 fix. Likely earns a brainstorm on merge strategy (patch improvements in vs regenerate-with-diff) while preserving consumer customization.
**Area:** `plugins/super-bootstrap/skills/release-init/SKILL.md`, `plugins/super-bootstrap/skills/release-init/assets/template.md`
**Prior:** Design question is merge vs regenerate-with-diff; either path must preserve consumer-side customization.

### DEBT-003 — harness-bootstrap skeleton templates ship audit-flagged prose noise and a stack-blind author-guide into every consumer

**Logged:** 2026-06-27 · **Source:** Consumer bootstrap-run audit-harness-edits report (2026-06-27), five findings (F3–F7) triaged against axiom-principles canon — all verified real
**Problem:** Five skeleton-sourced findings across the two scaffold assets. F3: `claude-md-skeleton.md` L78 carries the karpathy-guidelines registry pin (`andrej-karpathy-skills@karpathy-skills`) — install-config detail invisible to agent decisions; if reproducibility needs it, route to `docs/techstack.md`. F5: L101 meta-clause "Summary below so this orchestrator knows the rule exists during planning" sharpens no decision. F6: L137–138 "Skeleton seeded at scaffold; grown sections fill via doc-sync" on both overview.md + techstack.md bullets — origin annotation; procedure already owned by § Doc Sync. F7: `rules-index-skeleton.md` L21 Adding-a-new-rule frontmatter example uses static `src/<scope>/**/*.ts` — scaffolds verbatim into no-src/no-.ts consumers; make stack-aware or use an illustrative placeholder (e.g. `path/to/scope/**`). F4 (heaviest, probe-first): `rules-index-skeleton.md` carries no `paths:` frontmatter, so scaffolded `rules/index.md` loads ambient every session carrying the Adding-a-new-rule author-guide (on-demand content in always-on layer); proposed fix of adding `paths:` is unverified — whether `paths:` actually suppresses the eager load needs a loading-mechanic probe before prescribing; also the active-rules list duplicates `CLAUDE.md` § Rules — trim-before-split applies. Sequence this work with/after DEBT-001 (current branch already restructures `claude-md-skeleton.md`) to avoid double-editing.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md`; `plugins/super-bootstrap/skills/harness-bootstrap/assets/rules-index-skeleton.md`
**Prior:** F3/F5/F6 are clean prose cuts; F7 is an example swap; F4 needs a loading-mechanic probe (does `paths:` suppress eager load for rules/index.md?) before fix, plus active-rules duplication trim.

*(seeded as items are surfaced during reviews, audits, or development)*
