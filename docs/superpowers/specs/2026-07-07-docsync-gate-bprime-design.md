# Spec: docsync-gate B′ — de-syntax the enforcement, keep the deny

**Status:** approved (user, 2026-07-07 — "B′, outcome-driven, push to green, no per-section confirm")
**Bundle:** BUG-009 + GAP-011 + GAP-010 (+ two unlogged findings from transcript mining)
**Temporal:** delete after merge per `CLAUDE.md` § Doc Sync.

---

## 1. Problem + evidence (gathered 2026-07-07, do not re-derive)

All six defects in the gate's first 24h are one class — **enforcing a semantic invariant via command-string matching** (user's verbatim diagnosis: 「用語法比對強制語意不變式」):

| Defect | String-matching failure | Status |
|---|---|---|
| BUG-007 | deny text taught classifier to reject its own remedy | fixed `59abb4e` |
| chained-call deny | PreToolUse reads string pre-exec | correct behavior, unexplained in deny msg |
| stamp forgery hole | substring `*docsync-scan.sh*` — a `cat` would stamp | fixed pre-ship |
| stamp trailing-text fragility | `scan.sh 2>&1` silently fails to stamp | **open, unlogged** |
| GAP-011 | token has no lifetime semantics | **open** |
| BUG-009 | gate can't know a flow (release) is legitimate | **open** |

Plus two mining/archaeology findings:

