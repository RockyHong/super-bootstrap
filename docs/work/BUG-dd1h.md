# BUG-dd1h — "context heavy" has no measurable condition and reads as a stop trigger

**Logged:** 2026-11-03 · **Source:** device note from the ComfyUI `user/default/workflows/agent` repo (2026-10-30, plugin 5.7.0); surfaces checked against this repo at capture
**Problem:** At about 258K tokens, on the same card and the same settled Design, the model twice proposed parking the session "because the context is already heavy". User: "'這次對話的 context 已經很重了' 誰說的?你的準則在哪裡?現在258K 但你其他session 500k照跑". "Heavy" has no measurable condition, so the model invents a token threshold and reads it as a stop or hand-off trigger. That contradicts the platform rule: context is auto-summarized, and work need not wrap up early.

Surfaces carrying the wording: `claude-md-skeleton.md:102` (§ Context Hygiene, "context weight", "Compact while warm"), `:106` and `:108` (§ Finding Triage, "context budget (is the window heavy?)", "Context heavy"); dogfood `CLAUDE.md:103,107,109`; `session-close/SKILL.md:63,65` ("context to spare", "context heavy").

Note's wording direction: a session boundary keys on a topic shift or a finished unit of work, never on token count. Finding Triage's "context budget" means whether the finding's own investigation would pull large unrelated reads into this thread, not window size.

Related: GAP-cdrv edits the same line, `session-close/SKILL.md:65`.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md` § Context Hygiene · § Finding Triage, root `CLAUDE.md` same sections, `plugins/super-bootstrap/skills/session-close/SKILL.md` step 3
**Prior:** The axis was written as a window-size proxy for "this finding won't fit here" and never named the measurable thing.
