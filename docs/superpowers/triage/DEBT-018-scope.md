# DEBT-018 — reconcile shipped claude-md-skeleton.md to the dogfood root (§ Dispatch, § Doc Sync)

> **Baked this session** — surfaced during the DEBT-013 RED-probe (the shipped skeleton was missing the transcription carve-out; the transcription line itself was synced this session, this is the residual lag). Not independently cold-triaged; scope below is a first pass — pickup refines per-delta, does not re-discover.

## Findings

- **Root cause:** the shipped skeleton (`harness-bootstrap/assets/claude-md-skeleton.md`) is the seed for downstream repos, but its § Dispatch + § Doc Sync were not kept in sync as the dogfood root `CLAUDE.md` evolved. The dogfood root is the ahead-SSOT.
- **Observed deltas (skeleton behind root):**
  - § Doc Sync — skeleton narrates doc-sync as a **separately dispatched cold read** (`agents/commit.md` old model); the root runs it **in-process in the commit door**.
  - § Dispatch — skeleton lacks the **SDD carve-out** (subagent implements+reports, gateway commits) and the **create-new-file-foreground** rule.
  - (The transcription carve-out is already synced — added to both surfaces this session.)
- **Downstream impact:** repos scaffolded from the skeleton get stale dispatch / doc-sync doctrine.

## Verdict: auto-fix once scoped

- **Fix-shape:** mechanical reconciliation — port each dogfood evolution the skeleton lacks, **per-delta verifying it is shipped-behavior (propagate) vs dogfood-specific (skip)**. The in-process doc-sync model and SDD carve-out describe shipped `/super-bootstrap:commit` behavior → propagate. Anything referencing dogfood-only paths (e.g. `docs/specs/superpowers-topology.md`) → adapt or skip (shipped skeletons must be self-contained, per `repo-boundary.md`).
- **Probe-deps:** none — pure prose reconciliation, no runtime surface.
- **Execution:** `phased` — one pass over § Dispatch, one over § Doc Sync; verify the shipped-vs-dogfood-specific call on each delta.
