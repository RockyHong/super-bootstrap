# DEBT-2bx1 — `session-close-moves` `harness` fixture lets a run judge the drafted rule line a duplicate

**Logged:** 2026-11-09 · **Source:** BUG-pffk regression runs (commit `16616ce`), session-close of the same session
**Problem:** In `bench/session-close-moves`, scenario `harness`, 1 of 3 arm runs on the final text detected no move at all. It judged the session's drafted line for `.claude/rules/maintenance.md` unneeded, because `config/cabinet.toml:1` already says "Read by the controller at boot", so it called the rule line a second copy of that fact. The run then failed (p1), (p11)–(p14) on an empty pick. The judgment is defensible, so the fixture's premise ("no other file states this fact") is ambiguous, and the scenario reads noise as a regression.
**Area:** `bench/session-close-moves/fixture/harness/`, `bench/session-close-moves/prompt-harness.txt`, `bench/session-close-moves/make-fixture.sh`
**Prior:** Make the drafted fact one no fixture file states (e.g. the restart consequence alone, with the config comment carrying no timing), then re-run `harness` 3 times.

## Verdict — auto-fix · 2026-11-09

**Fix-shape:** mechanical
**Probe-deps:** none
**Execution:** phased(skip: design, plan) — depth: one comment line in one fixture file, no judgment left; closure: a scenario-local overlay plus one README fixture line, then a 3-run measurement that only a headless walk can produce

### Repro (pinned)

"In `bench/session-close-moves`, scenario `harness`, 1 of 3 arm runs on the final text detected no move at all. It judged the session's drafted line for `.claude/rules/maintenance.md` unneeded, because `config/cabinet.toml:1` already says "Read by the controller at boot", so it called the rule line a second copy of that fact. The run then failed (p1), (p11)–(p14) on an empty pick."

### Root cause (verified)

premise age: clean — no commit touched `bench/session-close-moves/` since 2026-11-09 (last: `16616ce`, the run the card's Source names). The failed run's output is not kept in the repo; the card's capture is the observation, and the fixture text below confirms its mechanism.

- `bench/session-close-moves/prompt-harness.txt:5-6` drafts `The controller reads config/cabinet.toml only at boot, so a changed value takes effect after the next restart.` and asserts "No other file states this fact, so the line is the whole edit."
- `bench/session-close-moves/fixture/base/config/cabinet.toml:1` reads `# Read by the controller at boot. These values are what the cabinet does.` That comment states the read-at-boot half of the drafted fact, and the restart half follows from it. So the prompt's "No other file states this fact" is false against the fixture, and a run that reads the toml can defensibly drop the row as a duplicate. The premise contradicts the fixture; the run is not at fault.
- No other fixture file states the fact: a grep for `boot|restart` over `fixture/` hits only `cabinet.toml:1`. The rule `fixture/harness/.claude/rules/maintenance.md` states the interval-equality rule only.
- Card's Prior (keep the toml comment, narrow the drafted line to the restart consequence alone) does not close the gap: "at boot" in the comment still implies "after a restart", so the duplicate reading survives. The fix that does close it is to strip the timing from the comment. The drafted line stays as is, because (p12) at `score-pick.sh:131` greps the fix-now row for `restart` and `bite.sh:92` quotes the line verbatim. Changing the line would drag both.
- Scope it to the scenario rather than the base. `make-fixture.sh:24` overlays `fixture/harness/.` onto the base on `harness` and `cochange` with `cp -R`. A `fixture/harness/config/cabinet.toml` overlay with the comment `# Read by the controller. These values are what the cabinet does.` (keep its three value lines byte-identical) changes only those two scenarios. `full`/`fixnow`/`resolve`/`leak`/`single`/`large` keep the base fixture that their recorded readings rest on. On `cochange`, no prompt line or scorer reads the comment (`prompt-cochange.txt` has no `boot` hit; (p15)–(p17) key on the seal rule and the served skill). Editing the base comment instead also works but moves the fixture under every scenario's recorded reading. The overlay is the smaller closure.
- Family: `bench/session-close-judgment/fixture/base/config/cabinet.toml:1` carries the same comment. That bench is a separate copy (its own fixture, no shared path, no byte-identity claim), and no harness-rule scenario there drafts a boot-time line. It is out of scope and stays unchanged.

### Files (fix surface)

- `bench/session-close-moves/fixture/harness/config/cabinet.toml` (new) — overlay: base file with line 1 minus "at boot"
- `bench/session-close-moves/README.md:23-24` — the `fixture/harness/` bullet: add that it overrides `config/cabinet.toml` with a comment that names no read timing, so the drafted rule line is the only place that states it
- No change: `prompt-harness.txt`, `score-pick.sh`, `bite.sh`, `make-fixture.sh` (its header line for `harness` stays accurate as a summary; it may add "and a `config/cabinet.toml` with no read timing" for parity — optional)
- Provenance: all paths are native to this repo (no `.served` marker, not under `.claude/guidelines/`)

### Doc Impact

- `bench/session-close-moves/README.md` § Fixture — the bullet above. A result line for the 3 re-runs goes in that README's results prose, in the form the earlier rounds use.
- `docs/overview.md:48` (`session-close-moves/` gloss) — read; unchanged
- `docs/test-queue.md:43` — read; unchanged

### Test Strategy: e2e

Run `bash bench/session-close-moves/make-fixture.sh harness <dir>` and check that `<dir>/config/cabinet.toml:1` has no `boot` and that `grep -rn -i 'boot\|restart' <dir>` hits nothing outside `.git`. Then run `run.sh arm harness <dir>` 3 times (fresh dir each) and score with `score-pick.sh harness`. Pass = (p1), (p11)–(p14) on 3 of 3. A miss whose rows show the drafted line read as a duplicate means the premise is still ambiguous. A miss of another shape is the variance the README's last regression paragraph already names, not this card. `bite.sh` needs no re-run: no assertion changes.
