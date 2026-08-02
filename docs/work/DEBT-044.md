# DEBT-044 — dispatch agents never evaluated against dispatch-purpose principle; some may collapse to inline

**Logged:** 2026-08-02 · **Source:** user capture via /super-bootstrap:log
**Problem:** This repo ships multiple dispatch agents (`plugins/super-bootstrap/agents/*`) and skills that dispatch them, but no agent has been formally evaluated against the dispatch-purpose principle (CLAUDE.md § Dispatch): dispatch exists to offload context to a subagent to prevent drift / context bloat and gain a clean-context benefit. Any dispatch that cannot meet that cut is overhead with no payoff — the gateway should handle it inline instead. The evaluation has never been done systematically; dispatch decisions were made ad hoc. Related: DEBT-039 covers `drain` and `release-init`'s inline-rationale documentation gap (pre-flight warning suppression), but is narrower and does not cover collapse as an option. `plugins/super-bootstrap/README.md` § Inline vs Dispatch documents the principle table but carries no per-agent rationale rows.
**Area:** `plugins/super-bootstrap/agents/` (all agents); skills that dispatch them; `plugins/super-bootstrap/README.md` § Inline vs Dispatch
**Prior:** For each agent, answer: does dispatching provide context-offload that prevents gateway drift or bloat, or does the gateway hold sufficient context to execute inline? Agents failing that test are collapse candidates — drop the subagent, fold the logic into the gateway skill. DEBT-039's per-skill inline-rationale row shape may serve as the evaluation record for agents that pass.

## Verdict — surface · 2026-08-02

### Findings

