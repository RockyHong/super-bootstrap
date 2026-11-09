# bench/doc-sync-harness-cochange — a same-change harness co-edit lands this round

Test surface for the harness row of [`skills/commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) §4,
the `harness` output class of [`agents/doc-sync-scan.md`](../../plugins/super-bootstrap/agents/doc-sync-scan.md), and the
§ Doc Sync Write boundary of [`claude-md-skeleton.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md).
A criterion change leaves this repo's own skill narrating the old criterion. The gateway lands that skill edit this round,
through the audit the harness requires, in one list with the stale docs, and asks once. A served skill still routes to its
owner. Behavior-shaping prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor.

## Fixture

- `fixture/base/` — the `kettle` podcast repo. `docs/criteria.md` § Tagging standard says 5 seconds; `docs/workflow.md`
  links it and restates 5 seconds; `docs/overview.md` links it with no number. `.claude/skills/ep-prep/SKILL.md` (the repo's
  own skill) and `.claude/skills/clip-cut/SKILL.md` (a `.served` marker in its directory) each restate 5 seconds.
- `fixture/session/docs/criteria.md` — the session's edit: 10 seconds and a host names it aloud.
- `make-fixture.sh <dir> <plugin-root>` — builds the repo with plumbing; the root's `claude-md-skeleton.md` becomes the
  fixture's `CLAUDE.md`, so the consumer's Write boundary is the copy under test.
- `prompt.txt` — the session record: the change, the file list, the session reads (both skills). The run is a dry stage that
  stops at the door's first doc-sync message.
- `run.sh <control|arm> <dir>` — one headless walk, then `score.sh`.
- `score.sh <out> [<dir>]` — (a0)–(a4).
- `bite.sh <scratch-dir>` — each assertion failing on a violating output. Zero LLM calls.

## Protocol

Headless `claude -p --model sonnet --allowedTools Bash,Read,Grep,Glob --setting-sources project,local --permission-prompts none`,
fixture as cwd, prompt on stdin, the commit skill and the agent body embedded verbatim. Put fixture directories outside this
repo. The copy under test is this repo's dev copy. The scope is 3 docs, so the door takes its warm lane.

- **Control** — the three files at `5c5c165`, exported beside the fixture.
- **Arm** — the working-tree copies.

Assertions:

- **(a0)** the fixture is as built: only ` M docs/criteria.md`.
- **(a1)** the `ep-prep` item names a landing this round and an audit or verify pass, read on the run's own route (below).
- **(a2)** the `ep-prep` item carries no deferral on the run's own route: no route to owner, flag-only, separate edit, follow-up, log a card.
- **(a3)** `docs/workflow.md` is in the same message, and the message holds at most one question (prose `?` lines plus
  AskUserQuestion `question` keys).
- **(a4)** `clip-cut`, when named, routes to its owner (owner, served, upstream, `/contribute`).

An item is its line, its indented continuation and the nearest heading or label line above it. (a1) and (a2) read the run's own
route: prose rows, plus the recommended option of each AskUserQuestion question (the option whose label holds `recommend`, any case;
none labelled, the first option). The options the run only offers do not count, in pretty or compact one-line JSON alike.

Pass condition, named before any run, three walks each: RED = control fails (a1), (a2) or (a3) on 2 of 3. GREEN = arm passes
(a0)–(a4) on 3 of 3. At most 3 wording passes after RED.

## Findings

Three walks per row, sonnet. The walk outputs are not kept, so rows were scored as follows: every row with the scorer as it stood
before the recommended-option scoping, which came last. That scoping only removes lines from (a1) and (a2) input of an offered
option, so a pass stays a pass in (a2); an earlier (a2) FAIL could flip to PASS, and an (a1) PASS on an offered option's "now" could
flip to FAIL. The RED verdict stands on (a3) 0 of 3 and (a1) 1 of 3, neither of which the scoping can raise. Scorer changes after
the first control reading:
(a2) catches the deferral phrasings control used ("route to their owners", "flagged only", "separate harness edit"),
leaves out lines that also name the served skill, keeps only the `ep-prep` clauses of a line that names a numbered row,
and continuation stops inside a fenced block; (a1) matches `now` and `land` as whole words; (a1) and (a2) score the recommended option of an ask, not the alternatives.

| Round | Text | (a1) | (a2) | (a3) | (a0), (a4) |
|---|---|---|---|---|---|
| RED | control `5c5c165` | 1 of 3 | 0 of 3 | 0 of 3 | 3 of 3 |
| 0 | harness class, §4 harness row, Write boundary | 3 of 3 | 3 of 3 | 0 of 3 | 3 of 3 |
| 1 | + the list takes one ask | 3 of 3 | 3 of 3 | 2 of 3 | 3 of 3 |
| 1, repeat | same text | 3 of 3 | 3 of 3 | 2 of 3 | 3 of 3 |
| 2 | + card and pick rows join the list | 3 of 3 | 3 of 3 | 0 of 3 | 3 of 3 |
| 3 | + the restatement and terminology rows are list rows | 3 of 3 | 3 of 3 | 3 of 3 | 3 of 3 |

Every (a3) miss after round 0 is a second question offering a restatement card. Round 3 is GREEN.
