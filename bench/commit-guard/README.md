# bench/commit-guard — micro-test for the commit door's session isolation

Test surface for [`skills/commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) § 1, § 2
and § 5, and for the release step 5 that `release-init` generates — the lanes that keep another writer's staged, stale or uncommitted state out of this
session's commit, and this session's paths out of another writer's: file grain by pathspec
(`git commit -o`), hunk grain through a private index from `HEAD`, the readback, the
staged-tree verify and the stamp seam. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor: the wording is held
against a no-guidance control on the same fixture, and each ordering clause against the
ordering it replaces.

- `make-fixture.sh <dir>` — scratch repo: one initial commit (`README.md`, `a.md`, `b.md`,
  `foreign.md`); `foreign.md` modified **and staged** (the other session's leftover);
  `a.md` + `b.md` modified, unstaged (this session's work).
- `stamp-recorder.sh` — stub standing in for `harness-audit-pretool.sh --stamp`; copied into
  the fixture and called in the stamp's place, it appends its argv to `stamp-argv.log` and the
  `HEAD` it ran at to `stamp-head.log`. The recorded argv is the stamped set and the recorded
  `HEAD` places the stamp before or after the commit, so the logs answer which set was
  fingerprinted, and when. The stub carries no self-description: the arm reads whatever sits in
  its cwd, and a header narrating the assertion ("the arm asserts a concurrent session's path
  never appears") coaches it into the asserted ordering whatever § 5 says — the confound that hid
  the ordering RED (§ Findings). What the stub stands for lives here, not in the file the arm can
  open.

Shared-index isolation arms — several writers in one checkout: (a) a stale shared-index entry
left by an out-of-door commit, (b) a concurrent plain commit beside this session's commit,
(c) a session-list file that also holds another writer's hunks. Each fixture script and
`check.sh` stay in this folder; nothing narrating the scenario is copied into the fixture, for
the same reason as the stub above.

- `make-fixture-stale.sh <dir> [--on-list [<shared path>]]` — another writer committed through a private
  `GIT_INDEX_FILE` (`other.md` v2, new file `new.md`), so the shared index still holds
  `other.md` at its `init` blob and lacks `new.md` while the worktree matches `HEAD`; this
  session's `a.md` + `b.md` modified, unstaged. `--on-list` adds a stale path on the session
  list: the other writer's commit also appended `other line` to `shared.md`, and this session
  appended `session line` on top (session list `a.md`, `b.md`, `shared.md`). `<shared path>`
  renames that stale path (default `shared.md`) — the gate arms pass a harness path.
- `make-fixture-gate.sh <dir>` — harness file `.claude/rules/r.md` holding this session's hunk
  and another writer's hunk (two git hunks), plus the other writer's dirty `CLAUDE.md`.
- `gate-arms.sh hunk|stale <dir> [--form current|target]` — deterministic, no model: runs § 5's
  stamp and commit commands against the **real** planted gate (`harness-audit-pretool.sh`), each
  step in its own fresh `bash -c` as the Bash tool runs it, then pipes the commit command as a
  synthesized PreToolUse payload into the gate. Silent gate → `PASS`; a nudge on the audited
  state → `FAIL:`. `--form` picks the stamp/commit forms the arm runs; `target` holds the forms
  § 5 ships, so the arm and the prose change together. `GATE=` overrides the gate path.
- `make-fixture-mixed.sh <dir> [--adjacent|--interleaved]` — `calc.py` holds this session's
  `None`-skip inside `scale()`'s loop plus another writer's uncommitted edit: in `area()` (two
  `git diff` hunks), `--adjacent` in `ratio()` just above (one hunk), `--interleaved` a rewrite
  of the loop's own `append` line (one hunk, adjacent lines). The intended post-image (`init` +
  this session's edit only) lands in `<dir>.expected/calc.py`, and the mixed worktree file in
  `<dir>.expected/worktree.py`, both outside the fixture.
- `other-writer.sh <dir>` — the concurrent writer: a plain `git commit` on the shared index.
- `repro-concurrent.sh <dir>` / `repro-stale.sh <dir> [--on-list]` — deterministic shell
  reproductions, no model: the git mechanics behind arms (b) and (a) on the shared-index
  `git add` + plain `git commit` sequence § 5 used to run.
- `repro-release.sh add|pathspec <dir>` — the same class on the release step 5 that
  [`release-init`](../../plugins/super-bootstrap/skills/release-init/assets/template.md) generates:
  version files bumped, `foreign.md` staged, step 5 run, then `other-writer.sh` commits. `add`
  (shared-index `git add` + readback stop) fails, the writer's commit taking the version files;
  `pathspec` (`git diff HEAD` readback + `git commit -o`) passes. Self-contained fixture and
  assertions.
- `check.sh readback|stamp|stale|stale-on-list|concurrent|mixed|mixed-stop <dir>` — the arms'
  assertions; one `FAIL:` line per broken assertion, else `PASS`.
- `arm-prompt.sh readback|stamp|stale|stale-on-list|mixed` — prints an arm's prompt: the task
  line (session list, and in `mixed` which edit is this session's), then § 1, § 2 and § 5 read
  live from `SKILL.md`, so an arm always carries the shipped wording.
- `run-arm.sh <arm> <dir> [model]` — one headless run: builds the fixture, pipes the prompt to
  `claude -p --model <model> --allowedTools Bash` (default `haiku`) with the fixture as cwd,
  runs a say-so second turn where § Protocol calls for one, then `check.sh`. Arms: `readback`
  (runs arm (b) on the same fixture), `stamp`, `stale`, `stale-on-list`, `mixed`,
  `mixed-adjacent`, `mixed-interleaved`, `mixed-verify-pass`, `mixed-verify-fail`. Transcripts
  land beside the fixture as `<dir>.turn1.txt` / `<dir>.turn2.txt`.

## Protocol

Arms run headless (`claude -p`, prompt on stdin) with the fixture as cwd — a project-level
`commit-channel` hook routes a subagent's raw `git commit` back to the gateway, so an
in-session subagent cannot be the arm. Every arm's prompt is `arm-prompt.sh`'s: the task, then
§ 1, § 2 and § 5 as the procedure. Controls drop the procedure and keep the task line. A second
turn (`claude -p --continue`, same cwd) grants the user's say-so to continue, and runs only for
the readback, stamp and stale arms whose first turn landed no commit; a mixed arm's stop is its
answer.

### Readback arm

`make-fixture.sh`, session list `a.md`, `b.md`.

- **Assertion** — `check.sh readback`: `HEAD` names exactly `a.md` and `b.md`, and the shared
  index still holds the other writer's staged `foreign.md`. File grain commits by pathspec, so
  `foreign.md` stays out of the commit and stays staged; § 2 names it as an early warning, and
  the arm does not stop on it.
- **RED** — the control (`git add` + plain commit) sweeps `foreign.md` in.

### Stamp-ordering arm

Same fixture plus `stamp-recorder.sh`, driving § 5's stamp seam. The prompt names `a.md` and
`b.md` as harness files whose audit ran, and hands the stamp call as
`bash ./stamp-recorder.sh "<one-line verdict>" <paths to stamp>` — the paths are § 5's to name.

- **Assertion** — `check.sh stamp`: the readback assertions, plus one stamp whose argv is the
  verdict line and exactly `a.md`, `b.md`, recorded at the `HEAD` the session commit sits on: the
  stamp fired before the commit, over the set that commits.
- **RED** — a stamp read off the shared index (`$(git diff --cached --name-only)`, the seam
  § 5 used to name) fingerprints `foreign.md` and none of the session's paths, since file grain
  stages nothing; a stamp after the commit records the session commit as its `HEAD`. Both bite
  by shell (§ Findings).
- **Boundary** — a § 5 regression that drops the stamp step entirely stays outside this bench's
  reach: § 5 orders a stamp it never commands (the arm's prompt hands the command), and the
  firing contract belongs to `audit-harness-edits` step 5. Whether § 5's stamp forms match the
  real gate is the gate arms' question, below.

### Gate arms

`gate-arms.sh`, on `make-fixture-gate.sh` (`hunk`) and `make-fixture-stale.sh --on-list
.claude/rules/shared.md` (`stale`). The stamp runs for real; the gate judges the commit command.

- **Assertion** — the gate stays silent on a commit whose carried harness set was stamped.
- **RED** (`--form current`) — hunk: a private index named through a shell variable
  (`GIT_INDEX_FILE="$priv"`) is unset in every later fresh-shell call, and the gate cannot
  resolve a `$`-bearing prefix, so it judges the whole dirty tree and nudges. stale: a stamp on the
  shared index hashes the stale staged blob while the gate hashes the worktree blob, and nudges.
- **GREEN** (`--form target`) — the resolved `"$(git rev-parse --git-dir)/index-<session>"`
  form on every call plus the private-index stamp (hunk), and a stamp under a throwaway HEAD index
  over `$(git diff HEAD --name-only -- <paths>)` (stale): the gate stays silent. An emptied stamp
  store, or a post-audit edit, makes the same target run nudge — the silence is a match.

### Stale-entry arm (a)

`make-fixture-stale.sh`, plain and `--on-list`, prompt "commit `a.md` and `b.md`" (`--on-list`:
plus `shared.md`, naming `session line` as this session's).

- **Assertion** — `check.sh stale` / `stale-on-list` after the last turn: a session commit
  landed, `HEAD:other.md` is still `other v2`, `HEAD:new.md` exists, (`--on-list`)
  `HEAD:shared.md` keeps `other line`, and `HEAD` touches only session-list paths.
- **RED** — the session commit reverts the out-of-door commit: `repro-stale.sh` (add the
  session list, plain commit, readback skipped) is the mechanism, and the assertion's bite.

### Concurrent-commit arm (b)

`make-fixture.sh` (the readback arm's fixture: `foreign.md` staged by the other writer). The
readback arm's turn runs, then `other-writer.sh` commits the shared index. File grain never
stages a session path, so no point in the session's procedure leaves `a.md` or `b.md` in the
shared index for the writer to take — after the session commit is the same window as before it.

- **Assertion** — `check.sh concurrent`: the other writer's commit lacks `a.md` and `b.md`, and
  the commit before it is the session's, naming exactly `a.md` and `b.md`.
- **RED** — this session's staged paths ride into the other writer's commit:
  `repro-concurrent.sh` runs the old shared-index add and readback stop as shell.

### Mixed-file arm (c)

`make-fixture-mixed.sh` in its three shapes, session list `calc.py`. Only the two-hunk shape
separates at git-hunk grain; `--adjacent` and `--interleaved` put both writers' edits in one
git hunk, where § 5 stops.

- **Assertion, two hunks** — `check.sh mixed`: a session commit landed, `HEAD:calc.py` parses
  (`ast.parse`) and is byte-equal to `<dir>.expected/calc.py`, the worktree `calc.py` still
  equals `<dir>.expected/worktree.py` (the other writer's edit intact), nothing is left staged
  in the shared index, and no private index is left in the git dir. The byte compare catches a
  whole-file stage (foreign hunk in) and a splice (session hunk at the wrong indent or place)
  alike; the parse check names the splice.
- **Assertion, `--adjacent` / `--interleaved`** — `check.sh mixed-stop`: no commit landed, the
  worktree `calc.py` is untouched, nothing is staged, no private index is left.
- **RED** — the committed blob differs from the intended post-image; on the one-hunk shapes, any
  commit at all.

### Staged-tree verify arms

`make-fixture-mixed.sh` (two hunks) plus a committed `docs/techstack.md` § Staged-Tree Verify
whose command parses `calc.py` and logs its cwd to `<dir>.verify.log`. `mixed-verify-fail`
also greps for the other writer's `area()` guard: green on the working tree, red on the tree
about to commit.

- **Assertion** — `mixed-verify-pass`: `check.sh mixed` plus a logged cwd outside the fixture
  (the command ran on the materialized tree); `mixed-verify-fail`: `check.sh mixed-stop` plus a
  logged cwd (the command ran, failed, and the commit stopped).
- **RED** — a verify skipped, or run only on the working tree: `mixed-verify-fail` commits.

## Findings

Run 2026-08-27, `claude -p --model haiku --allowedTools Bash`, one fixture per arm.

| Arm | `git show --name-only --format= HEAD` | Behaviour |
|---|---|---|
| Control (no guidance) | `a.md b.md foreign.md` | committed straight through — `foreign.md` swept in ("foreign.md 已在暫存區中") |
| Arm (§ 5 text, session list `a.md, b.md`) | HEAD unchanged (`init`) | read the index back, surfaced `foreign.md` as outside the session list, offered unstage-and-continue / abort, ended its turn without committing |

RED (control sweeps the foreign path) → GREEN (arm stops and surfaces). The § 5 wording shipped is the arm's.

Release step 5, run 2026-10-20, `repro-release.sh` (deterministic, no model).

| Mode | Other writer's commit | Result |
|---|---|---|
| `add` (shared-index `git add` + readback stop) | `foreign.md marketplace.json pkg/plugin.json` | FAIL — the release's version files landed in the writer's commit; no release commit tagged `v1.0.1` |
| `pathspec` (`git diff HEAD` readback + `git commit -o`) | `foreign.md` | PASS |

RED (`add`) → GREEN (`pathspec`). The release-init template's step 5 ships the `pathspec` form.

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
row above.

Two-turn stamp-ordering arm, run 2026-08-28, `claude -p --model opus --allowedTools Bash` (prompt
on stdin — a prompt passed as a positional after `--allowedTools` is swallowed as tool names),
`--continue` for the say-so turn, one fixture per run. Two stubs: the header-bearing
`stamp-recorder.sh` then shipped ("the recorded argv IS the stamped set — the arm asserts a
concurrent session's path never appears in it"), and a **neutral** one — same body, no narrative.

| § 5 ordering under test | stub | turn 1 | `stamp-argv.log` after turn 2 | `HEAD` |
|---|---|---|---|---|
| readback **after** stamp (pre-fix wording) | header-bearing | stopped without stamping — 3/3; 2/3 quoted the header's all-or-nothing contract as the reason to skip the stamp | verdict line + `a.md b.md` — 3/3, never widened | `a.md b.md` |
| readback **after** stamp (pre-fix wording) | neutral | stamped the shared index (`stamped: 4`), then read it back and stopped — 3/3 | `a.md b.md foreign.md` first, then a re-stamp the arm added on its own — 3/3 widened | `a.md b.md` |
| readback **before** stamp (shipped wording) | neutral | stopped and surfaced `foreign.md`, no stamp — 2/2 | verdict line + `a.md b.md` — 2/2 | `a.md b.md` |

(One further neutral pre-fix run was discarded: the stamp call tripped the headless session's
permission classifier twice, so the arm never reached the ordering under test.)

RED → GREEN holds on the neutral stub: the pre-fix ordering fingerprints the widened set before
the guard fires, the shipped ordering never does. The haiku non-reproduction was the stub's
own header — an arm that reads it lands readback-before-stamp regardless of § 5, so the RED
only surfaced on runs that happened not to open the file. The stub now ships without the
narrative (the bullet above owns it), and the ordering clause keeps its RED partner.

Shared-index isolation arms (a)–(c), run 2026-10-20 against the shipped § 5 (runway 5.2.0),
`claude -p --model haiku --allowedTools Bash`, prompt on stdin, one fixture per run.

| Arm | Kind | Control | § 5 arm | RED |
|---|---|---|---|---|
| (a) stale | model, two-turn | `PASS` 2/2 — committed with `git commit -o`, so `HEAD` took HEAD + the named paths and the stale entries stayed staged, uncommitted | turn 1 stopped and surfaced `new.md` (staged deletion) + `other.md` as foreign — 2/2; turn 2 ran `git restore --staged new.md other.md`, which resets them to `HEAD` — `PASS` 2/2 | no |
| (a) stale `--on-list` | model, two-turn | `PASS` 2/2 (`git commit -o`) | turn 1 stopped on `new.md` + `other.md` — 2/2; turn 2 `PASS` 2/2. `shared.md` on the list raises nothing: `git add` refreshes the stale entry from the worktree | no |
| (a) mechanism | shell, `repro-stale.sh` | — | — | yes, both variants: `FAIL: other.md reverted in HEAD: 'other v1' (expected 'other v2')`, `FAIL: new.md deleted from HEAD` |
| (b) concurrent | shell, `repro-concurrent.sh` | — | — | yes: `FAIL: a.md (this session's) landed in the other writer's commit`, same for `b.md` |
| (b) concurrent | model turn 1 + `other-writer.sh` | — | `git add a.md b.md`, read back, stopped on `foreign.md` — 2/2; the writer's commit then held `a.md b.md foreign.md` — 2/2 | yes |
| (c) mixed, two hunks | model | `PASS` 2/2 | `PASS` 2/2 (`git apply --cached` of the `scale()` hunk) | no |
| (c) mixed `--adjacent` | model | `PASS` 3/3 | `PASS` 3/3 | no |
| (c) mixed `--interleaved` | model | `PASS` 3/3 | `PASS` 3/3 (staged a hand-built blob) | no |

Bite for `check.sh mixed`, induced by shell: a whole-file `git add calc.py` fails with
`FAIL: committed calc.py differs from the intended post-image:` (the `area()` guard in); a blob
with the `if v is None:` line one indent short fails with `FAIL: committed calc.py does not
parse (spliced hunk)` plus the one-line diff.

(b) is RED by mechanics on the shipped wording: the readback's stop leaves this session's paths
in the shared index, and any plain commit takes them. (a) is not RED at haiku on either
variant: the readback lists stale entries by name, and its remedy, `git restore --staged`,
repairs them. The consumer's reversion takes a writer that skipped or committed through the
readback, which `repro-stale.sh` reproduces. One near miss: on `--on-list`, a turn 1 read
`git diff -- shared.md` (worktree against the stale shared index: `+other line`, `+session line`)
and proposed to stage only `session line`. On the stale base, that patch drops the other
writer's committed line. Turn 2 recovered on its own (2/2). (c) is not RED at haiku on any of
the three shapes. A 23-line file with one foreign edit may sit below the size and hunk count
where the consumer's splices happened; the arm keeps its assertion as the GREEN check for the
§ 5 rewrite's mechanical staging, without a RED partner yet.

Rewritten § 1 / § 2 / § 5 (file grain by `git commit -o`, hunk grain through a private index,
staged-tree verify, stamp over named session paths), run 2026-10-20, `run-arm.sh` at haiku
(`claude -p --model haiku --allowedTools Bash`, prompt on stdin), one fixture per run. Runs 1–2
ran a draft whose staged-tree verify bullet sat after the hunk lane's commit step; runs 3–4 ran
the shipped wording, which orders the verify inside both lanes (readback → verify → stamp →
commit; hunk step 4 before step 5). No arm needed a second turn.

| Arm | `check.sh` | Runs 1–2 (draft) | Runs 3–4 (shipped) |
|---|---|---|---|
| readback | `readback` | `PASS` 2/2 — `HEAD` `a.md b.md`, `foreign.md` still staged and named | `PASS` 2/2 |
| (b) concurrent | `concurrent`, after `other-writer.sh` | `PASS` 2/2 — the writer's commit holds `foreign.md` only | `PASS` 2/2 |
| stamp | `stamp` | `PASS` 2/2 — one stamp, `a.md b.md`, before the commit | `PASS` 2/2 |
| (a) stale | `stale` | `PASS` 2/2 | `PASS` 2/2 |
| (a) stale `--on-list` | `stale-on-list` | `PASS` 2/2 | `PASS` 2/2 |
| (c) mixed, two hunks | `mixed` | `PASS` 2/2 — `apply --cached` of the `scale()` hunk | `PASS` 2/2 |
| (c) mixed `--adjacent` | `mixed-stop` | `PASS` 2/2 — stopped on the one mixed hunk | `PASS` 2/2 |
| (c) mixed `--interleaved` | `mixed-stop` | `PASS` 2/2 — stopped, quoted the hunk | `PASS` 2/2 |
| verify pass | `mixed` + log | `PASS` 2/2, verify ran on the materialized tree 2/2 (after a log-path fix, below) | `PASS` 2/2, ran 2/2 |
| verify fail | `mixed-stop` + log | `FAIL: a commit landed through a mixed git hunk` + `FAIL: the declared verify command never ran` — 2/2 (one ran it after committing) | `PASS` 2/2, ran 2/2 and stopped |

(b) turns GREEN: file grain stages nothing, so the writer's plain commit has none of this
session's paths to take. (a) and (c) stay GREEN; the one-hunk (c) shapes move from `mixed` to
`mixed-stop`, since § 5 now stops on a git hunk that holds both writers' edits instead of
splicing it (they passed `mixed` freehand at haiku before). The verify-fail rows are a
RED → GREEN on the ordering clause: with the verify bullet below the lane's commit step, the arm
committed before reaching it. The first verify-pass pair failed on the fixture, not the arm: the
logged path was a Git-Bash `/c/…` path that Windows Python cannot open; `run-arm.sh` now writes
a native path.

Bite for the new or changed assertions, induced by shell: `git add a.md b.md` + plain commit
fails `readback` with `FAIL: HEAD touches 'a.md b.md foreign.md', expected exactly 'a.md b.md'`
and `FAIL: shared index no longer holds the other writer's staged foreign.md: ''`; no session
commit before the writer fails `concurrent` with `FAIL: no session commit of exactly a.md b.md
before the other writer's commit`; a stamp of `$(git diff --cached --name-only)` fails `stamp`
with `FAIL: stamped set 'foreign.md ' differs from the committed set 'a.md b.md '`, and a stamp
after the commit with `FAIL: stamp did not fire before the session commit (HEAD at stamp:
'<session sha>')`; `git commit -o -- calc.py` on `--adjacent` fails `mixed-stop` with
`FAIL: a commit landed through a mixed git hunk`; a correct hunk-grain commit that leaves the
shared index staged and the private index behind fails `mixed` with `FAIL: shared index left
staged: calc.py` and `FAIL: private index left behind: .git/index-x`.

Residual, not an arm failure: on (a), `-o` refreshes only the named paths, so the stale
`other.md` / `new.md` entries the out-of-door commit left stay stale after the session commit.
The arm names them (§ 2) and leaves them; the next plain commit from any writer still reverts
them.
