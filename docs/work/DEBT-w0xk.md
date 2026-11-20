# DEBT-w0xk — README root-pin drift row omits the CLAUDE.md § Rules line as co-change

**Logged:** 2026-11-20 · **Source:** device note from ComfyUI `workflows/agent` repo (harness-bootstrap 7.0.0 legacy → split migration, then regular sync), 2026-11-19
**Problem:** Root-pinning `/README.md` in ssot-doc-link / dimension-discipline drops nested READMEs (there `prompting/README.md`). `rule-paths-coverage.sh` caught it via `.claude/doc-surface`, but older installs' skeleton `CLAUDE.md` § Rules bullets still restate `README.md`; the drift row does not name that `CLAUDE.md` line as a co-change.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/` rule drift rows, `rule-paths-coverage.sh`
**Prior:** Drift row for the rule `paths:` change names the `CLAUDE.md` § Rules bullet as a co-change.
