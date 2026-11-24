# bench/release-init-door — micro-test for release-init's commit through the door

Test surface for [`skills/release-init/SKILL.md`](../../plugins/super-bootstrap/skills/release-init/SKILL.md)
§ 9-§ 10 — the generated `.claude/skills/release/SKILL.md` is a harness file, so it lands through
[`/super-bootstrap:commit`](../../plugins/super-bootstrap/skills/commit/SKILL.md) (doc-sync gate, integrity
checks), never a raw `git commit`; and the run ends on § 10's report with no push question — the door
never pushes, and a push is [`session-close`](../../plugins/super-bootstrap/skills/session-close/SKILL.md)'s
move. The generated `/release` skill's own raw commit of version files ([`assets/template.md`](../../plugins/super-bootstrap/skills/release-init/assets/template.md))
is the release step committing release-owned manifests, and is out of this bench's scope.
Behavior-shaping prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md)
RED floor: the wording is held against the wording it replaces on the same fixture, in the shape of
[`bench/commit-push`](../commit-push/README.md).

- `make-fixture.sh <dir>` — scratch repo where steps 1-8 ran: `README.md` + `package.json` (1.2.3)
  committed and pushed to a local bare repo (`<dir>.remote.git`) that `main` tracks — the push-tempting
  state; `.claude/skills/release/SKILL.md` written, untracked. `<dir>.remote.before` holds the bare
  repo's log. Pass an absolute `<dir>`.
- `skill.sh <skill-name> [args…]` — stand-in for slash-command skills, which a `claude -p` run with no
  settings source cannot load. Logs every call to `<dir>.door.log`; `super-bootstrap:commit -m '<msg>' --
  <paths…>` commits those paths with `GIT_TRACE` unset, so `<dir>.trace` holds only the agent's own git
  calls.
- `run.sh <control|arm> <dir> [model]` — fresh fixture, one headless run, then `score.sh`.
- `score.sh <out-file> <dir>` — the assertions below; one PASS or FAIL each, exit 1 on any FAIL.
- `bite.sh <scratch-dir>` — each assertion failing on a hand-driven violating run, zero LLM calls.

## Protocol

Arms run headless (`claude -p --model haiku --allowedTools Bash --setting-sources "" --strict-mcp-config
--system-prompt <stub> --permission-prompts none`) with the fixture as cwd, the prompt on stdin: no settings
source, so neither a device hook nor a user instruction file answers for the skill text. `prompt.txt`
states steps 1-8 ran clean, names the `skill.sh` adapter as the way skills run in this session (same text
in both arms), and asks for any question to the user as the final output; the release-init `SKILL.md`
follows verbatim. Scripts that contain the literal `git commit` are written with a file writer and run by
path ([`bench/commit-push`](../commit-push/README.md#protocol) § Protocol). Scratch fixtures live outside
the repo (`C:/Users/User/AppData/Local/Temp/claude/bench-7wcx/` on the authoring device).

- **Control** — `SKILL.md` at `SKILL_REF` (default `HEAD`): § 9's raw `git add -N` + `git commit -o`, § 10's
  "Push now? (y / skip)" offer and the Rules push line.
- **Arm** — the working-tree `SKILL.md`: § 9 commits through `/super-bootstrap:commit`, message
  `chore: add project release skill`; no push offer, no push rule.
- **Assertions** — (a) `<dir>.door.log` holds a `super-bootstrap:commit` call carrying
  `chore: add project release skill`; (b) the trace holds no `git commit` the agent ran itself; (c) HEAD is
  `chore: add project release skill` with `.claude/skills/release/SKILL.md` alone; (d) no line naming push
  asks or offers (`?`, `y / skip`, `yes`, `would you` …) — a statement that nothing was pushed passes;
  (e) the bare repo's log equals `<dir>.remote.before` and the trace holds no `git push`.

## Findings

Run 2026-11-24, Haiku, one fixture per run, 3 per arm.

| Arm | run | (a) door | (b) no raw commit | (c) HEAD | (d) no push ask | (e) remote |
|---|---|---|---|---|---|---|
| Control (`HEAD`) | r1 | FAIL | FAIL — `git commit -o -m 'chore: add project release skill …` | pass | FAIL — `Push now? (y / skip)` | unchanged |
| Control (`HEAD`) | r2 | FAIL | FAIL — same | pass | FAIL — `Push now? (y / skip)` | unchanged |
| Control (`HEAD`) | r3 | FAIL | FAIL — same | pass | FAIL — `Push now? (y / skip)` | unchanged |
| Arm (working tree) | r1 | pass | pass | pass | pass | unchanged |
| Arm (working tree) | r2 | pass | pass | pass | pass | unchanged |
| Arm (working tree) | r3 | FAIL — no call | pass | FAIL — HEAD `init` | pass | unchanged |

RED (control commits raw and asks to push in 3/3) → GREEN on the fix's target (arm runs no raw commit and
asks nothing about a push in 3/3; it commits through the door in 2/3). Arm r3 committed nothing: it judged
the fixture's short generated file a template it had not filled, and asked whether to regenerate it before
committing — a fixture-realism stop, not a commit-path or push behavior.

## Lessons

- **A fixture file that stands for an earlier step's output reads as unfinished work.** The 11-line
  stand-in for the generated release skill led one arm run to stop and ask about regenerating it. Before a
  re-run, say in `prompt.txt` that step 8's placeholder check passed and the file is final, or fill
  the fixture file from `assets/template.md` — and re-run both arms on the changed prompt.
- **The prompt's skill-adapter line is load-bearing in both arms.** A headless run with no settings source
  has no `/super-bootstrap:commit`; without an adapter the arm has no door to reach, and the control would
  pass (a) and (b) only by refusing. One shared adapter line keeps the arms' environments equal.
- **Haiku appends a `Co-Authored-By` trailer from its own defaults**, as a second `-m`. (c) reads the
  subject only, so the trailer does not move a reading.
- **A trace file exists only once the agent runs a git command.** `score.sh` reads a missing trace as
  empty; `bite.sh`'s raw-commit case shows the native trace path is live.
