# DEBT-119 — consult-check hook demands a per-doc YES/NO enumeration nothing checks (prompt-audit M7)

**Logged:** 2026-09-24 · **Source:** `/claude-api prompt-audit` over `plugins/super-bootstrap/**` (reader: downstream session model on every prompt, assumed `claude-opus-5-5`); unverified at capture
**Problem:** `skills/harness-bootstrap/assets/hooks/consult-check-check.sh:37` emits "evaluate EACH doc below and state YES or NO". The file's own header (lines 14-18) accepts that sessions skip the enumeration and calls the stated output cosmetic — recall is the metric. An output demand known to be violated carries no signal; on always-thinking models, asking the model to restate its evaluation in the reply is also the pattern the migration guidance flags. The measured bench arm (`bench/consult-hook`) ran on the Sonnet tier; the Opus arm showed no under-read to fix. The header forbids editing the measured sentence without measurement.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/consult-check-check.sh` (frozen v1), dogfood `.claude/hooks/consult-check-check.sh`, `harness-bootstrap/SKILL.md:278`, `bench/consult-hook/`
**Prior:** Candidate wording keeps the forced-evaluation moment and drops the output demand ("judge which docs below bear on this prompt and Read each one that does; if none does, answer directly"); gate it on a `bench/consult-hook` re-run (recall + TN) on an Opus 5.5 session; closure = header v2, byte-identical dogfood refresh, `SKILL.md:278` wording.

## Verdict — surface · 2026-09-24

### Findings

- root cause: premise verified against current code. `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/consult-check-check.sh:37` emits "evaluate EACH doc below and state YES or NO … Read every YES doc before composing your answer." Header lines 14-18 accept that sessions skip the stated enumeration ("the stated output is cosmetic … recall is the success metric"). Dogfood `.claude/hooks/consult-check-check.sh` is byte-identical (`diff` clean, same `# FROZEN consult-check-check v1` marker). Tier claim holds: the build-selecting bench (`bench/consult-hook/FINDINGS-gap045.md` header: "**Tier:** sonnet"; `run-gap045.sh:37` `claude --model sonnet`) is where the sentence was measured. The earlier opus run (`bench/consult-hook/FINDINGS.md:3,101`) showed no under-read to fix. The card's "migration guidance" claim (restated evaluation on always-thinking models) is an external fact this read cannot verify. It is not load-bearing: the no-signal argument stands on the header alone.
- aim: no overlapping open card (grep `docs/work/` for consult-check / forced-eval / YES-NO → only this card). No closed fork re-walked: `docs/decisions.md:58` settles absorb-the-hook, not the sentence. The binding constraint is in `FINDINGS-gap045.md` § Build shipped / source-scope revision: "The re-run condition below still holds for a change to the **injector** or the forced-eval sentences." So any wording change is measurement-gated by the repo's own SSOT, as the card's Prior already says.
- scope reach (closure if the change ships):
  - `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/consult-check-check.sh`: line 37 sentence, marker `v1`→`v2`, header lines 4-5 / 9 / 14-18 / 28 ("forced YES/NO-per-doc", "stays verbatim", known-non-compliance paragraph).
  - `.claude/hooks/consult-check-check.sh`: byte-identical refresh (own asset, sb provenance, not an import).
  - `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:278`: "forced YES/NO-per-doc relevance evaluation" wording.
  - `bench/consult-hook/FINDINGS-gap045.md`: new revision section recording the re-measured sentence (it is the measured sentence's home).
  - `bench/consult-hook/README.md:9-10`: "the measured sentence the check hook injects verbatim".
  - **Not named on the card:** `docs/parked.md:31`. Stage (2) of that parked item's recipe reads "the model's stated YES set" from session JSONL, so it is a downstream consumer of the exact output this card drops. Dropping the demand removes that read-out input, and stage (2) must re-key onto Read events alone.
  - Consumer propagation: `hooks-ensure-infra.md` copy-on-drift (lines 71-145) re-places a never-edited v1 script silently. The new sentence reaches every downstream repo on its next runway sync, so a regression would ship fleet-wide.
  - Frozen fixture snapshots under `bench/doc-sync/.fixtures/**` are out of closure.
- probes: no `§ Probes` table in `docs/techstack.md`, so none were fired.
- attempted: full static read of the hook, its dogfood copy, both FINDINGS, the runner, decisions, parked. I stopped at the measurement gate. This read-only lane cannot run the bench, and the run costs headless-session spend.

### Decision needed

- Should the forced-eval sentence drop its per-doc YES/NO output demand? The measured forced-evaluation moment stays. This decides whether the frozen, measured injector sentence gets re-measured and rewritten.
- options:
  - (a) Build the candidate arm and re-run the GAP-045 harness. The candidate wording is from the card's Prior: "judge which docs below bear on this prompt and Read each one that does; if none does, answer directly". Ship v2 only on recall/TN parity with forcedeval-compact. Closure is as listed above, including `docs/parked.md:31` re-keyed to Read events.
  - (b) Close without change. The cosmetic output costs a few tokens per reply. The stated YES set is a live read-out input for the parked graph-pruning recipe. Record the road-not-taken in `docs/decisions.md` and delete the card.
- recommendation: (a), gated on **both tiers**, not the Prior's Opus-only gate. The hook ships to every consumer regardless of the session model. The measured under-read (baseline 67%) lives on sonnet, and the Opus arm had no under-read, so an Opus-only gate cannot detect a recall regression. Pass = forced-eval recall 18/18 and TN 12/12 on sonnet ×2 replicates, plus no Opus regression. That matches the pre-registered gates the current sentence passed.
- settles by: `phased build`. Add `bench/consult-hook/forcedeval-v2-inject.sh` + `arm-forcedeval-v2.json` beside `forcedeval-compact-inject.sh`, parametrize the runner's `--model`, run in the decontaminated fixture (`make-fixture.sh`; never in-repo, per FINDINGS-gap045 caveat 4), then score with the blind judge. The run spend needs the user's consent (budget authority: 15 probes × 2 reps × 2 tiers of headless `claude -p`). No GPU involved.
