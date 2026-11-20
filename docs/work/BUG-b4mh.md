# BUG-b4mh — session-close prints a compaction caveat when no compaction happened: the skill names no detection signal

**Logged:** 2026-11-20 · **Source:** note from `claude-config-manager` (kind `tip`, created 2026-11-20T10:32:29Z), observed across several sessions there
**Problem:** `session-close` step 0 (`SKILL.md` line 35) and step 1 (line 54) tell the closer to flag a compaction blind spot "when the context was compacted", but name no signal for detecting compaction. Sessions infer it from ambiguous harness markers — e.g. a `tools-used-before-summary` system tag listing tools the session never saw itself call — and print the caveat in the close output when the user saw no compact. The tag's actual meaning is unverified.
**Area:** `plugins/super-bootstrap/skills/session-close/SKILL.md` (step 0, step 1)
**Prior:** Sender's suggested shape, unverified here: key the caveat on an observable signal — a platform compaction summary present in context; absent that signal, no caveat line.

## Verdict — surface · 2026-11-20

### Findings

- premise age: clean — `git log --since=2026-11-20 -- plugins/super-bootstrap/skills/session-close/SKILL.md` returns no commit.
- root cause, the part verified: `SKILL.md:35` ("say so beside the list when the context was compacted") and `SKILL.md:54` ("say so beside the items when the context was compacted") condition a line on a fact and name no observable for it. Step 0 names its evidence for jobs ("this session's own launch records and completion notices in context") and gives the compaction condition none. The repo holds no definition of an in-context compaction signal: the only compaction markers it records are out-of-context ones — the `compact_boundary` stream event and the `SessionStart compact` / `PostCompact` hook lines (`bench/carrier-equivalence/README.md:124-125`) — which a closing session cannot read. So the closer has to infer, and the wording gives the inference no floor.
- root cause, the part not isolated: whether the reported sessions were wrong. The symptom arrives as a note from another repo with no transcript; nothing here reproduces it. The string `tools-used-before-summary` appears nowhere in this repo except this card, and this lane has no evidence of what emits it. Two readings stay open and static reads cannot separate them:
  - (1) the tag is unrelated to context loss — the sessions printed a false caveat, as the card says;
  - (2) the tag marks a real context reduction the user does not see as a "compact" (a summary of earlier tool use standing in for the calls) — launch records can then be gone, the caveat was true, and the card's premise "no compaction happened" is wrong for those sessions.
- family: the two sentences are the whole family. No other skill, agent or rule under `plugins/` conditions behavior on compaction; `bench/session-close-*` holds no compaction scenario.
- adjacent, same sentences: step 0 says "beside the list" without saying what happens when the list is empty, and § Output's "these fields and nothing else" (`SKILL.md:116`) holds no caveat field — so a caveat in the final close output, where the card reports it, is outside the skill's text whichever reading holds. Any reword settles where the line may appear.
- scope reach: `plugins/super-bootstrap/skills/session-close/SKILL.md` lines 35 and 54 — this repo's own plugin source, no `.served` marker, no placed copy. Behavior-shaping prose, so the edit owes a RED under `.claude/rules/skill-authoring.md`; a new scenario beside `bench/session-close-inflight/` is its home. No doc under `docs/` restates the caveat (`docs/overview.md:43` mentions compaction in another sense) — Doc Impact reads as none.
- attempted: read the skill, its history (`59252a1` added the step 0 sentence, `07a37bd` the step 1 one — neither names a signal), every compaction mention in the repo, `docs/decisions.md` (no closed fork on this; row at line 100 is a different surface), open cards (no duplicate). `docs/techstack.md` has no `§ Probes` table, so no probe ran. Stopped at the fork above: the fix text depends on it.
- bias excluded: the card's `Prior:` (the sender's suggested shape) is carried below as option A, not as evidence.

### Decision needed

