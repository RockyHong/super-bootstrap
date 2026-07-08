# Merge-probe — venue-S gateway verification

The gateway-side verification lane for items whose verify phase is **stack-bound** — needs a real runner (emulator, ports, browser, native build) but no human. This is venue **S** in `.claude/rules/venue-map.md`; it exists only when the scale module is wired (no venue map → no S items; the bare cloud-safe criterion classifies these `Device` and they defer). Two properties make it gateway-side, not in-worktree:

- **Non-nested surface.** A worktree is physically nested in the parent repo, so module resolution walks up into the parent's installed deps and a build can false-green on phantom deps (`parallel-worktrees.md §Nested-worktree false-greens`). Stack-bound verification must run on a **real, non-nested checkout** — the merged base, gateway-side.
- **Fixed-resource collision.** Real runners bind fixed ports / emulator sockets that collide across concurrent worktrees. Gateway-serial at the merge gate avoids the collision that in-worktree-parallel would hit.

So an **S** item is drain-eligible but is **not** a user wall: the subprocess does the cloud-safe part in the worktree (author the spec/test, run the collection-only or static check — e.g. a test **list**, a typecheck, a lint), writes `DONE`, and halts at the merge gate. The full stack-bound run is the gateway's, at merge.

## Parameterize from the consumer's techstack — never hardcode a stack

The build/test commands come from **`docs/techstack.md`** (its Commands / build-test section, or the repo's `CLAUDE.md` Commands block), read at probe time. drain ships no stack assumption — no `pnpm`, no `playwright`, no framework literal in this file.

```
probe_cmd = techstack_commands("test" | "e2e" | "build")   # from docs/techstack.md
if probe_cmd is empty or docs/techstack.md absent:
  # nothing to run — degrade to the cloud-safe static check the subprocess already did
  skip the full probe; the merge gate is the plain no-auto-merge halt
```

Absent techstack, or a techstack with no runnable build/test command → **skip the probe**; the item still halts at the ordinary merge gate for the user to inspect and confirm. The probe adds gateway verification when the consumer has declared how to run it, and is a no-op when it hasn't.

## Gateway merge-probe flow (stack-agnostic)

Runs at `SKILL.md §Merge gate` for an S item, on the non-nested base. This is a gateway-exclusive destructive-git action (the drain no-auto-merge invariant still holds — the merge only finalizes on green, behind the user's confirm to run the probe):

```bash
cd <repo-root>
git merge --no-commit --no-ff drain/{id-lower}    # materialize on the non-nested base; no commit yet
<probe_cmd from docs/techstack.md>                 # the real runner, gateway Bash (unrestricted)
# green → git commit          # finalizes the merge
# red   → git merge --abort    # no base pollution → re-dispatch the subprocess to iterate in the worktree
```

- The merge is left **un-committed** until the probe is green, so a red probe aborts cleanly with zero base pollution.
- Red → the item is not done: re-dispatch its build phase in the same worktree (`phase-loop.md`) to iterate, then re-probe. This is the venue-S row of `phase-loop.md §Halts`.
- Any machine-global runner cache (browser binaries, toolchains) is a one-time install per machine, shared across worktrees — not a per-drain cost. If the consumer's techstack names an install command, run it once, not per item.

## Boundary

drain does not re-implement merge — the plain (non-probe) merge still runs via `/super-bootstrap:merge` (the destructive-git lane). The merge-probe is the **S-only** extension: the same hand-off, with a gateway verification run wedged before the finalizing commit. For a T item there is no probe — the subprocess's in-worktree tests are the verification, and the merge gate is the plain no-auto-merge halt.
