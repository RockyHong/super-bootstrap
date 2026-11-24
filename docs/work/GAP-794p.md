# GAP-794p — Card capture lets an unconfirmed scope and unsourced external facts in

**Logged:** 2026-11-24 · **Source:** device note from `magnetized-remake`, 2026-11-21 — a card logged straight from a research playbook's output
**Problem:** The card's scope (iOS + Steam review prompts) was wider than the author's own picture (iOS only), and nobody confirmed it at capture. The card restated platform rules with no source link, so later sessions read them as settled; one was wrong (Steam forbids in-game review asks). A later source check over the same playbook's other cards found 1 falsified, 7 partly right and 3 unsourced claims out of 29. The session also skipped triage because the author called the card "simple to discuss" — triage's premise verify is the step that would have caught it.
**Area:** `plugins/super-bootstrap/skills/log/SKILL.md`; the card contract `harness-bootstrap` seeds into a consumer's `docs/work/README.md` (and this repo's own copy); possibly `skills/triage/SKILL.md` or the doctrine `assets/harness.md`
**Prior:** Note's proposal — (a) an external fact a card restates carries its source link or is marked `unverified`, so triage's premise check knows which lines to ground; (b) a card logged from an agent's or playbook's output states its scope in one line the author confirms at capture, a batch in one ask; (c) state that "simple" describes the build, not the premises.

## Progress — 2026-11-24

- (b) shipped: `log` step 5 marks a scope drawn from an agent's, playbook's or report's output `(scope per {source}, unconfirmed)`. RED on a playbook-report scenario, 3 control vs 3 treatment (Sonnet): scope marked 0/3 → 3/3.
- (a) closed, not shipped: the same RED never went red on external facts — 3/3 controls already flagged the report's platform rules and figure as unsourced/unverified. Row in `docs/decisions.md`.
- (c) open: state that "simple" sizes the build, not the premises, so a card whose premises are external claims still takes triage. Candidate homes: the doctrine asset `harness-bootstrap/assets/harness.md` § Sizing (re-placed to `.claude/rules/harness.md`), or `skills/triage/SKILL.md`. Needs its own RED: a cold session handed a "simple to discuss" card with unsourced external claims — does it pick up without triage?
