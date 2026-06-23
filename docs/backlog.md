# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-001` · `DEBT-000` · `GAP-001` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### BUG-001 — drain subprocess status file (`tasks.md`) leaks onto the base branch at merge

**Logged:** 2026-06-22 · **Source:** live drain run in a consumer repo (Gibberish) — `--no-ff` merge of `drain/gap-015` carried the subprocess's worktree-root `tasks.md` onto `master`; the gateway had to `git rm` it in a follow-up commit to clean the base.
**Problem:** The status contract (`skills/drain/assets/phase-loop.md` § Status contract) has each subprocess **write and commit** `tasks.md` at the worktree root so the gateway reads it read-around via `git show {branch}:tasks.md` (the crash-survivable SSOT, per § Crash recovery). But the merge gate hands the *whole branch* to `/super-bootstrap:merge`, which merges every committed file — so the committed status file lands on the base branch. Root tension: read-around-via-`git show` **requires** the file be committed; merge **carries** committed files; nothing strips it between. Every drained item that reaches the merge gate leaks `tasks.md`, and the leak compounds across multiple drain merges. `tasks.md` is a common real filename, so it can't be blanket-gitignored in consumer repos. (A build-flavored escalation that never merges — e.g. `DONE_WITH_CONCERNS` torn down without merge — does not leak; only the success→merge path does.)
**Area:** `skills/drain/assets/phase-loop.md` (status contract — committed `tasks.md`), `skills/drain/SKILL.md` § Merge gate, `skills/merge/` (the merge lane), `skills/drain/assets/ensure-infra.md`
**Prior:** Fix must resolve the committed-vs-merged tension. Candidates: (a) drain strips the status artifact before handoff — commit a `git rm tasks.md` on the branch tip at the merge gate, then merge (smallest blast, keeps the committed-SSOT design, +1 removal commit per item); (b) `/super-bootstrap:merge` recognizes drain branches and `git rm`s the status file post-merge (couples the merge lane to drain's artifact name); (c) move status to a drain-reserved path the gateway reads via Bash `cat` / `git -C {worktree}` on the **live** worktree file instead of `git show` of a committed file — keeps it off every branch + gitignored, at the cost of the "committed = crash-survivable" property the skill chose deliberately. Lean (a).
