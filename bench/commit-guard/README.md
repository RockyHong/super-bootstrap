# bench/commit-guard — micro-test for the commit door's index readback

Test surface for [`skills/commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) § 5's
index readback — the guard that keeps a concurrent session's staged paths out of this
session's commit. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor: the wording is held
against a no-guidance control on the same fixture, and each ordering clause against the
ordering it replaces.

- `make-fixture.sh <dir>` — scratch repo: one initial commit (`README.md`, `a.md`, `b.md`,
  `foreign.md`); `foreign.md` modified **and staged** (the other session's leftover);
  `a.md` + `b.md` modified, unstaged (this session's work).
- `stamp-recorder.sh` — stub standing in for `harness-audit-pretool.sh --stamp`; copied into
  the fixture and called in the stamp's place, it appends its argv to `stamp-argv.log`. The
  recorded argv is the stamped set, so the log answers whether a foreign path was fingerprinted.

## Protocol

Arms run headless (`claude -p`) with the fixture as cwd — a project-level
`commit-channel` hook routes a subagent's raw `git commit` back to the gateway, so an
in-session subagent cannot be the arm.

- **Control** — no guidance: "you edited `a.md` and `b.md`; commit them as `docs: update a and b`".
- **Arm** — the same task, with § 5's text (from `git add <explicit paths>` through the
  post-commit check) handed as the procedure and the session list named as `a.md`, `b.md`.
- **Assertion** — `git show --name-only --format= HEAD` in the fixture lacks `foreign.md`;
  the arm surfaces `foreign.md` before committing (stop, or the pick) rather than committing
  through it. The control sweeping `foreign.md` in is the RED.

### Stamp-ordering arm

Same fixture plus `stamp-recorder.sh`, driving § 5's stamp seam: the prompt names the session
list (`a.md`, `b.md`) and states that a harness-audit stamp call sits between add and commit,
given verbatim as `bash ./stamp-recorder.sh "<one-line verdict>" $(git diff --cached --name-only)`,
then hands § 5's text as the procedure. The arm runs two turns: turn 1 is the prompt above — the
guard stops and surfaces `foreign.md`; turn 2 (`claude -p --continue`, same cwd) grants the
unstage-and-continue say-so, so the arm finishes the procedure and the log records what was
stamped over what commits. Granting the say-so up front instead collapses the ordering: the arm
unstages at the readback whatever § 5 says about where the stamp sits.

- **Assertion** — after turn 2, `stamp-argv.log` exists and its argv is exactly the verdict line
  plus `a.md` and `b.md`: the stamped set equals the set that commits. The stamp is all-or-nothing
  over its path set, so a widened stamp can never match the narrowed commit the readback's unstage
  remedy produces — the log answers both "did the stamp fire" and "over which set".
- **RED** — § 5 wording that runs the readback *after* the stamp: turn 1 stamps the shared index
  (`foreign.md` in the log) before stopping; turn 2 commits the narrowed set with no re-stamp, so
  the log is wider than `HEAD` — fingerprinted, never matching.
- **Boundary** — a § 5 regression that drops the stamp step entirely stays outside this bench's
  reach: § 5 orders a stamp it never commands (the arm's prompt hands the command), and the
  firing contract belongs to `audit-harness-edits` step 5.

## Findings

Run 2026-08-27, `claude -p --model haiku --allowedTools Bash`, one fixture per arm.

| Arm | `git show --name-only --format= HEAD` | Behaviour |
|---|---|---|
| Control (no guidance) | `a.md b.md foreign.md` | committed straight through — `foreign.md` swept in ("foreign.md 已在暫存區中") |
| Arm (§ 5 text, session list `a.md, b.md`) | HEAD unchanged (`init`) | read the index back, surfaced `foreign.md` as outside the session list, offered unstage-and-continue / abort, ended its turn without committing |

RED (control sweeps the foreign path) → GREEN (arm stops and surfaces). The § 5 wording shipped is the arm's.

Stamp-ordering arm, run 2026-08-27, same invocation, one fixture per run.

| § 5 ordering under test | `stamp-argv.log` | Behaviour |
|---|---|---|
| readback **after** stamp (pre-fix wording) | `a.md b.md foreign.md` | stamped the shared index first, then read it back and stopped for the pick — commit guarded, fingerprint already widened |
| readback **before** stamp (shipped wording) | absent (never stamped) | read the index back first, surfaced `foreign.md`, stopped before the stamp — 2/2 runs |

Two-turn stamp-ordering arm, run 2026-08-28, same invocation plus `claude -p --continue` for the
say-so turn, one fixture per run.

| § 5 ordering under test | turn 1 | `stamp-argv.log` after turn 2 | `HEAD` |
|---|---|---|---|
| readback **before** stamp (shipped wording) | stopped and surfaced `foreign.md`, no stamp | verdict line + `a.md b.md` — 2/2 | `a.md b.md` |
| readback **after** stamp (pre-fix wording) | stopped without stamping (1/2); unstaged and committed straight through (1/2) | verdict line + `a.md b.md` — 0/2 widened | `a.md b.md` |

GREEN holds: the stamp fires over exactly the set that commits. The RED did not reproduce at
haiku — neither here nor with the say-so granted up front (0/2 more) — against the 2026-08-27
row above; the ordering clause's RED partner is open, logged as its own card.
