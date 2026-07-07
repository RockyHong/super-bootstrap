# Bench Decontamination — Score Only Fixture Runs

When measuring Claude behavior with headless (`claude -p`) A/B runs, the run
environment leaks answers unless decontaminated. Two measured channels:

1. **Recent-commits leak** — the headless system prompt embeds a recent-commits
   block; probes modeled on a window's lived misses get answered from the fix
   commits' log excerpt.
2. **Ambient self-description** — the repo's CLAUDE.md + rules index catalogs
   the very surface under test densely enough for cold one-shot keyed reads.

Either channel saturates the baseline — an in-repo run cannot distinguish a
working mechanism from leaked context.

## Checklist

- **Score only fixture runs.** Runs cwd'd in the repo that authored the probes
  are structurally contaminated, not noisy — archive them unscored.
- **Build a consumer-shaped fixture** — generic CLAUDE.md, neutral git history,
  only the artifacts the distribution target would have.
- **Reset the fixture per run** (revert tracked files + clean untracked) —
  task-doing probes leak written files across runs.
