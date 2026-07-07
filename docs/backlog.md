# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-010` · `DEBT-008` · `GAP-013` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### GAP-013 — dispatch-tiering seam split across two repos: trigger half has doctrine but no enforcement organ

**Logged:** 2026-07-08 · **Source:** BUG-010 essence analysis session
**Problem:** the dispatch-tiering seam has two halves owned by two repos. super-bootstrap's gateway owns the TRIGGER (whether to dispatch at all — inline-vs-dispatch). CCM (device/global taste layer) owns tiering only AT/AFTER dispatch: model-reminder SessionStart hook, agent-model/workflow-model deny guards, work-discipline/model-tiering.md + axiom-principles/agent-shapes.md lore. CCM's enforcement is strictly downstream of the trigger — if the gateway never dispatches, there's no tool-call for CCM's hook/guards to intercept, so the whole tiering guard is moot. The trigger half has doctrine (agent-shapes "Dispatch test") but no enforcement organ: "failed to dispatch" is structurally un-hookable (an absent tool-call can't be intercepted). Symptom: ~13:1 inline:dispatch ratio (harness-collab-optimization baseline). Three OPEN hypotheses, none pre-judged: (a) super-bootstrap problem — CLAUDE.md § Dispatch trigger criteria don't fire hard enough and/or bundled skills aren't structured as dispatch-shells; (b) CCM problem — enforcement model has no trigger-side organ, may be inherently un-hookable or need a different mechanism (routes to `/contribute`, CCM is device/global read-only here); (c) not a real problem (Axiom II grounding) — inline for genuinely light work may be the correct Leverage call given dispatch overhead, meaning the dispatch-majority target itself is ungrounded and 13:1 could be correct.
**Area:** super-bootstrap `CLAUDE.md` § Dispatch (trigger criteria) + its bundled skills' dispatch-shell structure; CCM enforcement model (cross-repo, hypothesis b)
**Prior:** related to GAP-003 but distinct — do not merge. GAP-003 measures whether harness-collab-optimization moved the inline:dispatch ratio toward dispatch-majority; this card questions seam ownership itself + whether the dispatch-majority target is even the right target (hypothesis c). Triage decides among (a)/(b)/(c) — no fix pre-selected.

### BUG-010 — rules-index-skeleton.md "model tiering on skills" section: wrong paths-scope + false "only escape hatch" claim + consumer-broken todo wire

**Logged:** 2026-07-08 · **Source:** super-bootstrap dogfood, 2.17.0 self-sync run, audit-harness-edits verify pass (FAIL) on a runway pull-in
**Problem:** three defects in the shipped section (lines 28-34) that seeds every consumer's `.claude/rules/index.md`. Constraint is layer-scoped: this is a SHIPPED skeleton asset (downstream ≠ author), so it must be self-contained — no wire to the author's `.claude/guidelines/` tree or to plugin-internal paths a consumer repo lacks. (Scope note: this binds shipped `assets/**` only; this repo's own dogfood harness may legitimately taste-couple to served work-discipline, since those copies live here and the manager owns both sides.) (1) LAYER-PLACEMENT — pure `paths:` mechanic: `index.md` is `paths:`-scoped to `.claude/rules/**`, so it loads only when editing a rule; the section's audience is a `SKILL.md` author, who never triggers it → silent-miss at its real moment (defensible as a `## Related convention` see-also for the rule-vs-skill fork — author's call). (2) FACTUAL OVERCLAIM — "…the only tiering escape hatch" is false on Claude Code's own tool schema: the `Agent` tool and Workflow `agent()` both accept a `model` param (opus/sonnet/haiku/fable), so a skill can dispatch an ad-hoc model-tiered agent without a typed `agents/<name>.md` file — the typed-agent file is the reusable/named pattern, not the only mechanism. (3) BROKEN INTERNAL WIRE (self-consistency) — line 34 `See skills/todo + agents/todo.md for the pattern` points at super-bootstrap's own internals; seeded into a consumer repo with no `skills/todo`, the pointer doesn't resolve. downstream ≠ author → the seeded rule must be self-contained.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/rules-index-skeleton.md` § "Related convention — model tiering on skills" (lines 28-34) — fix at skeleton SSOT, then re-sync consumers
**Prior:** keep the whole fix guideline-free (plugin self-consistency is the constraint). (1) extract to its own `skills/**`-scoped rule (e.g. `skill-model-tiering.md`) + mirror a one-line bullet in `CLAUDE.md § Rules` — OR confirm it's an intentional see-also and leave it. (2) soften to e.g. "the repo's sanctioned tiering pattern". (3) make the example self-contained — drop the concrete `skills/todo` path, or qualify it explicitly as "super-bootstrap's own `todo` skill", so a consumer isn't sent to a path their repo lacks.

### GAP-012 — docsync-gate v3 residue: compound Bash commands targeting a different repo are denied by this repo's gate

**Logged:** 2026-07-08 · **Source:** docsync-gate B-prime redesign session (commit 7e8f7b1), live scratch-repo probe, 2026-07-07
**Problem:** the gate's `*"git commit"*` recheck (defense-in-depth leg) denies compound commands that contain the literal "git commit" but target a different repo — e.g. `cd $TMP/scratch && git init && git commit` in a test fixture setup. PreToolUse inspects the command string pre-execution; hook-input `cwd` is the shell's invocation cwd (this repo), not wherever the command `cd`s to, so the commit's actual target repo is undecidable at the gate.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/docsync-gate.sh`
**Prior:** accepted by design — string heuristics (detect `cd`/`-C`/`mktemp`) would re-enter the syntax-matching fragility class the v3 redesign exited. Deny message self-explains, remedy is running the scan. Re-triage only if Claude Code exposes richer semantic tool context (e.g. resolved target repo) to PreToolUse.

### GAP-003 — harness-collab-optimization effect unmeasured against spec's acceptance targets

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session, spec `docs/superpowers/specs/harness-collab-optimization.md` § 6 acceptance criteria, item C1
**Problem:** the optimization's real-world effect is unverified — no harvest window has yet checked: premature-commitment not top pain shape (first time in 4 windows), model-guard deny hits ≈0 (baseline 35/window), principles-load user re-assertions →0 (baseline ~15/session worst case), authoring inline:dispatch ratio moving from ~13:1 toward dispatch-majority, zero regressions on preserved wins (todo skip-dispatch fast path, four zero-retry dispatch lanes, audit gate).
**Area:** next harness-pain harvest window (spec deleted post-merge; acceptance targets inlined above, full text @ c1e2820)
**Prior:** pure measurement pass at the next harvest window, no code change. Also measure docsync-gate value since v3 (2026-07-07): organic catches (agent stopped from committing genuinely-stale docs) vs friction denies — zero organic catches in the gate's first 24h; drop-the-gate stays a future evidence call.
