# BUG-7nrd — commit-channel `_re` misses `then`-prefixed, `bash -c`-wrapped and `git.exe` commits

**Logged:** 2026-11-24 · **Source:** device note from `rocky-personal-assist` (harness audit on plugin 7.0.5), 2026-11-21 — static reasoning, regex not run
**Problem:** `commit-channel.sh` v8's `_re` treats only positions after `;`, `&`, `|` and a newline as a command start, so three forms reach `git commit` unblocked: `if x; then git commit …` (`then ` is not a separator), `bash -c "git commit"`, and `git.exe commit`. None of the three is in the header's accepted-residual list (L42-47), so a subagent can bypass the commit channel through them.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.sh`, `tests/commit-channel.test.sh`, the placed copy under `.claude/hooks/`
**Prior:** Reproduce each form first; then widen `_re` or list the form as an accepted residual.
