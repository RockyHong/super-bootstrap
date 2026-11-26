# Dispatch Prompt Carry — What the Receiver Cannot Recover

A subagent dispatch prompt carries what the receiver cannot recover
from the work in front of it:

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
- **A secret-file exclude for a repo search** — a brief that sends the
  receiver to search a repo tells it to keep `.env*` out of every recursive
  search that reads dotfiles: `grep -r --exclude='.env*'`,
  `rg --hidden -g '!.env*'` (plain `rg` skips dotfiles already),
  `Get-ChildItem -Recurse -Exclude '.env*' | Select-String`; a script the
  receiver writes skips `.env*` in its own file walk.

Family catalog: [`index.md`](index.md).
