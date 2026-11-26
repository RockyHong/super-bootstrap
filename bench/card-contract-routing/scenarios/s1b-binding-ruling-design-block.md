The repo's files (paths only, except the two shown whole below): `README.md`, `docs/overview.md`, `docs/specs/cli.md`, `docs/work/README.md`, `docs/work/TEMPLATE.md`, `docs/work/GAP-31.md`, `docs/work/GAP-32.md`, `docs/work/GAP-33.md`, `src/cli/main.py`, `src/cli/export.py`.

=== docs/specs/cli.md ===
# CLI

The `tool` binary dispatches subcommands from `src/cli/main.py`; each subcommand is one module under `src/cli/`.

## Subcommands

- `tool sync` — pull remote state into the local cache.
- `tool status` — print cache freshness.

=== docs/work/GAP-31.md ===
# GAP-31 — Add an export subcommand

**Logged:** 2026-11-10 · **Source:** user request
**Problem:** There is no way to dump the cache to a file; users copy it by hand.
**Area:** `src/cli/`

## Verdict — surface · 2026-11-11

### Decision needed
Name the new subcommand `export`, `dump`, or `cache-export`. GAP-32 (`tool prune`) and GAP-33 (`tool doctor`) add subcommands next and will face the same naming question.

=== task ===
The user just ruled on GAP-31's open fork: "Every subcommand name is a single plain verb, no hyphens, no noun prefix — this one is `tool export`, and GAP-32, GAP-33 and every later subcommand follow the same rule." Append the Design block for this ruling to GAP-31, following the card contract above.
