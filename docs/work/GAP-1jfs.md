# GAP-1jfs — what a build dispatch learned the hard way has no write-back step

**Logged:** 2026-10-27 · **Source:** device note from ComfyUI `workflows/agent` (a run of build dispatches on ComfyUI frontend subgraphs)
**Problem:** Implementers learn non-obvious behaviour through retries, failed approaches and workarounds (examples from the source: a legacy widget `PrimitiveNode` wired into a subgraph input never passes its value; server validation also visits lazy-switch branches) and report it in their hand-back text. The diff carries only the workaround code, and the commit door's doc-sync judges the diff, so the why and the dead ends never reach the repo's docs. A later cold dispatch rediscovers them by retrying. Not writing a learning is an omission, so nothing fires on it today.
**Area:** build-dispatch contract (root `CLAUDE.md` § Dispatch + `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md` § Dispatch), `plugins/super-bootstrap/skills/commit/SKILL.md`, `plugins/super-bootstrap/skills/harness-bootstrap/assets/techstack-skeleton.md`
**Prior:** proposed by the source in three parts — (a) the build-dispatch report gains a fixed "found the hard way" slot, each item stated as a reusable fact; (b) the commit door gains a lane beside doc-sync where each such item from this session's reports, plus the gateway's own retries, gets an outcome: landed in the repo's declared learnings home, or "already there"; (c) `harness-bootstrap` seeds a declared learnings home in `docs/techstack.md` (e.g. "Gotchas home: README.md § Gotchas") so the lane knows where to write and briefs can point at it. The source repo carries a prose stopgap in its `CLAUDE.md` § Build rules; prose moves the rate only, the door lane is the gate.

## Verdict — surface · 2026-10-27

### Findings

- premise age: clean. `git log --since=2026-10-27` shows no commit on the four Area paths.
- root cause (gap confirmed against current code): every write-back path in the shipped harness starts from the diff or from a card. Nothing starts from a dispatch's report text.
  - `plugins/super-bootstrap/skills/commit/SKILL.md` §3 builds its scan scope from `git diff` only: terms, citers, link targets and changed docs. §4 judges that scope. Rules § "Whole-diff-once" says the implementer never owns doc-sync. No step reads hand-back text.
  - `plugins/super-bootstrap/skills/harness-bootstrap/assets/agents-md-skeleton.md:28,36` already makes the executor report "what your change makes stale" and close with a list of unrun steps: uncommitted work, stale docs, owed work-tracking entries, questions. That list has no slot for a learning that has no diff.
  - `claude-md-skeleton.md:51` § Dispatch Build bullet requires "report the work as built with the file list". It has no learnings demand. Root `CLAUDE.md` § Dispatch matches it.
  - `techstack-skeleton.md` has no learnings home. § Architecture Rules and § Coding Patterns "grow via doc-sync", so they also fire only on a diff that touches the area.
  - Nearest existing route: `skills/session-close/SKILL.md:52` triages "inflight findings surfaced this session but not yet carded". That route goes to a card or a fix, never to a standing reference home, and it runs only at close.
  - The card's "omission, so nothing fires" claim holds. `docs/decisions.md` row 91 (action-vs-omission) also says a hook can only nudge an omission, never deny it. So a door step is the only gate shape available.
- aim: no duplicate card. `GAP-ym4e` is about doc-sync leak signals, which is adjacent but a different trigger. No closed fork is re-walked. Row 89 ("Capture is doc-sync's job, not a human act — the AI running doc-sync knows what pivoted") supports putting this capture in the commit door, not in a user-invoked skill. Part (b) is consistent with that row.
- scope reach (blast, both directions):
  - shipped: `commit/SKILL.md` (new lane, plus its Rules lines "Grep-gate is mechanical" and "Whole-diff-once", which the lane must state its relation to) · `agents-md-skeleton.md` § hand-back list (the executor-side slot) · `claude-md-skeleton.md` § Dispatch Build bullet and § Doc Sync (layer list, admission line) · `techstack-skeleton.md` (home declaration) · `harness-bootstrap/SKILL.md` § Pipeline-owned / seed-once classification and 2b drift handling for any new techstack section · `autorun` / `merge` deferred mode, because the lane must run at the merge boundary where worker reports arrive.
  - dogfood mirrors (asset lane: refresh byte-identical; prose lane: propagate): root `AGENTS.md`, root `CLAUDE.md` § Dispatch + § Doc Sync, `docs/techstack.md`.
  - docs: `docs/specs/harness-architecture.md` (check its doc-sync / dispatch narration), plugin README.
  - provenance: every touched path is this repo's own source or its placed derivative. No served file is in the closure.
