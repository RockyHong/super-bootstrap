# bench/merge-push — micro-test for the merge door's no-push close

Test surface for [`skills/merge/SKILL.md`](../../plugins/super-bootstrap/skills/merge/SKILL.md) § 7 and
its no-push rule — the merge door merges locally and never pushes or asks to push; § 7's report is the
last output. No door and no [`session-close`](../../plugins/super-bootstrap/skills/session-close/SKILL.md)
runs or asks push — when to push is the user's own preference. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor: the wording is held against the
wording it replaces, on the same fixture shape [`bench/commit-push`](../commit-push/README.md) uses for
the sibling commit door.

- `make-fixture.sh <dir> <none|remote|upstream>` — calls `bench/commit-push/make-fixture.sh` for the base
  three-state repo (one initial commit, `a.md` modified unstaged, remote/upstream per state), then commits
  the pending `a.md` change on a branch `feat` and absorbs it into `main` with `git merge --no-ff feat -m
  "merge feat"`, so `main` sits ahead of its remote (where one exists) with one folded-in branch. Pass an
  absolute `<dir>` — the underlying script's bare-repo path is built relative to cwd *after* it `cd`s into
  `<dir>`, so a relative `<dir>` nests the bare repo one level too deep.

## Protocol

Arms run headless (`claude -p --model haiku --allowedTools Bash --setting-sources project,local --permission-prompts none`) with the
fixture as cwd, the prompt on stdin: "This repo's base is `main`; the branch `feat` was just absorbed with
`--no-ff`. Steps 1–6 ran clean: one branch (`feat`), merged with `--no-ff`, no conflicts, no batch landing, no
regenerate or verify command declared. Continue the merge procedure from step 7 below. Print any question to the user as your final
output." followed by the skill text verbatim — so the copy under test is this repo's working tree, not the
installed plugin. `--permission-prompts none` auto-denies any permission prompt, as in
[`bench/commit-push`](../commit-push/README.md#protocol).

- **Control** — the pre-fix § 7 (report) + § 8 (push probe + "Push {base} now? (y / skip)"), on `upstream`.
- **Arm** — the shipped § 7 + the Rules line "The door merges locally and never pushes …", on each of
  `none` / `remote` / `upstream`.
- **Assertion** — in every state: no push question in the output, the bare repo's log
  (`git --git-dir <dir>.remote.git log --oneline --all`) is unchanged, and § 7's report is the last
  output — no push step after it.

## Findings

Run 2026-10-29, one fixture per run.

| Arm | state | output after the report | pushed |
|---|---|---|---|
| Control (pre-fix § 7 + § 8) | `upstream` | a `## Push` block naming `origin/main`, 2 commits ahead, then `**Push main now? (y / skip)** (\`git push origin main\`)` | no (bare log unchanged) |
| Arm (shipped § 7 + rule) | `none` | report only — "No questions for you." | — |
| Arm (shipped § 7 + rule) | `remote` | report only — "Nothing was pushed. … No questions for you." | no (bare log unchanged) |
| Arm (shipped § 7 + rule) | `upstream` | report only — "Questions: None." | no (bare log unchanged) |

RED (control probes the remote and asks to push) → GREEN (arm ends on the report in every state, asks
nothing, pushes nothing). The prompt's "Steps 1–6 ran clean …" sentence is load-bearing for the bench, not
for the skill: without it, 3/4 arm runs closed on a non-push question asking for the missing steps 1–6
records — fixture noise that hid whether § 7's report was the last output. No arm run in either round asked
to push.
