You are running `harness-bootstrap` on a repo. The governing instructions are quoted below,
then the facts Phase 1 read off the repo.

--- GOVERNING INSTRUCTIONS (Phase 1 § Existing CLAUDE.md, then § 2b) ---
{EXCERPT}
--- END INSTRUCTIONS ---

--- REPO FACTS ---
- `.claude/rules/harness.md` exists; its bytes equal the shipped `assets/harness.md`.
- `CLAUDE.md` exists and holds no owned heading.
- `.claude/super-bootstrap-runway.json` exists.
- `git log --oneline` prints one line: `a1b2c3d Initial commit`. The repo moved hosts last
  month and its history was imported as a single squashed commit.
- `docs/overview.md` line 12 carries a literal that `assets/rename-map.md` lists as `old`.
--- END FACTS ---

Answer in three lines, nothing else:

LINE 1 — the state Phase 1 reads: fresh, split or legacy.
LINE 2 — RUN or SKIP: does this run perform the § 2b rot scan?
LINE 3 — one sentence of justification.
