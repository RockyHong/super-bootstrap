# DEBT-104 — the commit door has no guard against a shared index: a concurrent session's staged paths ride into this session's commit

**Logged:** 2026-08-27 · **Source:** two sessions in one checkout — one `git add`-ed five paths, the other's `git commit` landed seconds later and swept them in; split by soft-reset afterwards
**Problem:** [`commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) § 5 stages by explicit path and never `-A`, but reads nothing back from the index before `git commit`: whatever another session (or a background agent) already staged is committed under this session's message. Session isolation is enforced at `git add` only, while the commit records the whole index. Same hole on the audit stamp — it fingerprints `git diff --cached --name-only`, so a foreign staged harness path widens the stamped set.
**Area:** `plugins/super-bootstrap/skills/commit/SKILL.md` § 5 (message + commit) · `skills/commit/assets/doc-links.sh` untouched · optionally `audit-harness-edits` stamp step (device skill — `/contribute`, not a local edit)
**Prior:** in § 5, after `git add <explicit paths>`, diff `git diff --cached --name-only` against the session file list; a path outside it → stop and surface (unstage-and-continue / abort), never commit through it. Keep `git add` + check + `git commit` in one flow so no window opens between them. Land after DEBT-101 / DEBT-102's in-flight edits to the same file.
**Test-feel:** manual
**Blast:** local

## Verdict — auto-fix · 2026-08-27

**Fix-shape:** design
**Probe-deps:** none
**Execution:** full — depth: behavior-shaping protocol prose in an ambient shipped door, with a mechanism choice and a failure branch to author (the skill-authoring RED floor applies); closure: the guard restates the door's frontmatter `description` promise and is narrated by two READMEs plus `overview.md`, so the edit is not self-contained.

### Repro (pinned)

From the card, verbatim: "two sessions in one checkout — one `git add`-ed five paths, the other's `git commit` landed seconds later and swept them in; split by soft-reset afterwards". Claim under test: "§ 5 stages by explicit path and never `-A`, but reads nothing back from the index before `git commit`: whatever another session (or a background agent) already staged is committed under this session's message."

### Root cause (verified)

**Premise confirmed — the gap exists exactly as described.** [`commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) § 5 (line 35, unchanged by the DEBT-103 sibling build, which touched only § 3 line 27) reads at the staging seam: `git add <explicit paths>` — never `-A` / `.`, never secrets (`.env`, keys). Commit with HEREDOC formatting; `git status` after to verify clean. No index readback, no comparison against the § 1 session file list, nothing between `git add` and `git commit`. Session isolation is asserted at three prose sites (frontmatter `description` line 3, § 1 line 13, Rules line 51 — "The session list decides; prior dirty state is sacred. Explicit paths, never `-A`") and enforced at exactly one operation, `git add`; `git commit` records the index, not the add-list, so the invariant is stated and never checked.

The door does read the index once — § 2 line 15 `git diff --staged` — but (a) its output feeds no comparison rule anywhere in the skill, and (b) it sits before the whole doc-sync gate, whose § 4 dispatch is a minutes-long window. The one existing index read is therefore both unasserted and stale by the time § 5 runs.

**Two corrections to the card's `Prior` — evidence, not preference:**

1. "Keep `git add` + check + `git commit` in one flow so no window opens between them" is unreachable for harness commits on this device. The served device skill `audit-harness-edits` § 5 mandates the opposite whenever a commit stages harness paths: "Keep the three calls separate" — `git add` / stamp / `git commit` — because "a `git add … && git commit` compound widens the gate to the whole dirty tree". A mandated third call sits between add and commit, so the residual race is irreducible for that class; the guard's value is detect-before-commit, not atomicity. Fix shape follows: the readback is the **last action before `git commit`**, not merely "after `git add`".
2. The alternative mechanism — `git commit -- <paths>` (pathspec-limited: commits HEAD plus the named paths, ignoring the rest of the index) — would eliminate the class by construction rather than detect it, and is **not** chosen: it drops the foreign staging silently, against the door's standing surface-and-resolve law ("never silently skip" at every other gate), and `--only` is fatal mid-merge. Recorded so implement does not re-open it; the readback-and-surface shape from `Prior` stands.

