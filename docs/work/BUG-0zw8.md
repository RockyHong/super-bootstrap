# BUG-0zw8 — doc-links.sh volatile-ids flags prose `GAP-card` as a card ID

**Logged:** 2026-11-20 · **Source:** device note from ComfyUI `workflows/agent` repo (harness-bootstrap 7.0.0 legacy → split migration, then regular sync), 2026-11-19
**Problem:** The `volatile-ids` check flags the overview skeleton's prose "GAP-card pickup" as a card ID.
**Area:** `plugins/super-bootstrap/skills/commit/assets/doc-links.sh` volatile-ids; `harness-bootstrap/assets/overview-skeleton.md`
**Prior:** ID pattern accepts any letters after `GAP-`; require the suffix shape (digits or a 4-char random suffix not a dictionary word), or reword the skeleton.