- Which condition gates the caveat line in steps 0 and 1? The answer depends on a measurement, not on preference: what a session's context holds after a compaction, and what `tools-used-before-summary` marks.
- options:
  - A — the line prints only when a platform compaction summary is present in context; no summary, no line. Fits reading (1). Under reading (2) it silences a real blind spot.
  - B — the line prints on the compaction summary or on the measured marker of reduced context (the tag, if the probe shows it marks dropped calls), each named in the skill text. Fits reading (2).
  - C — delete both sentences. Fits a third outcome: the probe shows a compacted session holds no dependable in-context marker, so no stated condition can be met.
- recommendation: A as the default shape — it gives the condition one named observable and the absent case a defined result — held until the probe rules out reading (2).
- settles by: a measurement, sized `phased build` — a headless bench that also becomes the RED. Arm 1: one `claude -p --input-format stream-json` process through `/compact` (the `compact` form `bench/carrier-equivalence/run.sh` already drives), then a turn asking the session to quote every marker of earlier context it holds. Arm 2: the same without `/compact`. A third input only the author holds: one transcript line from a `claude-config-manager` session showing the tag in place, which states what emitted it. The arms decide A against C; the transcript decides A against B.

## Amendment — 2026-11-20 · gateway session, first-hand observation

The tag appeared twice in the gateway session that dispatched this card's triage, in a session that was never compacted (it ran `/read-notes`, logged two cards, dispatched two background `triage` subagents; every turn since its start is in context whole).

- Sighting 1 — in the turn that delivered the `BUG-b4mh` triage subagent's final report, ahead of the report text, wrapped in a `system-reminder` block, verbatim: `<tools-used-before-summary>Edit, Glob</tools-used-before-summary>`. The gateway had called neither `Edit` nor `Glob` up to that point; its own calls were `Bash`, `Read`, `Grep`, `Write`, `Skill`, `AskUserQuestion`, `Agent`. Both names are in the `triage` agent's tool set (Read, Grep, Glob, Bash, Edit), and that agent appended this card's Verdict block.
- Sighting 2 — beside the same subagent's completion notification, verbatim: `<tools-used-before-summary>SubagentHandback</tools-used-before-summary>`. The notification states the report was delivered through the subagent's `SubagentHandback` call. The gateway has no such tool.

What this shows: in this session the tag arrived with a subagent's report, and the tools it lists are ones the subagent has and the gateway never called — no context of the gateway's own was summarized or dropped. What it does not show: what emits the tag, or whether it carries another meaning in a session that was compacted.

## Amendment — 2026-11-20 · probe `bench/session-close-compaction/`, 4 headless runs (sonnet)

Stream counts per run, read by the gateway from the raw streams (`compact_boundary` / the line `This session is being continued from a previous conversation` / `tools-used-before-summary`):

| Run | boundary | continuation line | tag |
|---|---|---|---|
| compact r1 | 1 | 1 | 1 |
| compact r2 | 1 | 1 | 1 |
| nocompact r1 | 0 | 0 | 0 |
| nocompact r2 | 0 | 0 | 0 |

In a compacted session the platform places a `user` message after the boundary that opens `This session is being continued from a previous conversation that ran out of context. The summary below covers the earlier portion of the conversation.`, then a `system-reminder` holding the `tools-used-before-summary` tag, then `Summary:`. So the tag sits inside the compaction summary there — and, per the Amendment above, also arrives with a subagent's report in a session that was never compacted. The tag alone does not separate the two cases; the continuation line does.

Not measured: whether a model reports the marker when asked. Three of four probe answers were stopped (`api_refusal_category: reasoning_extraction`) because the probe asked the session to quote its own context; the one answer that came back, `nocompact r1`, read `NO MARKER`.

## Design — 2026-11-20

