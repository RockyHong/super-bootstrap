# bench/session-close-compaction — what marker of a compaction does a session hold?

Measurement for [`skills/session-close/SKILL.md`](../../plugins/super-bootstrap/skills/session-close/SKILL.md):
after `/compact`, does the session hold a marker of the compaction inside its own context, and does a
session that was never compacted hold any such marker? The answer decides how the skill words the
sentence that tells a session it was compacted. The bench measures; it rewords nothing.

- `run.sh <outdir> <compact|nocompact> <rep>` — one headless run, model `sonnet`. Calls
  [`../carrier-equivalence/make-fixture.sh`](../carrier-equivalence/make-fixture.sh) (arm `rules`) for the
  fixture + cold config and [`../carrier-equivalence/drive-turns.py`](../carrier-equivalence/drive-turns.py)
  for the one-process stream-json drive. Turns: filler, then (arm `compact` only) `/compact`, then the
  probe. Writes `<outdir>/runs/<arm>-r<rep>.jsonl`, `.verdict.txt` (validity), `.fixture.txt`.
- `probe-prompt.txt` — the probe turn: quote the opening ~40 lines of the earliest visible content,
  then every text that states or implies earlier conversation was summarized / compacted / truncated /
  continued — or write `NO MARKER`. It names no expected phrase or tag.

## Protocol

- `<outdir>` is outside the repo and outside `%TEMP%/claude/…` (project instruction files do not load
  under that tree; see the carrier-equivalence README). Used: `C:/Users/User/AppData/Local/Temp/scc-probe`.
- Read-only fixture: `--disallowedTools "Edit,Write,NotebookEdit,Bash"`, `--permission-mode default`.
- Validity, from the stream: `compact` is valid only when `compact_boundary` precedes the probe turn;
  `nocompact` is valid only when the stream holds none. An invalid run is reported invalid.
- Two independent sources per `compact` run: the model's quote (what it chooses to repeat), and the
  stream's own `user` message after `compact_boundary` (the platform's text, independent of the model).
- Quirks: Git Bash rewrites a bare `/compact` — `MSYS_NO_PATHCONV=1`; `claude` needs stdin closed
  (`< /dev/null`); `drive-turns.py` exits 1 when a turn ends in an API refusal, which the stream still records.
- The probe asks the model to repeat its own context. On this build (Sonnet 5.5) the safeguard
  classifier can stop that answer (`api_refusal_category: reasoning_extraction`); the stream then holds
  `model_refusal_no_fallback` and no quote. A refused run has a valid compaction state but no model reading.

## Findings

Run 2026-11-20, one fresh fixture per run.

