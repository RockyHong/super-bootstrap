# BUG-szkd — merge/autorun route conflict resolution to an agent the runway's commit-channel hook forbids from concluding

**Logged:** 2026-10-20 · **Source:** device note from `magnetized-remake` (D:/Git/Games/Magnetized Remake, runway 5.2.0), 2026-10-17
**Problem:** `merge` aborts on conflict and routes resolution to "a conflict-resolution agent". The runway's own `harness-bootstrap/assets/hooks/commit-channel.sh` denies raw `git commit` from subagents, and a merge conclusion is a commit, so the resolver subagent stopped at a staged merge every time: gateway commits, gateway ff's, resume the subagent — 4 round trips for 4 branches, each re-reading context. The routing as written collides with the runway's hook.
**Area:** `plugins/super-bootstrap/skills/merge/SKILL.md` conflict routing; autorun's conflict routing; `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.sh`
**Prior:** State the resolver contract wherever resolution routes to an agent: the agent leaves the merge staged, the gateway concludes it. Related: GAP-0cf5.

## Verdict — surface · 2026-10-20

### Findings

- premise age: clean. No commit touched `skills/merge/`, `skills/autorun/` or `assets/hooks/commit-channel.sh` after 2026-10-17.
- root cause (telemetry first): the magnetized-remake transcripts hold three resolver subagents (`agent_type` set, attribution `super-bootstrap:merge`). They split two ways on how to conclude the merge.
  - `ce2e65a2…/subagents/agent-af47f8fd4d4b4f7a3.jsonl` and `34834f5d…/subagents/agent-a77e572708a9a1894.jsonl`: raw `git commit` was denied. Both then refused `git merge --continue` on purpose ("it runs the same commit and would get around the hook"), left the merge staged and reported back. These are the card's round trips.
  - `a855fe0b…/subagents/agent-aa85ffe7d3740400d.jsonl`: denied the same way, it read the deny text "git merge / git tag are orchestrator ops, unaffected" as permission. It wrote `MERGE_MSG` and ran `GIT_EDITOR=true git merge --continue`, and the merge commit landed from the subagent.
- mechanism: the hook does not block the conclusion. Its regex (`commit-channel.sh:42`) matches only a `git … commit` invocation, so `git merge --continue` / `git rebase --continue` pass. The deny text (`:50`) and header (`:15-16`) also exempt `git merge` without qualification. `merge/SKILL.md:29` sends work to "a conflict-resolution agent" and does not say who concludes. So the defect is an unstated resolver contract plus an ambiguous deny text. Each resolver guesses, and the guesses differ. The card's "the hook forbids concluding" is the hook's stated intent, not its mechanism.
- card corrections: (1) autorun has no conflict routing to an agent. `autorun/SKILL.md:17` ends the turn on a base-ff conflict, and `:74` sends DONE rows to `/super-bootstrap:merge`. The `autorun's conflict routing` Area entry is not a live surface. (2) The 4-round-trip cost is mostly GAP-0cf5's concern. Under the Prior's contract, each conflicted branch still costs one gateway conclusion. The batch-mode Prior in GAP-0cf5 (gateway commits each merge, only judgment-grade conflicts dispatch) is what removes the repeats.
- standing doctrine: `CLAUDE.md` § Dispatch says "Subagent commits route through the commit door … the gateway commits", and autorun defers doc-sync "to the merge boundary" (`commit/SKILL.md:18`). A merge commit concluded by a subagent skips both. This settles who concludes in favor of the Prior. No skill or door says how doc-sync runs at that boundary.
- closed fork touched: in `docs/decisions.md`, the row "Widen the commit-channel hook past Bash `git commit`" closes with "Reopen if a subagent lands a commit through any bypass class in practice." The `a855fe0b` run is a subagent landing a commit through `git merge --continue`. Whether that counts as the trigger, or `git merge` stays the exempt "orchestrator op", is the user's call on a closed fork.
- scope reach: `plugins/super-bootstrap/skills/merge/SKILL.md:3,29,103` (resolver contract). Possibly `assets/hooks/commit-channel.sh:15-16,42,50` + `tests/commit-channel.test.sh` + byte-identical dogfood `.claude/hooks/commit-channel.sh` (confirmed `cmp`-identical) + the `docs/decisions.md` row. Overlap: GAP-0cf5 (batch landing, same merge surface) and BUG-g6at (same skill, different section). Neither duplicates this card.
- attempted: static read of merge/autorun/hook, the decisions sweep, open-card overlap, and the device transcript grep. Stopped because the hook half re-walks a closed fork. No `§ Probes` table, so no probes ran.

### Decision needed

- Question 1, who concludes a resolved merge. Options:
  - (A) The resolver leaves the merge staged and reports. The gateway concludes through the commit door, where merge-boundary doc-sync can run.
  - (B) The resolver concludes with `git merge --continue`, and the skill and deny text state that this is allowed. This is fewer turns, but the commit bypasses the door.
- Question 2, enforcement for (A). Options:
  - (i) Prose contract only. State it in `merge/SKILL.md` § Conflict Doctrine step 3, and reword the hook's deny text and header so they no longer read as permission for a subagent to conclude a merge. This is a frozen-asset touch: version bump + dogfood refresh.
  - (ii) Reopen the decisions row and add `merge --continue` / `rebase --continue` (and a resolving `git merge` commit) to the subagent deny. This also needs a test-case update.
- recommendation: (A) + (i). § Dispatch already binds (A). (i) removes the ambiguity that split the three resolvers. (ii) follows the row's own ground ("a routing guard to the door, not a containment boundary"), so take it only if the user counts the `a855fe0b` landing as the reopen trigger. Fold the round-trip cost into GAP-0cf5, not this card.
- settles by: Question 1 by `CLAUDE.md` § Dispatch (cited above). Question 2 by user authority on the closed-fork reopen (risk / preference). After the ruling, build gates: the skill-prose edit needs a RED micro-test per `.claude/rules/skill-authoring.md` (dispatched probe). The hook edit needs a unit case in `tests/commit-channel.test.sh`.

## Design — 2026-10-20

Q1 → (A): the resolver leaves the merge staged and reports; the gateway concludes through the commit door. Settling source: `CLAUDE.md` § Dispatch ("Subagent commits route through the commit door … the gateway commits").
Q2 → (i) + (ii): state the resolver contract in `merge/SKILL.md` and reword the hook's deny text/header; also add `merge --continue` / `rebase --continue` to the subagent deny. Settling source: `docs/decisions.md` row "Widen the commit-channel hook past Bash `git commit`" — its literal reopen bar ("a subagent lands a commit through any bypass class in practice") is met by the `a855fe0b` run, and the class is command-text matchable (unlike the script-indirection class the row keeps closed), the same shape as the PowerShell reopen that row already shipped. The decisions row gets the reopen recorded. Round-trip cost folds into GAP-0cf5.