- **root cause (reduced): one agent, not eight.** `review-intake` is the only agent with no dispatching skill — grep of `subagent_type` across `plugins/*/skills/` returns 7 dispatch sites (`doc-sync-scan`, `help`, `log`, `plugin-digest`, `todo`, `triage`, `triage-report`), none for `review-intake`; it is routed by root `CLAUDE.md` § Dispatch prose alone. `plugins/super-bootstrap/README.md` § Inline vs Dispatch is **keyed by skill** (column 1 = `Skill`) and declares itself "the only home for inline-vs-dispatch rationale" (README:70), so an agent with no owning skill is structurally unable to hold a row there. Same key gap makes it invisible to `.claude/skills/release/SKILL.md` §1.5, which scans `plugins/*/skills/*/SKILL.md` only.
- **card premise partially falsified — "no per-agent rationale rows".** Literally true (rows are skill-keyed), but 7/8 agents already carry a stated dispatch rationale via their dispatching skill's row: README:58 (`plugin-digest`), :59 (`doc-sync-scan`), :64 (`todo`), :65 (`log`), :66 (`triage`), :67 (`triage-report`), :68 (`help`). The evaluation is not absent; it is indexed one indirection away.
- **card premise falsified — "some may collapse to inline".** No collapse candidate found. Two independent blockers:
  - **Model pin is structural.** Verified negative: zero `^model:` frontmatter across `plugins/*/skills/` and `.claude/skills/`; all 8 agents pin one (`haiku` ×2, `sonnet` ×5, `opus` ×1). `.claude/skills/release/SKILL.md:28` states the rule — "A skill frontmatter alone can't pin a model — bounded judgment left inline runs unpinned, at the gateway's tier." Collapse = every agent's work runs at gateway tier.
  - **Cold context is a correctness mechanism, not token economy, for 5 of 8.** `doc-sync-scan` ("blind to authoring rationale by design"), `triage` (priors isolation), `log` + `triage-report` (bias exclusion — shell passes no priors), `review-intake` (per `docs/decisions.md` row 22, the root cause of the review law's failure was *activation*, and the fix was a fire-moment container at claim entry — an inline judge is the falsified shape). Folding these into the gateway deletes the property they exist to provide.
- **the card's cut is narrower than the repo's SSOT.** The card frames dispatch-purpose as context-offload only ("any dispatch that cannot meet that cut is overhead with no payoff"). README:45-52 lists four dispatch reasons — model tier, heavy tool output, restricted toolset, parallelism/clean restart — and CLAUDE.md § Dispatch judges by propagation closure. Evaluating agents against the card's single-axis cut would return false collapse verdicts for `help` and `plugin-digest` (both cheap-context, both model-tier plays).
- **scope reach:** `plugins/super-bootstrap/README.md` § Inline vs Dispatch (the only write surface); read-only corroboration in `plugins/super-bootstrap/agents/*.md` (8 files, frontmatter + intro), `plugins/super-bootstrap/skills/{commit,help,log,resolve-plugins,todo,triage,triage-report}/SKILL.md` dispatch sites, `.claude/skills/release/SKILL.md` §1.5, `docs/decisions.md` rows 22/33-38, `docs/specs/harness-architecture.md`:261-265, :416.
- **attempted:** full 8-agent sweep against both the card's cut and the README's four-reason table; verified the model-pin premise by negative grep rather than taking README prose at face value; checked `docs/decisions.md` for a closed fork on agent collapse (none). Stopped at the fork below because the residue is a doc-key decision, not a defect trace.
- **DEBT-039 collision:** it owns adding `drain` + `release-init` inline-rationale rows to this same table §. Whatever shape lands here sets the shape there — batch them.

### Decision needed

- **How does the rationale SSOT hold an agent that no skill dispatches?** (`review-intake` today; any future gateway-routed agent tomorrow.)
- Options:
  - **A — keep the table skill-keyed, add an unowned-agent lane.** One extra row or short clause for agents dispatched by `CLAUDE.md` § Dispatch directly, carrying `review-intake`'s rationale (cold premise judge; inline defeats the mechanism per `docs/decisions.md` row 22). Smallest diff, no churn to the 7 existing rows, leaves `/release` §1.5's skill-only scan as-is.
  - **B — re-key the table to agent-level.** Per-agent rationale rows (what the card's Prior asks for), skills keep a mode column. Direct answer to "no per-agent rows", but rewrites 13 settled rows and splits one concern across two tables, with the model/tier facts then duplicated against each agent's own frontmatter.
  - **C — no doc change; close on the evaluation result.** The 7 skill rows already state the rationale, `review-intake`'s sits in `docs/decisions.md` row 22 + `docs/specs/harness-architecture.md`:261-265. Accepts that the table's "only home" claim (README:70) is inaccurate for one agent.
- recommendation: **A** — it fixes the one real gap (an agent outside the table's key) without re-keying a settled SSOT, and DEBT-039's two rows drop into the same shape unchanged. Note for whoever lands it: the *evaluation result* (zero collapse candidates) is history — it belongs in this block and the commit message, not narrated into the README, which holds only the binding present-tense rationale.

## Amendment — 2026-08-02 · per-item audit user-reviewed; residue on hold

The verdict's 8-agent sweep was reviewed per-item with the user. Outcomes:

- `todo` — keep for now; the cost remake is owned by GAP-050 → DEBT-022 (queued, same surfaces), not this card.
- `log` — collapse-to-inline candidate + dedup-must-surface-MCQ contract change → appended to DEBT-030.
- `help` — split to DEBT-045 (mechanical script path; dispatch saves no gateway context since the menu returns verbatim anyway).
- `plugin-digest` — keep Haiku (freeform README extraction — no true-mechanical path; judgment minimal; omission risk accepted at lifecycle frequency).
- `doc-sync-scan` / `triage` / `triage-report` / `review-intake` — keep; cold context is the correctness mechanism.
- Verdict supersession: the "DEBT-039 collision (add drain + release-init rows)" finding is falsified — both rows have existed since `71a3c2b` / `3ae1595`, predating DEBT-039; that card closes on git evidence with no diff.

Residue on hold: option A's README edits (unowned-agent row for `review-intake` + table-key note) wait on the user's open question — review-intake's trigger moment / whether it is a bandaid over an upstream cause.
