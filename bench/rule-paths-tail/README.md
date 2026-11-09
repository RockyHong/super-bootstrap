# bench/rule-paths-tail — micro-test for the placed doc rules' consumer `paths:` tail

Test surface for [`harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
§ Pipeline-owned / § Project-owned (the two doc rules' drift scope), § 2b Per-doc handling (the
drifted-section bullet) and Phase 3 § Doc-rule coverage. Behavior-shaping prose, so it ships behind
the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. The coverage check
itself is mechanical and pinned by [`tests/rule-paths-coverage.test.sh`](../../tests/rule-paths-coverage.test.sh).

Two axes, one prompt:

- **Tail kept** — a re-run meets a placed `.claude/rules/ssot-doc-link.md` whose `paths:` carries
  the skeleton's three entries plus a consumer entry `kinds/**/*.md`; everything else is
  byte-identical to the asset. Does the drift check read the file `✓ current` and keep the entry?
- **Coverage command** — `.claude/doc-surface` declares `kinds/*.md` and `guides/*.md`. Does the
  step text have the run call the coverage check?

## Protocol

`run.sh <control|arm> <out-file> <neutral-cwd>` lifts the excerpts verbatim from SKILL.md (control:
`e34057d`, pre-change; arm: the working tree), fills [`prompt.txt`](prompt.txt), and runs
`claude -p --model "${MODEL:-haiku}" --tools "" --setting-sources project,local --permission-prompts none`
in a neutral directory outside this repo, so the agent cannot read the answer off `CLAUDE.md` or the
commit log. The excerpt set differs between arms only by the changed and added clauses. Three trials
per arm per model (Haiku, Sonnet). Score by hand from the four answer lines:
RED = control `STATUS: DRIFTED` or `kinds/**/*.md` missing from `PATHS_AFTER`;
GREEN = arm `STATUS: CURRENT`, `REMOVED: NONE`, `kinds/**/*.md` kept, `COMMAND` names
`rule-paths-coverage.sh check`.

Prompt calibration: a first draft said the two bodies were byte-identical "below the frontmatter".
Haiku then read "whole shipped bodies" as the part below the frontmatter, and the control kept the
tail 5 of 5 trials. The shipped prompt says the files are byte-identical apart from the lines shown.

## Findings

Run 2026-11-09, Windows 11, Git Bash, CC 2.1.319.

| Arm | Model | Trial | STATUS | REMOVED | tail kept | COMMAND |
|---|---|---|---|---|---|---|
| control | haiku | 1 | DRIFTED | NONE | yes | NONE |
| control | haiku | 2 | DRIFTED | `kinds/**/*.md` | no | NONE |
| control | haiku | 3 | DRIFTED | `kinds/**/*.md` | no | NONE |
| control | sonnet | 1–3 | DRIFTED | `kinds/**/*.md` | no | NONE |
| arm | haiku | 1–3 | CURRENT | NONE | yes | `bash ${CLAUDE_PLUGIN_ROOT}/skills/harness-bootstrap/assets/rule-paths-coverage.sh check` |
| arm | sonnet | 1–3 | CURRENT | NONE | yes | same |

RED: 6 of 6 control trials flag the file drifted, and 5 of 6 revert the consumer entry. No control
trial names a coverage command. GREEN: 6 of 6 arm trials read the file current, keep the entry and
name the command, on the first wording round.

Not measured: the interleaved-entry clause (a consumer entry among the skeleton's entries is drift).

The § Pipeline-owned bullet's own clause ("`paths:` entries after the skeleton's last one are consumer-owned") is load-bearing: cut down to a pointer at § Project-owned, haiku reverted the entry in 1 of 3 arm trials; restored, 6 of 6 haiku trials keep it.
