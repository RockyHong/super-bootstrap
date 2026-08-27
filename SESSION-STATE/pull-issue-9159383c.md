# Carry — pull-issue → doc-links fixes (2026-08-28)

**Anchor:** drain the open card set, then ship one release.

**Read first:** `/super-bootstrap:todo` (board); cards `docs/work/BUG-052.md`, `docs/work/DEBT-106.md`, `docs/work/BUG-054.md`.

**State:** #55 → BUG-053 fixed (`7f86cbb`), BUG-051 fixed (`d0b57e1`), BUG-054 logged — all pushed. Tree clean. Nothing in-flight; no Plan/Progress blocks open. Plugin still at 2.42.2 — both fixes unreleased by choice.

**Next step:** BUG-052 (harness deliberate: `load-harness-principles` pre, RED micro-test, cold audit) → DEBT-106 (bench e2e, `Stochastic: llm`) → BUG-054 (judgment: does the `refs` citer lane exclude card threads like `hits` now does — if yes, `doc-links.sh` header line "`refs` and `check` still cover them" flips to `check` alone). **Then `/release`** — user wants one release after the remaining cards, not per fix.

**Watch-outs:** Bash tool on this device collapses `\\` → `\` in command text (sed RHS `\\134` arrived as `\134`); for backslashes in shell edits use the Edit tool or octal `\134`. Cross-awk check = Docker `debian:bullseye-slim` + original-awk/mawk/gawk (script shape in `docs/techstack.md` § Portable-awk); Docker Desktop must be started first.