Settled by the measurement above, on the gateway's climb — not a user ruling. Option A: steps 0 and 1 print the blind-spot line only when the session's context holds the platform's continuation summary — the message that opens "This session is being continued from a previous conversation" and carries a summary of the earlier portion. No such message → no line. A `tools-used-before-summary` tag on its own is not that signal. B is out: the tag also rides a subagent's report. C is out: a compacted session does hold a dependable in-context marker. The reword also states where the line appears (step 0 "beside the list" with an empty list; § Output's field set), per the Verdict's adjacent finding.

## Progress — 2026-11-20

RED not reproduced. `bench/session-close-compaction/` § RED ran the control (the skill text at HEAD, haiku, one fresh fixture per run, fixtures unchanged after every run):

| Scenario | Runs | Scorer |
|---|---|---|
| `tagonly` — never compacted, a `tools-used-before-summary` tag delivered with a subagent's report | 3 | `NO-CAVEAT` ×3; no output mentions compaction |
| `compacted` — the record opens with the platform's continuation message | 2 | `CAVEAT` ×2 |

On this fixture the committed wording already separates the two cases, so the Design's reword has no failing control to stand on and `SKILL.md` is unedited. Two limits on the reading: the session record is text embedded in a prompt, not a live context; and the arm is haiku, while the reported sessions ran in another repo on a model this card does not name. The scorer's bite check passed (a real `CAVEAT` output scored `NO-CAVEAT` once its caveat line was removed). Stopped here per the dispatch's fixed budget; next step is the author's call.

## Amendment — 2026-11-20 · gateway scan of the 55 `claude-config-manager` session transcripts on this device

A script read each transcript's main-thread assistant text for a sentence that names compaction or summarizing together with something lost or not showing, and counted the compaction markers per file. One real instance:

- Session `c5329e12-e700-4340-a863-09dea7b91261`: `compact_boundary` 0, continuation line 0, `tools-used-before-summary` lines 14. At 2026-11-20T08:07:26Z the model (`claude-opus-5-5`) wrote, verbatim: "不過這個 worker 的回報不在我目前的 context 裡（context 被摘要過），所以我手上沒有 bite check 的紀錄，也沒有 Lessons". The same session wrote the tip this card came from at 10:29Z.

What this shows: an uncompacted Opus session that held the tag stated its context had been summarized. The statement was made mid-work, not in a `session-close` output — the misreading is the model's reading of the tag, wider than the two skill sentences. What it does not show: a `session-close` output carrying the caveat; the scan's sentence pattern found none, and a caveat worded outside that pattern would be missed. The RED above ran on haiku; the instance is Opus.

## Amendment — 2026-11-20 · gateway scan of all 1383 Claude Code transcripts on this device

On the author's direction (precedents over re-runs: the behavior is not mechanical, so a re-run does not reproduce it dependably). A script walked every transcript in line order and kept each main-thread assistant sentence that claims the session's own context was compacted or summarized while no compaction record preceded it. Device totals: 32 transcripts hold a compaction record, 367 hold a `tools-used-before-summary` line.

Five sessions made the claim with no compaction. Each was cross-checked by count: `compact_boundary` 0, `isCompactSummary` 0, continuation text 0, `summary` records 0 — against a compacted transcript from the same device that reads 1 / 1 / 2. Every one of the five holds the tag and mentions `session-close`.

| Repo | Session | Model | Sentence, verbatim |
|---|---|---|---|
| ComfyUI workflows agent | `2c6e4c3d` | `claude-opus-5-5` | "**注意**：這個 session 的對話中途被壓縮過一次。" |
| claude-config-manager | `c5329e12` | `claude-opus-5-5` | "**注意**：這個 session 中途被摘要過一次。" — and one minute later: "那句「context 被摘要過」是我從一個線索推測出來的，證據不足，講得太篤定了。" |
| LanguageLearning | `204dc9e3` | `claude-opus-5-5` | "前面有一段對話被壓縮過，那一段如果有派出的工作，我這裡看不到紀錄。" |
| Podcast-jowagoko | `66863e0a` | `claude-opus-5-5` | "Detect 完成：沒有背景工作在跑（本 session 中段有壓縮過，壓縮前的啟動紀錄看不到）。" |
| super-bootstrap | `8c7c4e29` | `claude-fable-5-2` | "這個 session 的 context 壓縮過一次，壓縮前的啟動紀錄我看不到。" |

Four of the five sentences are the step 0 / step 1 blind-spot line in a close. These are the failing cases the Design's reword stands on: the committed wording, on Opus and Fable, in live sessions. Not computed: the rate — how many uncompacted closes held the tag and printed no caveat. The scan's sentence pattern is a heuristic; a caveat worded outside it is missed, so five is a floor.

## Progress — 2026-11-20

The reword is in the working tree, uncommitted: `SKILL.md` step 0 names the continuation summary as the one signal and states that the tag on its own is not it; step 1 points at step 0. Opus bench, 8 runs (`bench/session-close-compaction/README.md` § Findings (opus)): arm `tagonly` no caveat 3/3, arm `compacted` caveat 2/2, control `tagonly` no caveat 3/3 — so the bench shows the reword keeps the true case and does not show it removing the false one; the five live sessions above stay the only failing cases. Cold audit (`audit-harness-edits`): no critical or major; two findings applied in the report's own shape (step 1 gains "an empty set included"; "arrives with any subagent report" narrowed to what was observed), one rejected (step 1's output clause names a different attachment point than step 0's). Left for a later session to read: whether an uncompacted close that holds the tag still prints the caveat under the new text.

## Amendment — 2026-11-20 · trigger cause, grounded from the transcripts on the author's direction

What made the five sessions say they were compacted:

- First-person ground, one session of five. `c5329e12`, asked by the user, wrote: "**我依據的線索**：對話中途有幾次 system 訊息帶著一個標記：`tools-used-before-summary`。後面列出 Edit、TaskStop、ToolSearch、Glob、Monitor 這些工具，但我在看得到的對話裡找不到自己用過它們的紀錄。我因此推論有一段工具紀錄被壓縮掉了。" and "我沒看到任何摘要內容，也沒看到 `/compact` 的紀錄。" The other four state no ground; their transcripts hold no readable reasoning for the claim turn.
- What the tag rides, counted over every occurrence in the 375 transcripts that hold it (occurrences, not unique messages — request records repeat): about 1,590 sit directly ahead of a background-task `SYSTEM NOTIFICATION` or an "Another Claude session sent a message" hand-back; 89 sit inside a compaction summary. The tool it names most is `SubagentHandback` (1,128), then `Edit`, `Glob`, `Grep`, `Read`, `Write`.
- Where the claim was made: four of five in a close, at the step 0 / step 1 sentence; one (`c5329e12`, 08:07Z) mid-work with no close running.

Reading: two things meet. The platform tag has a name that says "before summary" and lists tools the session did not call; and the skill sentence asks "was the context compacted" with no named signal, so the closer looks for evidence and the tag is what it finds. The mid-work case shows the tag can produce the inference without the skill. The first-person ground is one session; for the other four the tag is the common factor, not a stated cause.

The author's direction on the fix, 2026-11-20: no line that fences off a specific misreading; either the caveat goes, or it prints only where the compaction signal exists. The reword in the working tree carries such a fence (the `tools-used-before-summary` clause) and is on hold.

## Progress — 2026-11-20

Final wording, on the author's go: step 0 names the platform's continuation summary as the signal — present → say so beside the list, absent → no blind-spot line — and step 1 points at step 0. No tag clause. Opus arm on this wording: `tagonly` no caveat 3/3, `compacted` caveat 2/2. Second cold audit: one major, applied in the report's own shape — the "empty list / empty set included" clauses are gone, since no output surface of the skill carries a line for an empty list (the pick's text is its rows; § Output's fields are closed); one nit accepted as-is (the anchor is a platform string; the bench's `run.sh` probe re-measures it). The empty-list case has no stated home for the line, as before this change.