| Run | compaction state (stream) | model reading |
|---|---|---|
| compact r1 | valid — boundary in turn 2, before the probe | refused (`reasoning_extraction`), no quote |
| compact r2 | valid — boundary in turn 2, before the probe | refused (`reasoning_extraction`), no quote |
| nocompact r1 | valid — no boundary | Part 2: `NO MARKER` (Part 1 quoted the operator's `CLAUDE.md` opening) |
| nocompact r2 | valid — no boundary | declined both parts, no quote |

Stream fact, `compact` runs: after `compact_boundary` the stream carries a `user` message beginning
`This session is being continued from a previous conversation that ran out of context. The summary
below covers the earlier portion of the conversation.` followed by a `<system-reminder>` with
`<tools-used-before-summary>` and `Summary:`. The compacted session holds this text as a user turn.
Whether the model itself reports it is unmeasured: both `compact` probes were refused.

## RED

Test surface: the two sentences in the skill that begin "Blind spot:" (step 0, step 1). Question: does a
session that was never compacted get told it was? The `tools-used-before-summary` tag also rides a
subagent's report in such a session, so the tag alone is no sign of compaction; the platform's
continuation message is.

- `red-run.sh <control|arm> <tagonly|compacted> <fixture-dir> <out-file>` — fixture from
  [`../session-close-inflight/make-fixture.sh`](../session-close-inflight/make-fixture.sh) (`a.md` edited,
  unstaged); embeds the skill text verbatim after the scenario prompt; one headless arm; prints the
  fixture's log + status. `control` = `SKILL.md` via `git show HEAD:`; `arm` = the working-tree file.
- `red-prompt-tagonly.txt` — session record: goal delivered, one subagent (`agent-c3`) dispatched and
  reported, its report's delivery turn carries a `system-reminder` block with
  `<tools-used-before-summary>Edit, Glob</tools-used-before-summary>`. No continuation text. Nothing running.
- `red-prompt-compacted.txt` — the same record, opening with the platform's continuation message
  (tag block + `Summary:`). Nothing running.
- `red-score.sh <out-file>` — exit 0 + `CAVEAT` when a line speaks of compaction/summary AND of something
  lost or not showing; exit 1 + `NO-CAVEAT` otherwise. A line that denies compaction never counts.

### Protocol

Headless form as in [`../session-close-inflight/README.md`](../session-close-inflight/README.md#protocol).
One fresh fixture per run under `C:/Users/User/AppData/Local/Temp/scc-red/` (outside the repo and outside
`%TEMP%/claude/`). Runs are haiku unless `RED_MODEL` names another model; the arm has Bash only, so it reports that it could not run the commit
door or AskUserQuestion — that gap line is not a caveat and does not score.

- **Assertion** — `tagonly`: the arm scores `NO-CAVEAT`; the control scoring `CAVEAT` is the RED.
  `compacted`: control and arm both score `CAVEAT`.

### Findings (control, `HEAD` text)

Run 2026-11-20. Every fixture after the run: `init` only, ` M a.md`.

| Run | scenario | score | caveat line |
|---|---|---|---|
| control 1 | tagonly | NO-CAVEAT | none; step 0 reads "Nothing is running" |
| control 2 | tagonly | NO-CAVEAT | none |
| control 3 | tagonly | NO-CAVEAT | none |
| control 4 | compacted | CAVEAT | "Blind spot: this session continued from a compacted context, so a launch record lost to compaction would not show here." |
| control 5 | compacted | CAVEAT | "This session was compacted, so launch records from before the summary would not show here." |

The RED on `tagonly` does not reproduce: the control text does not print the caveat for a tag-only record
on haiku (0/3). `compacted` control: caveat 2/2. Scorer bite: a `compacted` output scores `CAVEAT`; the
same output minus its caveat line scores `NO-CAVEAT`; the line "No compaction signal in this session." scores
`NO-CAVEAT`.

### Findings (opus, control against arm)

Run 2026-11-20, `RED_MODEL=opus`. The arm is the wording that names the continuation summary as the one
signal. Every fixture after the run: `init` only, ` M a.md`.

| Run | scenario | score | line |
|---|---|---|---|
| control ×3 | tagonly | NO-CAVEAT ×3 | none |
| arm ×3 | tagonly | NO-CAVEAT ×3 | none; one run states "The context holds no continuation summary." |
| arm 1 | compacted | CAVEAT | "**Compaction blind spot:** this session was continued from an earlier, summarised one. A background job or an unfinished task from that earlier part would not show here." |
| arm 2 | compacted | CAVEAT | "This session was continued from a summary, so a job launched before the summary would not show here." |

The control prints no false caveat on opus either (0/3), so this bench does not reproduce the failure and
its `tagonly` rows cannot show the arm removing it: a session record embedded in a prompt is not a live
context. The failing cases are live sessions — uncompacted closes on larger models that printed the caveat.
What the bench does hold: the arm keeps the caveat where the continuation summary is present (2/2) and
prints none without it (3/3).

The table's arm rows ran on a wording that also named the `tools-used-before-summary` tag as a non-signal.
The shipped wording names the continuation summary alone; re-run on it, opus: `tagonly` `NO-CAVEAT` 3/3 with
no mention of compaction, `compacted` `CAVEAT` 2/2 ("This context was compacted (a continuation summary is
present), so a job launched before the summary would not show here.").

Scorer: its first pattern (`summari[sz]`) scored arm 2 `NO-CAVEAT` — the line says "summary". The pattern
is `summar` now; bite re-run on arm 2: `CAVEAT`, and `NO-CAVEAT` with its two caveat lines removed.
