# BUG-g6at — merge's rebase strategy fails on autorun branches still checked out by their worktree, and reports it as a conflict

**Logged:** 2026-10-20 · **Source:** device note from `jowagoko` (D:/Git/Podcast/jowagoko, autorun 5.2.0), 2026-10-20 run
**Problem:** `/super-bootstrap:merge` §4 picks rebase + ff for a 1-commit branch. On an autorun branch, `git rebase main autorun/x` fails with `fatal: 'autorun/x' is already used by worktree at …` — the sheet-phase worktree still checks the branch out. The conflict doctrine then aborts and reports a conflict that does not exist.
**Area:** `plugins/super-bootstrap/skills/merge/SKILL.md` §1 / §4; autorun worktree teardown order
**Prior:** Default `autorun/*` to `--no-ff` (teardown after merge), or detect branches occupied in `git worktree list` at §1 and go no-ff; report branch-occupied separately from conflict. Related: GAP-0cf5, BUG-szkd.

## Verdict — auto-fix · 2026-10-20

**Fix-shape:** systematic
**Probe-deps:** none
**Execution:** phased(skip: design) — depth: §4's existing "don't rewrite a branch another holder has" rule applied to one new instance, plus one non-conflict failure line, no open design fork; closure: one shipped skill file + one new bench fixture + the `docs/overview.md` bench list. RED first (shipped behavior-shaping prose, `skill-authoring` rule), then `audit-harness-edits`.

### Repro (pinned)

"`/super-bootstrap:merge` §4 picks rebase + ff for a 1-commit branch. On an autorun branch, `git rebase main autorun/x` fails with `fatal: 'autorun/x' is already used by worktree at …` — the sheet-phase worktree still checks the branch out. The conflict doctrine then aborts and reports a conflict that does not exist."

### Root cause (verified)

premise age: clean — no commit touched `plugins/super-bootstrap/skills/merge/` or `plugins/super-bootstrap/skills/autorun/` since 2026-10-20.

Direct evidence is the device telemetry the card quotes (the `fatal:` line). Three defects in `plugins/super-bootstrap/skills/merge/SKILL.md` combine to produce it:

1. **§5 Rebase strategy (line 77)** runs `git rebase {base} {branch}`. The two-argument form checks out `{branch}` before it replays. Git refuses to check out a branch that another worktree holds, so the command dies before any replay. No rebase is in progress after that, so nothing exists to conflict or to abort.
2. **§4 strategy table (lines 57-62)** does not test whether a branch is occupied. §1 (lines 37-40) does not run `git worktree list`. A 1-commit autorun branch therefore always gets "Rebase + fast-forward".
3. **The Conflict Doctrine (lines 23-29)** is the skill's only failure lane, and §5 line 89 sends every failure there. The doctrine has no branch for "the git command failed and left no unmerged paths". The agent fit the checkout refusal into the conflict lane and reported a conflict with an empty file list. §7 line 104 ("Branches skipped and why") is the correct report slot, but nothing routes a failure there.

Upstream cause: autorun does not tear down a DONE worktree before the merge (`plugins/super-bootstrap/skills/autorun/SKILL.md` lines 61 and 74). Park and Drop tear down. DONE only waits for `/super-bootstrap:merge`. So every DONE autorun branch reaches merge while its worktree still holds it. `git merge {branch} --no-ff` from the base checkout works on an occupied branch. Only the rebase path checks the branch out.

Fork settled without user judgment:
- **Detect occupancy generically. Do not match the `autorun/*` prefix (the Prior's first option).** `docs/decisions.md` line 88 closes the coupling fork: "Merge lane stays generic (rejected coupling it to drain's artifact name — SoC)." A branch prefix is the same coupling. `git worktree list --porcelain` (a `branch refs/heads/{branch}` line under a worktree that is not the current one) is generic git state. It also covers branches occupied by any other worktree tool.
- **Occupied → Merge --no-ff. Do not rebase inside the occupying worktree (`git -C <wt> rebase {base}`).** §4 line 62 already has the rule for a branch another holder uses: "don't rewrite shared history". A rebase from the occupying tree rewrites the HEAD of a tree that this skill does not own. Autorun's Rules put worktree-side git with the gateway behind a prompt (`autorun/SKILL.md` line 83). The no-ff row is the existing rule applied to one more holder. Worktree teardown order stays as it is. No autorun change is needed.

Family sweep: §5 is the only place in `plugins/` that checks out a feature branch. `git rebase {base} {branch}` appears only at merge line 77. §5's `git checkout {base}` (lines 78, 85) fails only when another worktree holds the base. Out of scope here, but the same failure line (fix item 3 below) covers it. The bench arms (`bench/merge-cd/arm-*.md`) are frozen derivatives of the shipped skill body for their own test. They are not a fix surface.

Fix shape (implement phase lands it):
1. §1 — add `git worktree list --porcelain` to the gather set.
2. §4 — add a row: "Branch checked out in another worktree → **Merge --no-ff** (a rebase would check it out)". Note the occupancy in the recommendation table.
3. §5 / Conflict Doctrine — a git command that fails and leaves no unmerged paths (`git diff --name-only --diff-filter=U` is empty) is not a conflict. Report the error line verbatim under §7 "skipped and why". Run no abort, because none is in progress.

### Files (fix surface)

- `plugins/super-bootstrap/skills/merge/SKILL.md:35-40` — §1 gather: add the worktree-occupancy read.
- `plugins/super-bootstrap/skills/merge/SKILL.md:57-62` — §4 table: add the occupied-branch → Merge --no-ff row.
- `plugins/super-bootstrap/skills/merge/SKILL.md:23-29`, `:89` — separate a non-conflict command failure from the Conflict Doctrine and send it to §7's skipped line.
- `bench/merge-occupied/` (new) — RED fixture shaped like `bench/merge-push/` and `bench/merge-cd/`: a base plus a 1-commit branch that a second worktree checks out. Run the current shipped body headless (expect: rebase attempt, then a conflict report or a failed absorb). Run the fixed body (expect: no-ff absorb, no conflict wording).
- Provenance: `merge/SKILL.md` is plugin source owned by this repo (no `.served` marker, not under `.claude/`). The edit lands here.

### Doc Impact

- `docs/overview.md:48` — the `bench/` line lists each fixture and gives a count ("21 measured fixtures"). Add the new bench and update the count.
- `README.md:92` and `plugins/super-bootstrap/README.md:22` — read. Both stay accurate ("aborts + surfaces the file list on conflict" / "delegates to `/super-bootstrap:merge`"). No change.
- `plugins/super-bootstrap/skills/autorun/SKILL.md` — read. No change is needed for this fix. A separate observation, not in scope: no rule tears down a DONE worktree after its merge (only Park and Drop tear down). Worktrees then stay until `release`. That gap is near GAP-0cf5's batch-landing flow. It is not this card's defect.
- Overlap check: GAP-0cf5 (batch landing) and BUG-szkd (resolver contract) touch the same file but different sections and different defects. Neither duplicates this card.

### Test Strategy: e2e
