# Carry — GAP-064: v2.41.1 tagged; pilot migration tail still open

## Anchor

GAP-064 + OUT-001. Pilot (Magnetized Remake) synced 2.34.2 → 2.40.0 `SYNC WITH ISSUES`; its producer findings shipped as v2.41.0, and this session's card sweep (GAP-065 closed no-change · DEBT-089 · DEBT-095 fixed · DEBT-100 logged · DEBT-099 still deferred) as **v2.41.1**. Card + OUT-001 close only when the pilot migrates its author-moved cards (its DEBT-088).

## Read first

1. `docs/work/GAP-064.md` — last Progress block (`consumer pilot sync`).
2. `docs/outward.md` — OUT-001 (tail = delete GAP-064).
3. `docs/work/DEBT-099.md` (worktree template `_comment` — rides the next substantive template change; `placed` hashes exist only after a consumer runs 2.41.x drain ensure-infra; `v2.41.1..HEAD` touches the file 0 times → still waits).
4. Pilot (PRIVATE — read by path, never copy): `D:/Git/Games/Magnetized Remake/docs/work/DEBT-088.md` — still present with its six cards; `outward.md` there holds one entry.

## State

`bd0810d` = `chore: release v2.41.1`, tag `v2.41.1` **pushed**; `main` pushed through the session-close commit. `/plugin update` + `/reload-plugins` ran (cache holds 2.41.1 at user scope, `claude plugin list` = enabled), yet `super-bootstrap:*` skills were absent from **two** consecutive sessions' listings (both launched from `plugins/super-bootstrap/`; commit door run by hand from `skills/commit/SKILL.md`) — the CCM-filed `plugin-version-resolution-user-scope-loads` item, unresolved. DEBT-100 resolved `81c8936` (bench 20/20 green, unpushed). Served `agent-model-pretool.sh` re-synced from CCM (`eaa279f`). Pilot's `consult-check-*.sh` are byte-identical to the shipped asset (its `d206e0a`) — the fork-prompt watch-out from the prior carry is void.

## Next step

1. Push `81c8936` (DEBT-100) — pending the user's yes.
2. Pilot repo (one downstream order): `/super-bootstrap:harness-bootstrap` sync on 2.41.1, then migrate its author-moved cards per DEBT-088 → here: delete `docs/work/GAP-064.md` + OUT-001 via `/super-bootstrap:commit` (card-lifecycle exemption). Then this carry clears.
3. Contributed to CCM inbox (2026-08-27): `plugin-version-resolution-user-scope-loads` + `harness-audit-pretool-harness-paths-from-toplevel` — triage is CCM-side (`/digest-inbox`); until (b) lands, a commit staging `plugins/*/shared/*` from this subdir-launched session raises a false "audit stale" nudge.
4. Try a session launched from the repo root to see whether the `super-bootstrap:*` skill listing recovers there.

## Watch-outs

- PUBLIC repo; consumer specifics stay out of docs/tests/cards.
- Harness commits: audit → `git add` → `harness-audit-pretool.sh --stamp` → `git commit`, three separate calls; run the stamp from the repo root and expect the `shared/` mismatch above until (3b) lands; never stage `__pycache__`.
- `render-board.py` changes must keep `bench/todo-board/` goldens green (`bash bench/todo-board/run.sh`, 20 cases).