**Secondary defect in the same sentence, in scope for the same edit:** "`git status` after to verify clean" contradicts Rules line 51's "prior dirty state is sacred" — in a checkout carrying another session's uncommitted work, post-commit `git status` is never clean, so the stated success check either forces a wrong conclusion or invites the `-A` sweep the door forbids. The post-commit check should be that the commit's `--name-only` set equals the session list, not that the tree is clean.

**Family sweep — scopes to § 5, named:** the only sibling stage-then-commit flow in this repo is `.claude/skills/release/SKILL.md:110` (`git add <two version files>` then commit), identical exposure, but it is a rendered instance of the shipped template `plugins/super-bootstrap/skills/release-init/assets/template.md:116` — its fix is a template edit under its own card, not this one. Drain-worktree commits are exempt by construction: a linked worktree carries its own index, so nothing is shared across sessions there.

**Aim check:** live. [`DEBT-103`](DEBT-103.md)'s Verdict already records that "DEBT-104 touches `commit/SKILL.md` §5 and declares `skills/commit/assets/doc-links.sh` untouched" — adjacent, not duplicate, and its § 3 edit has landed. No row in [`docs/decisions.md`](../decisions.md) closes a fork on the staging seam (all four commit-door rows concern § 3's doc-sync lanes). Blockers cleared: DEBT-101 / DEBT-102 landed in `60ae831` / `d73d922`. No `§ Probes` table in [`docs/techstack.md`](../techstack.md), so no probe fired.

### Files (fix surface)

- `plugins/super-bootstrap/skills/commit/SKILL.md:35` — § 5, the whole fix: insert the readback (`git diff --cached --name-only` against the § 1 session list) as the final action before `git commit`, with the stop-and-surface branch (unstage-and-continue / abort — never commit through it, never unstage on the door's own initiative); reconcile the "`git status` after to verify clean" clause in the same sentence.
- `plugins/super-bootstrap/skills/commit/SKILL.md:51` — Rules "Session-isolated" bullet: the law the guard mechanizes; state that the index is verified against the session list at commit, so the law reads as enforced rather than asserted.
- `plugins/super-bootstrap/skills/commit/SKILL.md:3` — frontmatter `description` "Session-isolated (never -A)": a description field whose behavior the diff changes, so doc surface per [`CLAUDE.md` § Doc Sync](../../CLAUDE.md#doc-sync-non-negotiable); extend or confirm.
- `plugins/super-bootstrap/skills/commit/SKILL.md:15` — § 2's `git diff --staged` is the only pre-existing index read and feeds nothing; optional early-warning point (foreign staging spotted before the expensive § 4 dispatch — beside the § 5 guard, never instead of it).
- **Out of repo, no local edit:** `~/.claude/skills/audit-harness-edits/SKILL.md:125` — `bash "$HOOK" --stamp "<verdict>" $(git diff --cached --name-only)` widens the stamped set by the same mechanism. Served device skill → `/contribute` per [`repo-boundary`](../../.claude/rules/repo-boundary.md). Hand-off note: a § 5 guard stopping before `git commit` covers the stamp only when the operator runs the check before the stamp call, so the device-side fix stays the durable one.

### Doc Impact

- [`README.md`](../../README.md) line 81 — commit-door row, "session-isolated (never `-A`)": the guard strengthens the same promise; extend only if the row should say the promise is now checked, else confirm-unchanged.
- [`plugins/super-bootstrap/README.md`](../../plugins/super-bootstrap/README.md) line 17 — skill-list line, same class.
- [`docs/overview.md`](../overview.md) line 61 — commit flow "gateway-inline stage + classify → …": the guard sits inside "stage"; confirm-unchanged expected.
- `CLAUDE.md:153` + `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md:153` — the parity pair "Only commit current session's changes — leave unrelated uncommitted work alone" states the law, not the mechanism, and is already correct: no edit. Both are harness, read-only inside doc-sync regardless.

### Test Strategy: e2e

The card's `Test-feel: manual` is superseded: [`skill-authoring`](../../.claude/rules/skill-authoring.md) sets a RED-first micro-test floor for behavior-shaping skill prose, and this behavior is mechanically observable. Fixture in the `bench/consult-hook/make-fixture.sh` shape — a scratch git repo with one foreign path already staged plus the session's own paths modified; arm runs the § 5 text, control runs no-guidance; assert on `git show --name-only HEAD` (foreign path absent) plus the surfaced stop. The control sweeping the foreign path in is the RED.
