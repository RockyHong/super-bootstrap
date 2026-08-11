# Bench Decontamination — Score Only Fixture Runs

When measuring Claude behavior with headless (`claude -p`) A/B runs, the run
environment leaks answers unless decontaminated. Three channels (first two
measured, third lived):

1. **Recent-commits leak** — the headless system prompt embeds a recent-commits
   block; probes modeled on a window's lived misses get answered from the fix
   commits' log excerpt.
2. **Ambient self-description** — the repo's CLAUDE.md + rules index catalogs
   the very surface under test densely enough for cold one-shot keyed reads.
3. **Device-hook bleed-through** — headless runs inherit `~/.claude` device
   hooks (arm settings replace project settings only), so the bench environment
   drifts as device hooks accumulate; their injections are unmeasured context
   the arms never controlled for.

The first two saturate the baseline — an in-repo run cannot distinguish a
working mechanism from leaked context. The third invalidates cross-date
comparison if the device-hook set changed between runs.

## Checklist

- **Score only fixture runs.** Runs cwd'd in the repo that authored the probes
  are structurally contaminated, not noisy — archive them unscored.
- **Build a consumer-shaped fixture** — generic CLAUDE.md, neutral git history,
  only the artifacts the distribution target would have.
- **Reset the fixture per run** (revert tracked files + clean untracked) —
  task-doing probes leak written files across runs.
- **Record the device-hook set alongside scored runs** — full isolation is not
  an option: blanking `$HOME` would sever the `~/.claude/guidelines` plant the
  fixture depends on along with the hooks; record-and-compare is the honest
  floor. Treat cross-date score deltas as suspect when the set changed.
