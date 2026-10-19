# BUG-szkd — merge/autorun route conflict resolution to an agent the runway's commit-channel hook forbids from concluding

**Logged:** 2026-10-20 · **Source:** device note from `magnetized-remake` (D:/Git/Games/Magnetized Remake, runway 5.2.0), 2026-10-17
**Problem:** `merge` aborts on conflict and routes resolution to "a conflict-resolution agent". The runway's own `harness-bootstrap/assets/hooks/commit-channel.sh` denies raw `git commit` from subagents, and a merge conclusion is a commit, so the resolver subagent stopped at a staged merge every time: gateway commits, gateway ff's, resume the subagent — 4 round trips for 4 branches, each re-reading context. The routing as written collides with the runway's hook.
**Area:** `plugins/super-bootstrap/skills/merge/SKILL.md` conflict routing; autorun's conflict routing; `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.sh`
**Prior:** State the resolver contract wherever resolution routes to an agent: the agent leaves the merge staged, the gateway concludes it. Related: GAP-0cf5.
