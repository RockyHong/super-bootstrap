# BUG-bqc8 — Language-server pin overrides a user-scope `false` and re-inserts after a decline

**Logged:** 2026-11-20 · **Source:** device note from ComfyUI `workflows/agent` repo (harness-bootstrap 7.0.0 legacy → split migration, then regular sync), 2026-11-19
**Problem:** techstack names Node.js → the sync inserts `typescript-lsp@claude-plugins-official: true` at project scope, but the user's `~/.claude/settings.json` sets that key `false` and enables `typescript-lsp-win@local` (Windows variant). The project `true` overrides the deliberate user choice. A declined pin is not carried like a declined drift row — the next run re-inserts it.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` language-server pin step
**Prior:** Skip a key the user scope sets `false` (or one a same-language variant covers); carry a declined pin across runs.
