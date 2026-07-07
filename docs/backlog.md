# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-011` · `DEBT-008` · `GAP-016` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### BUG-011 — background Agent-tool subagent reported completion twice with zero writes landing, no visible error

**Logged:** 2026-07-08 · **Source:** dispatch-lane defect observation, this session
**Problem:** a general-purpose sonnet background subagent (Agent tool) tasked with creating 4 hook files reported completion twice with zero writes landing — no error surfaced, no permission denial visible to the gateway, git status clean of its target paths both times. A same-shaped sibling dispatch (CLAUDE.md rewrite, same model/type, same session) wrote fine. Gateway fell back to inline build. Silent claimed-done-no-write shape breaks dispatch-lane trust.
**Area:** Agent tool dispatch lane (background subagents + Write permissions), `plugins/**` new-file writes
**Prior:** possibly background-agent permission prompt auto-deny on new-file Write to `plugins/**`; possibly agent claimed-done without doing. Root-cause at next occurrence.

### GAP-016 — superpowers `writing-skills` Iron Law unevaluated against this repo's skill-authoring conventions

**Logged:** 2026-07-08 · **Source:** entry-discipline spec § 7 O2 (spec deleted post-merge — this row is its new home)
**Problem:** superpowers `writing-skills` (Iron Law: no skill without a failing test first, applies to new skills AND edits) is a candidate discipline for `plugins/super-bootstrap/skills/**` authoring, but unevaluated against existing conventions (skill-authoring lore + `/release` dispatch-shell check).
**Area:** plugin-skill authoring workflow
**Prior:** evaluate at next new-skill authoring session.

### GAP-015 — sdd (subagent-driven-development) invoke threshold undecided vs CLAUDE.md § Dispatch

**Logged:** 2026-07-08 · **Source:** entry-discipline spec § 7 O1 (spec deleted post-merge — this row is its new home)
**Problem:** superpowers `subagent-driven-development` offers a compaction-durable progress ledger (`.superpowers/sdd/progress.md`) + per-dispatch model-tier rule that CLAUDE.md § Dispatch only form-shadows today. Open question: at what plan size does invoking sdd whole beat the current § Dispatch machinery? Undecided — no evaluation criteria set.
**Area:** CLAUDE.md § Dispatch, cluster-3 route
**Prior:** decide at first large multi-task plan; note the outcome in docs/techstack.md.

### GAP-003 — harness-collab-optimization effect unmeasured; criteria reshaped by entry-discipline

**Logged:** 2026-07-06 (criteria reshaped 2026-07-08, entry-discipline session) · **Source:** harness-collab spec § 6 C1 (full text @ c1e2820) + entry-discipline spec W4
**Problem:** next harvest window measures: (a) off-card / off-lane leakage — change-work entered without a backlog card (entry-discipline E1/E2 regression); (b) cluster-1/3 omission shapes — bug fixed without root-cause entry, multi-step work without plan artifact — unharvestable under current ccm harvest taxonomy, companion `[ccm]` taxonomy item routes via `/contribute`; (c) route-line theater — E3 regression: confirm-stops firing where SSOT already resolved (07-04 baseline: "MCQ 給自由假象，實質只是確認"); (d) zero regressions on preserved wins (todo skip-dispatch fast path, four zero-retry dispatch lanes, audit gate); (e) principles-load user re-assertions →0 (baseline ~15/session worst case); (f) premature-commitment top-pain exit (still top pain 3 consecutive windows as of 07-08 — unmeasured post-entry-discipline). RETIRED: dispatch-majority ratio target — dispatch value is two-sided (context-hygiene + model-strength routing); a ratio target manufactures reflexive routing. Raw inline:dispatch ratio stays descriptive-only (mining baseline ~13:1, 35 sessions — not a harvested figure).
**Area:** next harness-pain harvest window
**Prior:** pure measurement pass, no code change. docsync-gate v3 value + one-shot-token cost (token consumed by a failing commit → forced re-scan) ride this window — v1-era defect evidence closed at GAP-014 triage 2026-07-08 (facets 1+3 verified fixed in v3 in-file; facet 2 structurally present, zero v3 firings measured, adopters pending re-sync).
**Measured (2026-07-08, ccm three-probe downstream timing audit — evidence: claude-config-manager `docs/harness-pain/reports/2026-07-08.md` + GAP-063 closing commits `d05742e`/`067fac4`):** (1) model-guard deny hits: only 2 real runtime pin-denials corpus-wide post-enforcement, both complied+succeeded next call — EXCLUDE the 4 spotify-radio denies on `super-bootstrap:todo` dispatches (`0696f836`/`15a02eb4`/`df6637d0`/`58108cd9`): stale-copy artifacts of a 06-26 agent-model hook predating ccm's BUG-007 namespaced-pin fix (07-01; copy refreshed 07-07 23:47), NOT guard noise and NOT a todo-template defect (todo's `model: sonnet` pin correct in every released version). (2) docsync-gate value since v3: zero organic catches AND zero v3 firings downstream — all 4 adopters still carry byte-identical v1 hooks (every sync predates the first fix; v3 deny text zero corpus hits); measurement blocked on adopter re-sync, which commit-skill's FROZEN drift check triggers on each adopter's next `/super-bootstrap:commit`. (3) unmeasured by this audit: premature-commitment top-pain, principles-load re-assertions, inline:dispatch ratio — DEBT-028 family did recur in-window (ChewLingo ×2 facets).
