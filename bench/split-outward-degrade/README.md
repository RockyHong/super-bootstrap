# bench/split-outward-degrade — micro-test for the outward split's no-`python3` stop

Test surface for [`skills/harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)
§ 2a-scale "Split before placing" and its hold-back in § Pipeline-owned (scale module) and the `y`
placements: when `docs/outward.md` exists and `python3` is absent, the run skips the split, leaves the flat
file untouched, names the prerequisite (install `python3`, re-run the sync), writes nothing under
`docs/outward/` — a placed `docs/outward/README.md` makes every later split refuse (exit 2) — and continues
the sync. This is the invoking step's declared degrade path for
[`split-outward.py`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/split-outward.py),
which [`asset-dialects`](../../.claude/rules/asset-dialects.md) asks of every Python asset. Behavior-shaping
prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor, in the
shape of [`bench/release-init-door`](../release-init-door/README.md).

- `make-fixture.sh <dir>` — scratch repo: `docs/outward.md` with two `### OUT-###` entries,
  `docs/parked.md` from the shipped skeleton (scale module installed), no `docs/test-queue.md` (a scale
  member § 2b resolves `Missing → write`), no `docs/outward/`. `<dir>.outward.before` holds the flat file.
- `extract.sh <skill-md>` — the rendered sections: Phase 2's intro (per-artifact rule, registration rule,
  pipeline-owned / project-owned lists) and § 2a-scale whole, cut on headings so any revision extracts.
- `run.sh <control|arm> <dir> [model]` — fresh fixture, one headless run with `python3` hidden, then
  `score.sh`. The scale assets are copied to `<dir>.plugin`, so the run never touches the repo.
- `score.sh <out-file> <dir>` — the assertions below; one PASS or FAIL each, exit 1 on any FAIL.
- `bite.sh <scratch-dir>` — each assertion failing on a hand-driven violating run, zero LLM calls.

## Protocol

Arms run headless (`claude -p --model haiku --allowedTools "Bash Read Write Edit Glob Grep"
--setting-sources "" --strict-mcp-config --system-prompt <stub> --permission-prompts none`) with the fixture
as cwd, the prompt on stdin. `prompt.txt` states Phase 1, § 2a and § 2a-hooks ran, scopes the run to
§ 2a-scale plus § 2b's scale-member drift check, pre-approves every write, and states that the device has
no Python interpreter anywhere (same text in both arms); the extracted sections follow. `python3` is hidden
by a PATH with every python / conda / WindowsApps entry dropped, `HOME` pointed at an empty dir (so the Bash
tool's login profile cannot re-add them), and a `py` shim answering `command not found`. Scratch fixtures
live outside the repo (`C:/Users/User/AppData/Local/Temp/claude/bench-yyae/` on the authoring device).

- **Control** — `SKILL.md` at `SKILL_REF` (default `HEAD`): only the exit-2 branch; no `python3`-absent
  branch, no hold-back on the outward placements.
- **Arm** — the working-tree `SKILL.md`: the same stop for `python3` absent or failing to launch, with the
  named prerequisite, and `docs/outward/README.md` + `TEMPLATE.md` held while `docs/outward.md` exists.
- **Assertions** — (a) no file under `docs/outward/`; (b) `docs/outward.md` byte-identical to the fixture's;
  (c) an output line naming python that says to install it or to re-run ("not installed" alone fails);
  (d) `docs/test-queue.md` placed — the sync continued past the split.

## Findings

Run 2026-11-24, Haiku requested, one fixture per run, 3 per arm, prompt with the no-interpreter line.

| Arm | run | (a) no outward/ | (b) flat intact | (c) prerequisite | (d) continued |
|---|---|---|---|---|---|
| Control (`HEAD`) | r1 | pass | pass | pass — "run the split with a Python interpreter, then re-run this step" | pass |
| Control (`HEAD`) | r2 | pass | pass | FAIL | FAIL — halted all placements at the split |
| Control (`HEAD`) | r3 | pass | pass | FAIL | pass |
| Arm (working tree) | r1 | pass | pass | pass | pass |
| Arm (working tree) | r2 | pass | pass | pass — "install `python3`, then re-run the sync" | pass |
| Arm (working tree) | r3 | pass | pass | pass — "install Python 3 and re-run the sync" | pass |

RED (control 1/3 clean: no recovery step named in 2/3, the whole sync halted in 1/3) → GREEN (arm 3/3).
With the no-interpreter line stated, the control already held the folder in 3/3, on the "strands those
entries" sentence alone; the hold-back's value shows in the earlier run below, where the control placed
`README.md` + `TEMPLATE.md` as soon as an interpreter turned up.

Earlier control run, prompt without the no-interpreter line (3 runs): r1 halted the whole sync (d FAIL);
r2 and r3 found a real interpreter by absolute path (`.../Python310/python.exe`, `/c/Windows/py.exe -3`),
ran the script, and wrote all four `docs/outward/` files — (a) (b) (c) FAIL. Not an arm-comparable reading:
python3 was not truly absent.

## Lessons

- **PATH filtering does not hide an interpreter from an agent.** The Bash tool sources the login profile,
  which re-adds Miniconda and the `py` launcher; with `HOME` redirected, the agent still found
  `Python310/python.exe` and `C:/Windows/py.exe` by absolute path. The absent case holds only when the
  prompt states it as a device fact — same line in both arms.
- **A shim named like the missing command is a tell.** `command -v python3` printing a shim path reads as a
  stub, not an absence; shim only what PATH must keep (`py` in `C:/Windows`) and let the rest go
  genuinely not-found.
- **A `C:/…` entry in PATH splits on its colon.** Build the shim path from `pwd` (POSIX `/c/…`), never a
  native path.
- **"not installed" matches a loose `install` grep.** (c) keys on `re-run` or `install it/python`, so a
  diagnosis without a recovery step fails.
