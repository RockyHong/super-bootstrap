# BUG-kbq7 — Rot scan: `/super-bootstrap` rename row false-hits every namespaced form, and a failing grep reads as a clean scan

**Logged:** 2026-11-20 · **Source:** device note from ComfyUI `workflows/agent` repo (harness-bootstrap 7.0.0 legacy → split migration, then regular sync), 2026-11-19
**Problem:** (1) The rename-map row `/super-bootstrap` → `/super-bootstrap:setup` matches every namespaced form (`/super-bootstrap:log`, `:commit`, …) under whole-token matching, since `:` is a word boundary — 11 false hits in one repo. (2) The rot scan has no shipped instrument: on Windows Git Bash `grep -P` fails ("supports only unibyte and UTF-8 locales") per literal, the loop printed nothing, and the run read as a clean 0-row scan. The "no rot scan" guard catches zero literals read, not a grep that errors per literal.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/` rename map + rot-scan step
**Prior:** Exclude a following `:` for that row (end-of-token / whitespace); ship a bundled scanner script (doc-links.sh mould) that fails loudly.
