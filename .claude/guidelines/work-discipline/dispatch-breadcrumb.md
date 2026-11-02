# Dispatch Breadcrumb — What Rides the Prompt

A subagent dispatch prompt carries the entry doc for its scope — the breadcrumb
head the agent reads first (the scope's index, overview, or SSOT entry point).
Project context is the caller's responsibility (skill-authoring axiom); the
entry doc is the minimum unit of that responsibility.

- **Name a path, not a topic** — "read `docs/architecture.md` § Hook
  Distribution first" beats "familiarize yourself with the hook system."
- **Entry point, not payload** — pass the breadcrumb head and let the agent
  pull; inline only what the agent cannot discover from it.
- **Cheaper tiers under-read most** — the colder the dispatched tier, the more
  a missing breadcrumb costs. Never assume a subagent infers the reading list.

Beside the entry doc, the prompt carries:

- **The user's load-bearing words, verbatim — the gloss marked as gloss.** The
  receiver reads the whole brief as the request, so a paraphrase becomes its
  spec. Quote the words the work turns on — the ask, a constraint, a taste
  call, a correction — as the user gave them, in the user's language, and
  label the interpretation or plan added around them as the dispatcher's own.
  The receiver then builds to the quote and reports where the gloss parts
  from it.
- **An output file the receiver can write** — a subagent's `Write` is refused
  when the basename starts with `REPORT`, `SUMMARY`, `FINDINGS` or `ANALYSIS`
  and ends `.md`, any case. A brief that names an output file picks a basename
  off those prefixes, or asks for the text back and persists it from the
  dispatcher. Mechanism (device-planted):
  `~/.claude/guidelines/claude-shape/subagent-write-gate.md`.
- **Plain commands for a worktree-isolated subagent** — a brief dispatching
  one tells it to keep commands plain: literal paths, at most one leading
  `cd`, file bodies through `Write` / `Edit`, git from the worktree root. Fact
  (device-planted):
  `~/.claude/guidelines/claude-shape/worktree-isolation.md` § Worktree git guard.

Family catalog: [`index.md`](index.md).
