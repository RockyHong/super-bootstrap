# Dispatch Run Mode — Path Overlap Decides

A file-writing subagent dispatched in the background returns behind the
caller's read-tracker: it writes (and often commits, with formatter passes) in
its own context while the dispatching session keeps editing the same paths.
The caller's next Edit there carries an `old_string` built from the pre-write
file. The tool auto re-reads current disk content, but where the writer's change
removed that `old_string`, no re-read restores it. An orchestration-made stale
race, structural whenever writer and caller share paths.

- **Writer dispatches run foreground when the caller keeps working the
  writer's paths.** A short writer agent whose job is touching shared files —
  commit, log, merge class — dispatches `run_in_background: false` when the
  session will edit the paths it touches: the return sequences the caller's
  next edit instead of racing its read-tracker.
- **Path overlap is the criterion, not writer class.** A writer touching only
  paths the session is done with can stay background.
- **Long dispatches with no path overlap stay background** — blocking the
  session on a long build buys nothing when the session isn't editing the
  build's paths.

Siblings: [`dispatch-breadcrumb.md`](dispatch-breadcrumb.md) — what a brief
carries; [`dispatch-brief-shape.md`](dispatch-brief-shape.md) — how much; this
file — when the dispatch runs relative to the caller's own work.