- **`$CLAUDE_PROJECT_DIR` unset in agent-issued Bash calls** — the commit skill's prescribed `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/docsync-scan.sh"` hit exit 127 live. **Open, unlogged.**
- **Linked-worktree always-deny** — in a worktree, `.git` is a file; the token path can never exist → gate would deny every drain worktree commit (contradicts drain's documented free-commit contract). Latent, never fired.

**Value ledger:** zero organic catches in 24h (too early to condemn); 3 same-day fixes; each patch so far revealed the next mole.

## 2. Intent preserved (original design, `c1e2820` spec § A2)

Non-negotiable, all kept:

- **Deny-not-warn** — prevents the audit-after-commit inversion; warn re-creates the measured prose failure.
- **Un-forgeable by hand** — agent never touches the token; classifier-safe.
- **Scan provably ran before commit.**

Recovered original intent that implementation shed:

- Original spec said **"scan report present and newer than the staged diff"** — a *freshness* semantic. v1 simplified to bare existence; GAP-011 is that lost freshness. TTL restores it.
- Original division: **"the skill produces the artifact; the hook only checks."** The stamp hook (a BUG-007 patch) broke that division and introduced the fragile invocation-shape matching. Scan-self-stamp restores it.

**Jurisdiction constraint (user, 2026-07-07):** upstream plugin touches only the CC layer (`.claude/hooks/`, `settings.json` merge). Never the downstream repo's `.git/hooks/` singleton. (Closes the approach-B git-pre-commit fork — see decisions routing in § 8.)

## 3. Design

### Components after change (4 hook files → 2 + 2 grounding)

**`docsync-scan.sh` → FROZEN v2 (self-stamping):**
- Keeps: print changed-file surface (staged / unstaged / untracked), always exit 0.
- Adds: writes `.git/docsync-token` itself as an internal side-effect of executing, containing `$CLAUDE_CODE_SESSION_ID` (empty string if unset). Running the scan IS the proof — no invocation-shape matching anywhere.
- Path robustness: resolve repo root via `git rev-parse --show-toplevel` fallback when `$CLAUDE_PROJECT_DIR` unset (fixes the exit-127 finding). Token lands in the **main** `.git` dir (`git rev-parse --git-common-dir`).

**`docsync-gate.sh` → FROZEN v3 (TTL + session-key, worktree-aware):**
Order of checks on a `git commit` command:
1. Non-`git commit` command → pass (unchanged defense-in-depth; the one leg with a zero-failure record — accepted residue, confined).
2. Linked worktree (`git rev-parse --git-dir` ≠ `--git-common-dir`, or `.git` is a file) → **pass** (drain's free-commit contract preserved).
3. Token missing → deny.
4. Token stale (mtime older than **30 min**) → deny (distinct reason: stale, re-run scan).
5. Token session mismatch (token content non-empty AND stdin `session_id` non-empty AND unequal) → deny (distinct reason: other session's scan). Empty side(s) → skip this check (graceful degradation to TTL-only).
6. Pass → consume (delete token, one-shot).

Deny messages: route to `/super-bootstrap:commit` **or "run the doc-sync scan (`docsync-scan.sh` as its own Bash call), resolve findings, then commit"** — legitimizes non-commit-skill flows (release) and explains the scan-must-be-separate-call requirement. Never name a bare token command (BUG-007 lesson).

**`docsync-stamp.sh` + `docsync-stamp.hook.json` → DELETED.** The fragile leg exits structurally: forgery, trailing-text, mention-vs-invocation all cease to exist.

**`harness-grounding.*` — untouched.**

### Flow-level legitimacy (BUG-009, fixed at class level)

Any flow that runs the scan earns its commit. One line each:
- `release-init/assets/template.md` — generated `/release` step: scan → resolve findings → commit (systemic fix, every consumer).
- `release-init/SKILL.md` step 9 (its own commit of the generated skill) — scan-first.
- This repo's live `.claude/skills/release/SKILL.md` — same patch (it predates the template fix).
- `/super-bootstrap:commit` — semantics unchanged; §3 prose updated to the v3 contract (self-stamp, no stamp hook, TTL).

### Migration (already-bootstrapped repos)

`hooks-ensure-infra.md` gains a **retired-hooks** step: on re-sync, delete `docsync-stamp.sh` and remove its settings.json hook entry (match by script name). FROZEN marker compare handles the scan/gate upgrades as today (copy-on-drift, asset wins).

### GAP-010 (present-but-outdated detection)

Rides `/super-bootstrap:commit` §3's existing install-state branch — the one place that already checks at the moment it matters: compare installed hooks' `# FROZEN <name> vN` markers against the plugin's assets when locatable (plugin cache present); on mismatch **or** on detecting a retired `docsync-stamp.sh` still installed, halt-and-nudge to re-run `/super-bootstrap:harness-bootstrap`. Pull-only; no new SessionStart hook surface (consistent with the ambient-first closed fork).

### Harvest checkpoint

Gate value measurement (organic catches vs friction) joins GAP-003's measurement pass — one line appended to that backlog row. Drop-the-gate stays a future evidence call.

## 4. Test plan

- **L1 unit (zero session dependency, red-first):** `tests/docsync-hooks.test.sh` (repo-level, not shipped in plugin dir). Pipes fake hook-input JSON; forges mtime via `touch -d`. Cases: gate deny on missing/stale/mismatched token; pass+consume on fresh+matching; worktree pass-through; non-commit pass-through; scan self-stamps token with session id; scan works with `CLAUDE_PROJECT_DIR` unset; env `CLAUDE_CODE_SESSION_ID` ↔ stdin `session_id` identity probe.
- **L2 headless e2e (auto fresh sessions):** scratch repo + `claude -p` (drain precedent): bare commit → deny; scan-then-commit → pass. Run once if feasible this session; script committed regardless.
- **L3 in-repo dogfood (needs one fresh session):** settings snapshot at session start → stamp-entry removal verified next session. Terminal acceptance: the pending v2.17.0+ `/release` of this repo ships through the live gate.

## 5. Acceptance

1. L1 green (all cases).
2. `audit-harness-edits` cold pass on the diff, findings dispositioned.
3. Backlog: BUG-009, GAP-011, GAP-010 rows deleted; two unlogged findings covered by this diff (no rows needed); GAP-003 row gains the gate-value metric line.
4. Doc-sync closure: hooks-ensure-infra, harness-bootstrap SKILL.md § 2a-hooks table, commit SKILL.md §3 + rules restatement, release-init SKILL.md + template, README `.claude/hooks/` row, plugin.json description (hook count/wording) — all consistent with v3 contract.
5. L3 deferred: next session runs `/release` live (BUG-009's acceptance) — carried as the release session's first move, not a backlog row.
