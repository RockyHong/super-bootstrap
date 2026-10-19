# bench/autorun-derived-state — regenerate derived state before verify

Test surface for [`skills/autorun/assets/parallel-worktrees.md`](../../plugins/super-bootstrap/skills/autorun/assets/parallel-worktrees.md)
§ Provisioning, its worker-side copy in [`worktree-boundary.md`](../../plugins/super-bootstrap/skills/autorun/assets/worktree-boundary.md),
and the merge-gate verify line in [`skills/autorun/SKILL.md`](../../plugins/super-bootstrap/skills/autorun/SKILL.md)
§ Rules: before a verify, when tracked sources changed through something other than the verifying session's own edits,
run the regenerate commands the repo's docs name. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor, on the protocol shape
[`bench/merge-occupied`](../merge-occupied/README.md) uses.

- [`make-fixture.sh`](make-fixture.sh) `<dir> respawn|mergegate` — `<dir>/repo`, whose `CLAUDE.md` `## Commands` names
  install (`tools/install.sh`), regenerate (`tools/codegen.sh` → git-ignored `gen/registry.txt`) and verify
  (`tools/verify.sh`: each `uses: X` in `src/*.src` must be in the registry). Each script appends its name to the
  git-ignored `.bench-log`. `respawn`: a provisioned worktree on `autorun/gap-12` with `main` merged in, which
  brought `src/billing.src` (`uses: invoice`) and `src/invoice.src`. `mergegate`: a provisioned main checkout with
  `autorun/gap-12` (the same two files) landed by Merge --no-ff. Either way the registry predates `invoice`, so a
  verify before regenerating fails with `src/billing.src: error: unknown type 'invoice'`. `<dir>/coldcfg` is a
  credentials-only `CLAUDE_CONFIG_DIR`.
- [`run.sh`](run.sh) `<dir> <tag> [model]` — one model run on a fresh fixture, `--allowedTools Bash`, cwd the
  scenario's tree, so the fixture `CLAUDE.md` loads as project memory. `SCENARIO=respawn` (default): prompt =
  `worktree-boundary.md` whole, the provisioning section, "the gateway merged `main` into your branch before this
  re-spawn", and a work order (one edit, verify, commit, status line). `SCENARIO=mergegate`: prompt = SKILL.md
  § Rules, the provisioning and Nested-worktree false-greens sections, "`autorun/gap-12` just landed; run the
  merge-gate verification". `SCENARIO=nocue`: the branch carries an earlier session's commit that added the two
  files; the prompt is `worktree-boundary.md` alone plus the work order, and names no history. `DELIVERY=brief`
  (respawn): the prompt carries `worktree-boundary.md` alone, as the real brief delivers it, with no pasted
  provisioning section. Text extracted at run time; `SKILL_REF=HEAD` takes it from a commit instead. Writes
  `runs/<tag>.prompt.md`, `.result.txt`, `.state.txt` (`.bench-log` order, "first verify preceded by codegen?",
  status line, git log).
- [`text-run.sh`](text-run.sh) `<dir> <tag> [model]` — no-tools probe: the same two scenarios with the Commands block
  in the prompt and the situation handed over in words; asks for the command sequence. `LEAN=1` names no changed
  file. Writes `runs/text-<tag>.*`.

Pass an absolute `<dir>` outside this repo.

## Protocol

- **Control** — `SKILL_REF` at the commit before the fix (provisioning names the install command only, as a cold
  tree's first action).
- **Arm** — the shipped text.
- **Assertion** — `.bench-log` shows `codegen` before the first `verify`.

## Findings

Run 2026-10-20, haiku, one fresh fixture per run, three runs per cell.

| Cell | `.bench-log` | first verify after codegen |
|---|---|---|
| Control respawn | `verify, codegen, verify[, …]` | 0/3 |
| Arm respawn | `install, codegen, verify` (r1, r3); `codegen, verify` (r2) | 3/3 |
| Arm respawn, `DELIVERY=brief` (r1) | `codegen, verify` | 1/1 |
| Control nocue (`worktree-boundary.md` at `HEAD`) | `verify, codegen, verify[, …]` | 0/3 |
| Arm nocue | `install, codegen, verify` (r2); `install, codegen, codegen, verify` (r1); `install, install, codegen, verify` (r3) | 3/3 |
| Control mergegate | `install, codegen, verify` | 3/3 |
| Arm mergegate | `install, codegen, verify` | 3/3 |
| Text probe, control, both scenarios, with and without `LEAN` | (named codegen before verify) | 12/12 |

RED (respawn): the pre-fix text fires provisioning on a cold tree only, so a re-spawned worker verifies on the
stale registry first, every run. Control r2: "Verify failed at first with `billing.src: unknown type 'invoice'`.
The cause was a stale `gen/registry.txt`, not the record." In this fixture the error points at its cause and the
worker recovered each time; a cache whose error does not reads as a break. GREEN: the shipped text regenerates
before the first verify 3/3 ("I ran `sh tools/codegen.sh` before verify, because the merge of `main` changed
`src/`").

The respawn scenario's base sync into the branch is a cue no shipped step produces; nocue is the shipped shape
(a re-spawn into a tree an earlier session left, with nothing in the prompt saying so). Arm respawn, and its
`DELIVERY=brief` run, used an earlier wording of the worker rule without the `git log` check.

No cue (nocue): control verifies first on the stale registry 3/3 (r2: "Verify failed at first:
`src/billing.src: error: unknown type 'invoice'`. The cause was a stale `gen/registry.txt`"). Arm regenerates
before the first verify 3/3, but through the cold-tree bullet, not the `git log` check: r1 "I ran
`sh tools/install.sh` and `sh tools/codegen.sh` first, since the tree was cold"; r2 and r3 name provisioning
with no reason. A worker that cannot tell a provisioned tree from a cold one provisions it in full, which also
clears the stale state; the `git log` check itself is not shown to fire.

Delivery: a worker's brief embeds `worktree-boundary.md` only, so the worker-side rule lives there and
`parallel-worktrees.md` § Provisioning stays the gateway-side home. With the anchor alone the re-spawned worker
regenerates before verify 1/1 ("the merged `main` added `billing.src` and `invoice.src`, so I ran
`sh tools/codegen.sh` before verify. I skipped install because no manifest changed").

No RED at the merge gate: a gateway handed a landing on the base tree plus the module-resolution rule already
reinstalls and regenerates 3/3, control and arm alike. The merge-gate half of the fix ships on the card's
enumerated hazard (a landing changes the base tree's sources under its derived state), not on a RED. The text
probe shows the same once the situation is spelled out: a handed-over "sources changed" cue is enough, and the
gap is the cold-tree-only trigger a worker reads when nothing hands it the cue.
