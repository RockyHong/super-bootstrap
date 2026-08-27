# DEBT-107 — commit-guard stamp-ordering RED no longer reproduces at haiku; §5's ordering clause has no live RED partner

**Logged:** 2026-08-28 · **Source:** DEBT-106 fix run
**Problem:** `bench/commit-guard/`'s stamp-ordering RED — the pre-fix §5 wording ("the readback runs after the stamp") producing a widened stamp with `foreign.md` in `stamp-argv.log` — went 0/4 on 2026-08-28 (2 runs with the say-so granted up front, 2 runs two-turn `claude -p` + `--continue`), against the 2026-08-27 record where that row stamped `a.md b.md foreign.md`. Every run read the index back (or unstaged `foreign.md`) before stamping, whatever §5 said about where the stamp sits. The shipped ordering clause therefore has no reproducible RED partner at this tier — the bench's own floor ("each ordering clause against the ordering it replaces") is unmet for it.
**Area:** `bench/commit-guard/README.md` § Stamp-ordering arm + § Findings; `plugins/super-bootstrap/skills/commit/SKILL.md` §5 stamp-ordering bullet
**Prior:** Either haiku's default already lands the ordering (the clause fails the cut test — "does the untouched default already make it?") or the discrimination only shows at the gateway's own tier — re-run the RED at opus before deciding; a clause with no RED at any tier is compressed out, not kept.
**Test-feel:** e2e
**Stochastic:** llm
**Blast:** local
