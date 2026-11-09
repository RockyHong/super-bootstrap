# BUG-arw5 — commit door's fixed session-close handoff line interrupts work still in flight

**Logged:** 2026-11-09 · **Source:** device note from `rockyhong__jowagoko` (D:/Git/Podcast/jowagoko), 2026-11-09
**Problem:** Commit §6 Handoff makes "the next and only output after the commit" the fixed line `Committed. When the session's work is done: /super-bootstrap:session-close (card resolve, carry).` It prints on every commit, whatever the work state. Under commit-in-flow it fires mid-work: a multi-step or multi-session worker reads it as a wrap-up signal and stops, and "only output" stops the reply from reporting progress on the ongoing work. Instance: jowagoko EP75 edit pipeline, step 1 (ASR) running in the background, a one-line `docs/techstack.md` commit — the reply shrank to the handoff line. User quote: 「這個提醒很煩，明明工作剛開始，提醒這個只會讓 multi session worker 被斷」. The session-close-invoked path already skips the line.
**Area:** `plugins/super-bootstrap/skills/commit/SKILL.md` §6 Handoff (line 66)
**Prior:** Sender's shapes, preference order: (a) drop the fixed line — report the commit and continue the work; (b) name session-close only when the session looks finished (no background work, no in-flight card step, no pending pipeline step); (c) at least drop "only output", so the line cannot replace the progress report.

## Verdict — auto-fix · 2026-11-09

**Fix-shape:** prompt
**Probe-deps:** none
**Execution:** full — depth: behavior-shaping skill prose whose effect on a consuming agent is non-deterministic, so it ships behind the `skill-authoring` RED floor (headless bench arms); closure: one skill step plus four narrating sites (session-close Output line, plugin README row, the commit-push bench, a test-queue line), all in this repo's own plugin source.

### Repro (pinned)

"Commit §6 Handoff makes "the next and only output after the commit" the fixed line `Committed. When the session's work is done: /super-bootstrap:session-close (card resolve, carry).` It prints on every commit, whatever the work state."

"Instance: jowagoko EP75 edit pipeline, step 1 (ASR) running in the background, a one-line `docs/techstack.md` commit — the reply shrank to the handoff line."

### Root cause (verified)

- premise age: 1 commit touched the named surface after the observation — `16616ce` (2026-11-09 12:07, "land same-change harness edits in one pick…"). Its diff to `commit/SKILL.md` carries no `Handoff` / `only output` hunk, so §6 is untouched; the card was logged after it (`960c046`, 12:20). Premise stands against current code.
- `plugins/super-bootstrap/skills/commit/SKILL.md:66` — §6 reads verbatim: "the next and only output after the commit is this one line: `Committed. When the session's work is done: /super-bootstrap:session-close (card resolve, carry).` Skipped when invoked by `/super-bootstrap:session-close`". Two defects in one sentence: (1) "next and only output" is an exclusivity claim with no work-state condition, so an obeying gateway emits nothing else after a mid-work commit — the progress report on the still-running step is suppressed; (2) the only carve-out is the session-close caller, so every other invocation — the commit-in-flow commits CLAUDE.md § Envelope mandates ("commit at each verified unit") — ends on a session-wrap-up pointer. The symptom (reply shrinks to the handoff line, worker reads it as a stop) follows directly from obeying the text.
- Provenance of the defect: `ea3e4b1` (resolve GAP-0asv) collapsed the old three-row §7 "Cycle handoff" table (which already said "Cycle complete …") into this one unconditional line; the "only output" wording carried over from the removed push step ("§7's handoff line is the next and only output"), where it ended the commit door's own flow, not the session's.
- Family sweep: the same exclusivity bites every skill that calls the door as a sub-step and then continues — `setup/SKILL.md:61` ("land the new `docs/work/{ID}.md` files through `/super-bootstrap:commit` … before the gate renders"), `setup/SKILL.md:43`, `resolve-plugins/SKILL.md:260`, `autorun/SKILL.md:86`, `autorun/assets/ensure-infra.md:71`. "Only output" tells the gateway to stop at the commit, when the caller's next step still has to run. The fix covers the whole family at the one source line; no caller needs its own edit. The sibling door `merge/SKILL.md:151` ("§7's report is the last output") ends on the door's own report, with no session-close pointer — it is the model shape, not a family member.
- Option settle (no user judgment left): the card's Source is the user's own device note, which ranks its shapes "(a) drop the fixed line — report the commit and continue the work" first, and the user quote rejects the line outright. (c) alone fails the aim — the line would still print mid-work and still read as a wrap-up cue. (b) needs a "session looks finished" predicate the door cannot observe (the gateway's remaining plan is not on disk); finish detection is already `session-close`'s job (its still-running gate and undelivered-goal check, `session-close/SKILL.md` step 1 / line ~100). So (a) fits: §6 becomes the door's own one-line commit report (sha + subject, plus any acknowledged integrity break), then control returns to the work in progress or the calling skill's next step. No session-close pointer, no exclusivity claim. The session-close-invoked skip stays, since that path prints session-close's own Output.

### Files (fix surface)

- `plugins/super-bootstrap/skills/commit/SKILL.md:66` — rewrite §6 per (a): report the commit, then return to the ongoing work or the caller's next step; drop "next and only output" and the session-close line; keep the session-close carve-out.
- `plugins/super-bootstrap/skills/session-close/SKILL.md:104` — "the commit door's handoff line does not print under session-close" narrates the line being removed; reword so it names the door's commit report (or drop the clause) to match §6.
- `plugins/super-bootstrap/README.md:63` — the `commit` row ends "its handoff line points to `session-close`"; it is stale after the fix. Drop or restate the clause (the push clause before it stays true).
- `bench/commit-push/README.md` — the RED/GREEN surface for §6. Its assertion (line 34: "the output after the commit is § 6's one handoff line") and its Findings arms pin the behavior being removed. Re-aim it: add a fixture prompt with work still in flight (e.g. a remaining step the prompt names), Control = the current §6 text (expect the reply to collapse to the handoff line = RED), Arm = the new §6 (expect a commit report followed by continuation / progress, with no session-close line and no push). Keep the no-push assertion. Runs headless per its § Protocol (`claude -p --model haiku …`, fixture as cwd).
- Provenance: every path above is this repo's own plugin source / bench. No `.served` marker or sidecar applies, so there is no foreign route.
- Ship: a skill-body change. The plugin version bump and marketplace sync go through `/release` after commit (not part of this fix's diff).

### Doc Impact

- `docs/test-queue.md:38` — "the commit lands through `/super-bootstrap:commit` with no session-close reminder line" stays true after the fix, though now trivially. Confirm unchanged, or drop the clause at doc-sync.
- `docs/overview.md:62` (Session boundary), root `README.md:89` (session-close row), `merge/SKILL.md:151` — read; none narrates the commit door's handoff line. They are confirmed unchanged.
- `docs/decisions.md` — no closed fork on the commit handoff line, so the fix re-walks nothing. No open card overlaps (grep of `docs/work/` for handoff / session-close: only this card).

### Test Strategy: e2e

The headless bench arm `bench/commit-push` (re-aimed as above) gives a failing control on the current §6 and a passing arm on the new text. It needs no human eyeball: the assertion reads the run's output after the commit for the session-close line and for continuation text, and reads the bare-repo log for no push.
