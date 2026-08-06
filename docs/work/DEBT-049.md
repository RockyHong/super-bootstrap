# DEBT-049 — shared/ doctrine escapes the harness-audit gate; add .claude/harness-paths declaration

**Logged:** 2026-08-06 · **Source:** GitHub issue #29 (https://github.com/RockyHong/super-bootstrap/issues/29)
**Problem:** `plugins/super-bootstrap/shared/classify-actionable.md` is doctrine both the `todo` and `drain` agents read, but commits touching it carry no harness-audit stamp — the gate's path predicate covers the plugin-format directories (`skills` / `agents` / `rules`) and `shared/` is a repo-chosen name that falls through. `plugins/*/skills/**` and `plugins/*/agents/**` stamp fine, isolating the gap to the `shared/` segment.
**Area:** repo root `.claude/harness-paths` (new file); `plugins/super-bootstrap/shared/`
**Prior:** the gate reads a per-project declaration — add `.claude/harness-paths` at the repo root with `plugins/*/shared/*` (one glob per line, repo-root-relative, `#`/blank skipped). Verify: stage a file under `plugins/super-bootstrap/shared/`, re-run the stamp — it should stamp instead of reporting no gated harness path.
