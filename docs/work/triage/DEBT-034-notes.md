# DEBT-034 — write-once has no amendment clause; mutation authority is assigned to actors forbidden to mutate

## Findings

- **root cause:** not "no stated path for a falsified premise" (the card's framing) but one level up — **`docs/backlog.md` states row immutability without ever naming who may amend a live row, so every surface that needs a mid-life mutation names a destination whose owner refuses the write.** Direct evidence, four surfaces:

  - `docs/backlog.md:30` (= skeleton `plugins/super-bootstrap/skills/harness-bootstrap/assets/backlog.md:30`, byte-identical): *"The claim is write-once — captured at the richest-context moment, read cold by later sessions."* No exception, no amendment clause. Header `:19` sanctions exactly one mutation: `When resolved, **delete the row**`.
  - `plugins/super-bootstrap/agents/log.md:16` + `:78` assign row mutation to an owner — *"Edits or deletes on existing rows — the session that resolves an item owns its row"* / *"Row edits/deletes → the resolving session."* Combined with header `:19`, that owner's only sanctioned act is deletion. **Nothing covers a row's mid-life.**
  - `plugins/super-bootstrap/agents/log.md:21` names a second, different owner: the pickup judgment *"runs at `/super-bootstrap:todo` triage when a session picks the row up (**drop / re-log** / turn into spec)"*. This is the card's disposal #2 — and it **is** written down, contra the card's "neither is written down". But the actor it names is structurally forbidden: `CLAUDE.md` cluster row 8 defines that lane as *"read-only verdict phase"*, and `plugins/super-bootstrap/agents/triage.md:13` states *"no backlog row edits (the row is frozen at capture…)"*. The one actor authorized to drop/re-log is the one actor that may not write.
  - `plugins/super-bootstrap/skills/triage/SKILL.md:24` — a **third** unnamed-in-either-card path: `NEEDS_CONTEXT` → *"the user (or a follow-up `/super-bootstrap:log` amendment) supplies them."* `log.md:16` refuses precisely that write. Same refusal-loop shape as DEBT-036, previously uncarded.

- **card claims falsified / corrected:**
  - *"neither disposal is written down"* — **partly false**. Delete-and-re-log is written down (`log.md:21`), as a parenthetical with no procedure, no ID-preservation rule, and an actor that cannot execute it. Overwrite-in-place is genuinely unwritten.
  - *"leaving the falsified text leading is the failure the pickup-grounding fork in `docs/decisions.md` describes"* — **false as cited**. That fork (`decisions.md:31`) records the opposite: 2/2 controls *"led with the triage notes' framing over the row's stale Prior, surfaced the supersession, and **edited nothing**"*. It closes a rule-file port, not this gap — but it is direct evidence that a stale claim is already handled **without any row mutation, conditional on a verdict file existing**. `docs/work/triage/` did not exist at the DEBT-027 re-aim (still absent before this file), so that re-aim ran in the no-verdict-file condition the fork never tested.
  - *"what the DEBT-027 re-aim did — violates the letter of the rule"* — **confirmed**, commit `659a509`: summary + all four fields overwritten, ID kept, `**Source:**` annotated `re-aimed 2026-07-26 … closed in docs/decisions.md`. Note the outcome was *good* — ID preserved, supersession pointed at `decisions.md`. The defect is that it was unsanctioned, not that it was wrong.

- **scope reach (full propagation closure — answers the gateway's sizing note):**
  - `docs/backlog.md:19,30` — header (amendment clause)
  - `plugins/super-bootstrap/skills/harness-bootstrap/assets/backlog.md:19,30` — shipped skeleton, byte-identical, rides the same edit per `.claude/rules/repo-boundary.md` sync direction
  - `plugins/super-bootstrap/agents/log.md:16,21,78` — three separate clauses, two conflicting owners
  - `plugins/super-bootstrap/agents/triage.md:13` + `plugins/super-bootstrap/skills/triage/SKILL.md:24,36` — read-only floor and the `NEEDS_CONTEXT` amendment pointer
  - `plugins/super-bootstrap/skills/triage-report/SKILL.md:28` + `plugins/super-bootstrap/agents/triage-report.md:24` — the `dup` new-fact annotation contract (DEBT-036's surface)
  - `CLAUDE.md` § Doc Sync backlog-cleanup + `skills/triage/SKILL.md:36` — verdict-file lifecycle, pulled in only if the verdict artifact becomes the landing site
  - Checked and **out** of closure: `check-docs-consistency` annotates its own report, not the tracker (`SKILL.md:106`, `assets/tracker-annotation.md:44`); `drain/assets/relations.md:21` reads `**Area:**` only; `harness-bootstrap` ID re-plant writes the header counter, not rows.

- **DEBT-034 vs DEBT-036 — neither "one answer covers both" nor "genuinely separate":** two symptoms of one defect (unassigned mid-life mutation authority), plus a third uncarded instance (`triage/SKILL.md:24`). But the natural fix cut does **not** run along card lines — it runs along evidence grade (see Decision needed). Fixing either card alone leaves the shared header clause unwritten and the other two refusal-loops live.

- **attempted:** traced all four surfaces cold; verified the header text against the skeleton; pulled commit `659a509` for the practice evidence; swept every `.md` naming a write to an existing row to close the family. Stopped at verdict — the remaining question is a design fork, not a trace. No `§ Probes` table in `docs/techstack.md`; probes skipped.

- **auto-fix criteria:** fails 3 of 4. Scope spans six surfaces across three skills and three agents (not one feature surface). Test strategy is a `superpowers:writing-skills` control-arm pressure test, not unit/e2e — every surface is behavior-shaping harness prose per `.claude/rules/skill-authoring.md`. And the disposal choice is an open design fork.

## Decision needed

**Which mutation classes earn a sanctioned path, and is prose earned at all for the falsified-premise case?**

`docs/decisions.md` carries ~10 rows rejecting harness prose added without a failing control test ("adding it without a failing test violates the scoped RED rule"). The falsified-premise case has n=1 observed instance, and it produced a *correct* outcome ad hoc. The refusal-loops, by contrast, are a contradiction visible on the page with no behavior guess required. That asymmetry is the fork.

- **A — Split by evidence grade (recommended).** Land the refusal-loop half now as a pure consistency fix: give `triage-report/SKILL.md:28` and `triage/SKILL.md:24` a destination their owners actually accept, and reconcile `log.md`'s two conflicting owner clauses (`:16` vs `:21`) so one actor is named. Route the falsified-premise disposal to a `superpowers:writing-skills` RED first — control arm on the current header, a card whose premise evidence falsifies, and see whether a cold session actually mishandles it. Prose only if the control fails.
- **B — Author the full amendment clause now.** Take the card's Prior: write-once binds against *paraphrase*, a falsified premise is superseded in place with a mandatory pointer to `docs/decisions.md`, ID preserved. Covers all three refusal-loops in one header clause plus skeleton mirror. Fastest, but authors disposal prose for a case whose only observation already resolved correctly — the exact shape this repo's decisions.md repeatedly rejects.
- **C — No header change; the verdict artifact is the amendment site.** Route all three mutation classes to `docs/work/triage/{ID}-*` (already ID-keyed, already lifecycle-bound to the row via `CLAUDE.md` § Doc Sync cleanup, already the artifact `decisions.md:31`'s 2/2 controls read over a stale Prior). The row stays genuinely write-once; amendments accrete beside it. Costs: needs a writer for cards never triaged, and pulls the verdict-file contract open.
- **D — Delete-and-re-log only.** Promote `log.md:21`'s existing parenthetical to the header as the single legal disposal. Rejected on the card's own grounds — burns an ID that specs, sibling cards, and session carries reference, against header `:17`/`:19` which make the stable ID the point.

**Recommendation: A.** It is the only option that separates what is provably broken (three surfaces routing writes to actors that refuse — falsifiable today, no guess) from what is merely unspecified (which disposal a falsified premise earns — one observation, good outcome, no failing control). B and C both author disposal doctrine ahead of evidence; D contradicts the header's own stable-ID rationale. A's second half may well close as "unearned" after the RED, exactly as `decisions.md:23` and `:32` closed for the triage lane — and if so, the falsified-premise half of this card dissolves into the pickup-grounding coverage already recorded at `decisions.md:31`, leaving only the consistency fix.

**Note for whoever routes this:** the fix, whichever option lands, should carry `triage/SKILL.md:24` — a third refusal-loop instance neither DEBT-034 nor DEBT-036 names. It needs no new card if it rides this fix; it needs one if this card closes narrowly.
