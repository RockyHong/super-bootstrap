2026-11-19
# Session carry — DEBT-ymdg

**Anchor:** Whole-pipeline review of the plugin's positioning; retire, restructure, migrate.
**Read first:** `docs/work/DEBT-ymdg.md` — the latest Verdict, Design, Plan and Progress; then `bench/carrier-equivalence/README.md`.
**State:** Both retires landed (`1a1c999`, `facbe99`) and their cards are resolved. The carrier-equivalence bench is built (`82c79a0`); its first 20-run round is invalid — the outdir sat under Claude Code's temp tree and no run loaded a project instruction file.
**Next step:** Re-run the round with the outdir outside `%TEMP%/claude/` (`bash bench/carrier-equivalence/run-round.sh <outdir>`, 20 headless runs, sonnet), on the author's go. A pass opens the ownership split.
**Watch-outs:** Check the `claudemd`/`main` rows read `loaded 1` before trusting a round.
