# Plan: docsync-gate B′ (spec: 2026-07-07-docsync-gate-bprime-design.md)

Temporal — delete after merge.

- [x] 1. Red: `tests/docsync-hooks.test.sh` written, run captured red (8 fail / 5 pass against v1/v2 hooks)
- [x] 2. Build A (dispatch): hook assets — `docsync-scan.sh` v2 self-stamp, `docsync-gate.sh` v3 (TTL 30min + session-key + worktree pass), delete `docsync-stamp.sh` + `docsync-stamp.hook.json`, `hooks-ensure-infra.md` retired-hooks step, sync live install (`.claude/hooks/`, `.claude/settings.json` stamp entry removal)
- [x] 3. Build B (dispatch, parallel with A): prose propagation — harness-bootstrap SKILL.md § 2a-hooks, commit SKILL.md §3 (v3 contract + GAP-010 FROZEN-marker branch) + rules restatement, release-init SKILL.md step 9 + assets/template.md scan-first, this repo's `.claude/skills/release/SKILL.md` scan-first
- [x] 4. L1 green: 13/13 (gateway-verified rerun)
- [x] 5. L2: headless `claude -p` scratch-repo script committed (`tests/docsync-hooks-e2e.sh`); ran once — 2/2 (deny bare commit, pass scan-first)
- [x] 6. `audit-harness-edits` cold pass — 8 findings, all applied (incl. worktree scope-narrow to `.claude/worktrees/`, live session_id identity verification); L1 re-run 14/14; state stamped
- [x] 7. Doc-sync: both README hook rows updated, plugin.json verified current; backlog — BUG-009/GAP-011/GAP-010 deleted, gate-value metric appended to GAP-003
- [ ] 8. Commit via `/super-bootstrap:commit`; L3 (fresh-session `/release`) carried to next session
