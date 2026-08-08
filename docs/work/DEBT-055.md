# DEBT-055 — dogfood runway stale: stamp 2.25.0 vs plugin 2.29.7, resync owed

**Logged:** 2026-08-08 · **Source:** session-close detect (change B resolution session)
**Problem:** This repo's own bootstrapped runway is behind its shipped plugin: `.claude/super-bootstrap-runway.json` stamps `2.25.0` while `plugins/super-bootstrap/.claude-plugin/plugin.json` is `2.29.7`. Skeleton sections and infra added between those versions are missing from the dogfood harness until a sync runs.
**Area:** `.claude/super-bootstrap-runway.json`; runway surfaces `harness-bootstrap` Phase 2b syncs (root `CLAUDE.md`, skeleton docs, rules, hooks)
**Prior:** Re-run `/super-bootstrap:harness-bootstrap` — sync mode's stale-stamp guard forces the full Phase 2b drift check, preserving local edits while backfilling skeleton additions.
