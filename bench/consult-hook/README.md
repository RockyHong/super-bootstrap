# consult-hook bench — test surface for the shipped consult-check pair

Measurement provenance for the frozen assets at
`plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/consult-check-{check,sessionstart}.sh`.
super-bootstrap is the SSOT of the hook pair; this directory is the bench that
selected its shape — any edit to the frozen forced-eval sentence or the catalog
contract re-runs here first.

- `FINDINGS-gap045.md` — the forced-eval build: arms, pre-registered gates, the
  measured sentence the check hook injects verbatim.
- `FINDINGS.md` + `arm-{baseline,pointer,prodbundle,v1,v2-oracle}.json` — the
  earlier arm sweep whose failures ground the check hook's header constraints
  (ignorable-pointer, map routing, TN pre-classifier).
- `*-inject.sh`, `run*.sh`, `score-gap045.sh`, `probes*.jsonl`, `doc-map.tsv`,
  `make-fixture.sh`, `bench-decontamination.md` — arms, harnesses, probes, fixture.

Raw run transcripts (`runs/`, `runs-gap045/`, ~3.5 MB of JSONL) were not
migrated — they remain in the claude-config-manager repo's git history, where
this bench lived before the SSOT transfer.
