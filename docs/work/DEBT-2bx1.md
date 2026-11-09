# DEBT-2bx1 — `session-close-moves` `harness` fixture lets a run judge the drafted rule line a duplicate

**Logged:** 2026-11-09 · **Source:** BUG-pffk regression runs (commit `16616ce`), session-close of the same session
**Problem:** In `bench/session-close-moves`, scenario `harness`, 1 of 3 arm runs on the final text detected no move at all. It judged the session's drafted line for `.claude/rules/maintenance.md` unneeded, because `config/cabinet.toml:1` already says "Read by the controller at boot", so it called the rule line a second copy of that fact. The run then failed (p1), (p11)–(p14) on an empty pick. The judgment is defensible, so the fixture's premise ("no other file states this fact") is ambiguous, and the scenario reads noise as a regression.
**Area:** `bench/session-close-moves/fixture/harness/`, `bench/session-close-moves/prompt-harness.txt`, `bench/session-close-moves/make-fixture.sh`
**Prior:** Make the drafted fact one no fixture file states (e.g. the restart consequence alone, with the config comment carrying no timing), then re-run `harness` 3 times.