- attempted: static read of the four Area surfaces, the AGENTS skeleton, session-close, and `docs/decisions.md`. I stopped at the design fork below. The work is a multi-surface harness design on behavior-shaping skill prose (`skill-authoring.md` requires a RED first). It fails auto-fix criteria 2 (scope contained) and 4 (no user judgment).

### Decision needed

- **Q1 — RED first or build first.** The table has repeated "RED never went red" closures on this harness: rows 94, 96, 98, 99, and `BUG-064`. Should a control run go before any build? The control holds the shipped `agents-md-skeleton` + commit door and replays a dispatch that hit a gotcha. Does the gotcha already land without new prose?
  - (a) RED first: build the bench, and ship only if the control drops the learning.
  - (b) Build directly on the source repo's report. The source repo already observed rediscovery in practice.
  - recommendation: (a). The current hand-back list already asks for "which docs the change makes stale", and a strong executor may route a gotcha through it. Repo precedent closes unmeasured prose additions.
  - settles by: `phased build` — a fixture repo with a planted gotcha, `claude -p` arms (control = shipped skeletons, arm = slot + lane), scored on whether the learning lands in a repo file.
- **Q2 — what is the learnings home.** The current admission line (`claude-md-skeleton.md:72`) says "Single-file mechanism stays in that file's own header or comment". Under that line, a gotcha bound to one workaround site belongs as a code comment, which is the implementer's in-diff job, and doc-sync then reaches it.
  - (a) Two-tier, using the existing rule: a single-site gotcha becomes a comment at the workaround, enforced by the executor contract. A cross-surface gotcha goes to an existing grown section (`techstack.md` § Coding Patterns / § Architecture Rules).
  - (b) A new declared home that `harness-bootstrap` seeds, e.g. `techstack.md` § Gotchas (card Prior (c)). It is a new pipeline-owned section and needs seed-once / drift classification.
  - (c) A consumer-declared pointer line ("Gotchas home: …") that the lane reads. It is configurable, but an undeclared repo has no home.
  - recommendation: (a). It needs no new section, it fits the existing admission rule, and the PrimitiveNode / lazy-switch examples are each single-site plus one cross-surface fact. Fall back to (b) only if Q1's bench shows the learning drops anyway.
  - settles by: preference (shipped-surface taste: a new section in every consumer's techstack). Partly measurable in the Q1 bench by whether arms land the learning at the comment site.
- **Q3 — where the gate sits.**
  - (a) Executor slot only: a "found the hard way" line in the `agents-md-skeleton` hand-back list. Prose; it moves the rate.
  - (b) Slot plus a commit-door lane that gives each reported item an outcome: landed / already there / dropped-with-reason. The lane's input is the session's dispatch reports, a non-diff and judgment-shaped input. Its relation to "Grep-gate is mechanical" and to deferred mode must be stated.
  - (c) Slot plus a gateway step at integration (Build bullet: "integrate + verify") instead of at commit.
  - recommendation: (b), if Q1 goes red. Row 89 places capture at doc-sync. The commit door is the one step every route passes, and it already holds outcome-marker discipline ("every doc the gate enumerates gets an outcome marker").
  - settles by: preference on commit-door weight. The Q1 bench measures whether (a) alone lands the learning.

### Notes

- Prior excluded as a lean: the card's three-part proposal was read as one option set, not as the target.
- Card corrections: none. The Area list omits `agents-md-skeleton.md`, which holds the actual hand-back contract, and `autorun` / `merge` deferred mode.

## Design — 2026-10-27

Q1 settled by repo precedent (`.claude/rules/skill-authoring.md` RED floor; `docs/decisions.md` rows 94/96/98/99): measure before building. Probe: 3 cold sonnet control runs holding only the shipped `agents-md-skeleton.md` contract, each hitting a planted non-obvious behaviour in a fixture. ≥2/3 land the learning in a repo file (comment at the workaround site or a doc line) → no gap, close the card. Otherwise Q2 = (a) existing admission rule and Q3 = (a) executor slot, built on that evidence. Budget: one probe round.

## Progress — 2026-10-27

Probe round 1 (budget spent): fixture `vendor/store.js` quirk (ttl ignored unless `configure({ expiry: true })`), 3 sonnet control arms under the shipped `agents-md-skeleton.md`. 0/3 hit the quirk through a failure — each read the vendor file first and passed on the first run — so the Design's ≥2/3 rule could not apply. Side evidence: 3/3 wrote the why as a comment at the workaround; 2/3 proposed a `docs/techstack.md` line in the hand-back only, left as "the orchestrator's call" (`AGENTS.md` routes `docs/` to the orchestrator). Unmeasured: a quirk only a failure reveals, and whether the gateway lands a hand-back doc proposal that has no diff anchor. Next round needs a quirk unreadable from source (bundled/minified vendor, cross-call state); held for the author's call on further budget.
