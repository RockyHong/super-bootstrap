# bench/log-closed-forks — micro-test for `/log` step 2's Closed-forks outcome line

Test surface for [`skills/log/SKILL.md`](../../plugins/super-bootstrap/skills/log/SKILL.md)
steps 1-2: the Closed-forks gate, and whether a run leaves a per-entry trace that tells a
clean read apart from an unread source. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. The mechanical half
(the source resolves, or it fails loud) is the script
[`log/assets/closed-forks.sh`](../../plugins/super-bootstrap/skills/log/assets/closed-forks.sh),
pinned by [`tests/closed-forks.test.sh`](../../tests/closed-forks.test.sh). This bench measures
only the prose half: does the reply carry one outcome line per entry?

**Copy under test:** the in-repo dev copy. Control = [`skill-control.md`](skill-control.md),
byte-exact `git show HEAD:plugins/super-bootstrap/skills/log/SKILL.md` at `1a3507e`. Arm = the
working-tree `SKILL.md` with its bundled `assets/closed-forks.sh`.

## Fixture

[`fixture/`](fixture/) is a minimal consumer repo for a bash CLI `tally`: `docs/work/` (README
with high-water `BUG-003` · `DEBT-001` · `GAP-004`, TEMPLATE, no open cards) and
`docs/decisions.md` (the shipped skeleton plus three Closed Forks rows). No `docs/parked.md`, no
`docs/outward/`. Two entries per run:

1. "rewrite tally in Python — faster and easier to extend" — collides with the row *Port the
   `tally` CLI from bash to Python for speed*.
2. "README Install never says `chmod +x tally`" — clean: no row touches it.

## Protocol

Each trial copies `fixture/` to a fresh scratch directory and dispatches one cold
`general-purpose` subagent (Agent tool, `model: sonnet`) with [`scenario.md`](scenario.md),
`{ROOT}` = the scratch copy, `{SKILL}` = the arm's skill file, `{BASE}` =
`plugins/super-bootstrap/skills/log` (so `<skill-base>` resolves to the in-repo assets). The
subagent executes the skill with tools and ends with its reply to the user. The scenario names
no outcome line; the skill text is the only variable.

**Axis:** the reply to the user carries a Closed-forks outcome line for entry 2 (the clean one).
Without it, a clean read and an unread `decisions.md` leave the same trace.

**Pre-registration:** the expected control failure — no per-source outcome line on the clean
entry — was stated in the dispatch brief before the first trial ran.

## Findings

Run 2026-10-10, `model: sonnet`, cold subagents.

| Arm | Trial | Entry 1 (collides) | Entry 2 (clean) — Closed-forks line in reply | Card written |
|---|---|---|---|---|
| Control | 1 | surfaced the fork, not logged | **none** | `BUG-004` |
| Control | 2 | — reply lost: the hand-back body was the literal `placeholder` | — (invalid trial) | `BUG-004` |
| Control | 3 | surfaced the fork, not logged | **none** | `BUG-004` |
| Control | 4 | surfaced the fork, not logged | **none** | `DEBT-002` |
| Arm | 1 | `decisions.md § Closed Forks — collides: [tech] Port the tally CLI from bash to Python for speed` | `decisions.md § Closed Forks — no collision` | `BUG-004` |
| Arm | 2 | ``decisions.md § Closed Forks — collides: [tech] Port the `tally` CLI from bash to Python for speed`` | `decisions.md § Closed Forks — no collision` | `BUG-004` |
| Arm | 3 | `decisions.md § Closed Forks — collides: [tech] Port the tally CLI from bash to Python for speed` | `decisions.md § Closed Forks — no collision` | `BUG-004` |

Control replies on entry 2, verbatim:

- Trial 1: "**2) README missing `chmod +x tally`: logged as BUG-004.** … There were no open cards
  to check for duplicates. There is no `docs/parked.md` or `docs/outward/`, and nothing in the
  item needed them." — dedup and the two other sources are accounted for; `decisions.md` is not.
- Trial 3: "**Entry 2 (logged):** the missing `chmod +x tally` step is now `BUG-004` … I changed
  nothing else and did not investigate." — no source named.
- Trial 4: "**2) README Install section omits `chmod +x tally`: logged as DEBT-002.** … There was no
  suspected duplicate, because no other open cards exist, and no outward thread folder." — no
  `decisions.md` mention.

**Verdict: RED → GREEN.** Control: 0/3 valid trials emit a Closed-forks outcome for the clean
entry; each control does surface the collision on entry 1, so the gate fires on a hit and is
silent on a miss — exactly the shape that makes a clean read and an unread source identical. Arm:
3/3 emit an outcome line for both entries, the collision line quoting the script's projected row.

**Declared bounds.**
1. N=3 valid per arm, one model tier (sonnet). Shows the wording moves the trace, not that no
   other phrasing would.
2. The fixture's decisions.md resolves cleanly, so the stop path (script exits non-zero →
   surface and hold) is pinned by the unit test's failure fixtures, not exercised here.
3. Trials run as in-session subagents, so the dispatching repo's `CLAUDE.md` is in their ambient
   context; the scenario points them at the fixture root only.
