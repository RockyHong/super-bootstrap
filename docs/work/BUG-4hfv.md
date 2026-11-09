# BUG-4hfv — session-continue auto-claimed a stale carry against the user's intent

**Logged:** 2026-11-09 · **Source:** device note from claude-config-manager harness-pain harvest (CCM `docs/harness-pain/reports/2026-11-09.md`, commit `5b87231`); installed plugin cache 5.9.0; model `claude-opus-5-5`
**Problem:** At session start in the ComfyUI-agent adopter repo, `session-continue` claimed the stale GAP-at49 carry and oriented on it. The user wanted the PE card series and had to re-anchor. Evidence: `~/.claude/projects/C--Users-User-Documents-ComfyUI-user-default-workflows-agent/42547892-cfa2-44d3-8eeb-abef16053fca.jsonl:111` ("nope，我要處理的是PE系列的卡片，greedy+most cost effective slm+ensure upstream config，昨天LTX有做完了?今天換其他模型?"). Open question: should a carry whose cited work looks finished or stale be offered instead of auto-claimed, or should the confirm-before-dive step name the carry's age and its card state?
**Area:** `plugins/super-bootstrap/skills/session-continue/SKILL.md`
**Prior:** —
