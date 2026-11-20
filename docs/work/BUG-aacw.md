# BUG-aacw — SessionStart runway hook reports a version pair from a stale source

**Logged:** 2026-11-20 · **Source:** device note from ComfyUI `workflows/agent` repo (harness-bootstrap 7.0.0 legacy → split migration, then regular sync), 2026-11-19
**Problem:** The SessionStart runway hook reported "runway stamped v5.10.1 < plugin v5.10.6" while the installed plugin cache was 7.0.0 — the plugin-side version it reads is stale.
**Area:** `plugins/super-bootstrap/hooks/` runway-version hook
**Prior:** Hook resolves the plugin version from an old cache dir or a pinned path rather than the active install.
