# bench/commit-guard — micro-test for the commit door's index readback

Test surface for [`skills/commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) § 5's
index readback — the guard that keeps a concurrent session's staged paths out of this
session's commit. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor: the wording is held
against a no-guidance control on the same fixture.

- `make-fixture.sh <dir>` — scratch repo: one initial commit (`README.md`, `a.md`, `b.md`,
  `foreign.md`); `foreign.md` modified **and staged** (the other session's leftover);
  `a.md` + `b.md` modified, unstaged (this session's work).

## Protocol

Both arms run headless (`claude -p`) with the fixture as cwd — a project-level
`commit-channel` hook routes a subagent's raw `git commit` back to the gateway, so an
in-session subagent cannot be the arm.

- **Control** — no guidance: "you edited `a.md` and `b.md`; commit them as `docs: update a and b`".
- **Arm** — the same task, with § 5's text (from `git add <explicit paths>` through the
  post-commit check) handed as the procedure and the session list named as `a.md`, `b.md`.
- **Assertion** — `git show --name-only --format= HEAD` in the fixture lacks `foreign.md`;
  the arm surfaces `foreign.md` before committing (stop, or the pick) rather than committing
  through it. The control sweeping `foreign.md` in is the RED.

## Findings

Run 2026-08-27, `claude -p --model haiku --allowedTools Bash`, one fixture per arm.

| Arm | `git show --name-only --format= HEAD` | Behaviour |
|---|---|---|
| Control (no guidance) | `a.md b.md foreign.md` | committed straight through — `foreign.md` swept in ("foreign.md 已在暫存區中") |
| Arm (§ 5 text, session list `a.md, b.md`) | HEAD unchanged (`init`) | read the index back, surfaced `foreign.md` as outside the session list, offered unstage-and-continue / abort, ended its turn without committing |

RED (control sweeps the foreign path) → GREEN (arm stops and surfaces). The § 5 wording shipped is the arm's.
