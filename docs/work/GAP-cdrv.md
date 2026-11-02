# GAP-cdrv — session-close lets judgment leak past the close instead of settling it inside

**Logged:** 2026-11-03 · **Source:** device note from `magnetized-remake` (2026-10-30, super-bootstrap 5.7.0); surfaces checked against the current skill at capture
**Problem:** `/super-bootstrap:session-close` let decisions leak past the close, so the user got questions after "done". Two scenes:
1. Step 3's inflight-findings triage routed two findings to **log** moves although both could finish in-session: a doc edit in that repo, and a cross-repo note. User: "為什麼不現在做完?". The triage axes were met, "far afield" was read loosely, and the default fell to deferral. Surface: `session-close/SKILL.md:63-65`.
2. The close's commit ran through `/super-bootstrap:commit`, whose cold doc-sync scan returned a `register` proposal. Session-close has no step for it, so it surfaced after the close output, with the gateway's own recommendation ("skip") attached. User: "既然建議不登記那又說幹嘛? 有earn right就記，沒有就不要在那邊硬擠話要說". The finding did earn its keep (one artifact, five names), and the right outcome was to do it. Surface: `session-close/SKILL.md:81`, where the commit runs after the pick.

Note's asks:
- Step 3 biases inflight findings to **fix-now** whenever the work is this repo's and bounded; a log move states why it cannot finish now (closure, context, ownership).
- Run the commit door's doc-sync before building the pick, or fold its returns (register / terminology / restatements) into the pick, so the close asks nothing after the close.
- A surfaced item carries an action the model will take or a genuine fork, never "I recommend skipping, do you want to?". No earn-right → silent drop; earn-right → a move.

Related: BUG-dd1h edits the same line, `session-close/SKILL.md:65`.
**Area:** `plugins/super-bootstrap/skills/session-close/SKILL.md` step 3 and the pick / execute order; `plugins/super-bootstrap/skills/commit/SKILL.md` §4 returns
**Prior:** The pick is built before the commit door runs, so the door's judgment returns have no slot inside the close.
