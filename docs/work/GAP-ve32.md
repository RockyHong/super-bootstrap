# GAP-ve32 — autorun § Pick has only skip for a card whose deliverable is partly a harness file

**Logged:** 2026-10-20 · **Source:** device note from `jowagoko` (D:/Git/Podcast/jowagoko, autorun 5.2.0), 2026-10-20 run
**Problem:** § Pick skips any card whose deliverable is a harness file. In the run, most cards shipped scripts with a few incidental lines in `.claude/skills/<x>/references/*.md`; skipping all of them leaves autorun almost nothing to run.
**Area:** `plugins/super-bootstrap/skills/autorun/SKILL.md` § Pick / § Run; the autorun status sheet
**Prior:** Pattern that worked in the run (15 harness edits applied, audit found minor/nit only): admit the card with a brief forbidding `.claude/**` edits in the worktree; the worker appends a `## Plan` block with verbatim old → new per harness edit, keeps the card, writes status `DONE — harness edits pending on card {ID}`; after merge the gateway applies verbatim (each old string's occurrence count checked), runs `audit-harness-edits`, deletes the card, commits. Make it a formal branch plus a `DONE — harness pending` sheet row.
