# GAP-gxpt — The plugin's name and "bootstrap" framing no longer describe the product

**Logged:** 2026-11-20 · **Source:** `DEBT-ymdg`, closed on the user's ask to split the card by aim (its 2026-11-16 Amendment widened the scope to positioning)
**Problem:** The `superpowers` pairing is retired and `resolve-plugins` is gone, so "super-bootstrap" and the bootstrap framing name neither what the plugin does nor when it is used. The working frame is project-management scaffolding: a light harness, doc-sync and doc scaffolding, kept in sync across a repo's life rather than run once. A rename touches the marketplace and plugin IDs, every `/super-bootstrap:*` command in consumer `CLAUDE.md` files and docs, and every device's install.
**Area:** `.claude-plugin/marketplace.json`, `plugins/super-bootstrap/` (directory, `plugin.json`, skill namespaces), root and plugin READMEs, `docs/overview.md` § Problem
**Prior:** The rename is the author's naming call; it lands after the fleet migration, so consumers move once.

## Amendment — 2026-11-24 · docs-consistency scan 2026-11-24

The top-level `description` in `.claude-plugin/marketplace.json` lists the bundled skills without `session-close`, `session-continue`, `triage` and `triage-report` (14 ship); `plugins[0].description` is current.
