# DEBT-5hm3 — session-close still asks for push in its pick when the repo is the user's own

**Logged:** 2026-11-26 · **Source:** mailbox note from `claude-config-manager` (handoff, 2026-11-25, its finding 2, against 7.1.3)
**Problem:** `session-close` lists push as a row in its confirm-pick (`skills/session-close/SKILL.md` around :78, :98, :131), so a push still costs the user a confirm. The device push rule (claude-config-manager `a69e98e`, `templates/device-claude.md` § Ask Threshold) makes a push to a user-owned repo the session's own closeout move with no ask, taken through the closeout skill's mechanical push check. The public plugin has to stand alone without that device rule. (scope per the ccm note, unconfirmed)
**Area:** `plugins/super-bootstrap/skills/session-close/SKILL.md`, `plugins/super-bootstrap/skills/session-close/assets/push-state.sh`
**Prior:** ccm's proposal — when `push-state.sh` detects a pushable branch and the repo owner matches the `gh` login, push without a pick row and report it; keep the pick row for any repo whose owner does not resolve to the user.

## Verdict — surface · 2026-11-26

### Findings

- premise age: clean — `git log --since=2026-11-25 -- plugins/super-bootstrap/skills/session-close/` returns no commit.
- root cause (need-check, gap confirmed): push is a gated pick row by design. `SKILL.md:78` turns a printed `push-state.sh move` line into a **push** move; `:98` puts every move into the one AskUserQuestion pick ("blast for moves that mutate or reach outward (merge, prune, push)"); `:106` runs push last in drive order, only when picked; `:131` (Rules) states "Commit, merge, prune, push, and every file write … run only when picked, after the pick". `push-state.sh` reads remote / upstream / ahead only — no owner lookup, no `gh` call. So a user-owned repo still costs one confirm, as the card says.
- the gate is an owner ruling, not an accident: commit `2303783` ("Owner's ruling: … A remote brings a push move into the pick") and `86c55b9` set it. `docs/decisions.md` holds no push row, so no closed fork is re-walked; the change reverses a ruled behavior of a shipped skill.
- the bench already anticipates an ambient push rule: `bench/session-close-push/README.md` § Protocol withholds user-level instruction files "which can state their own push rule". Today the skill's "only when picked" line and the device rule (`~/.claude/CLAUDE.md` § Ask Threshold — "take the push move an installed closeout skill's mechanical check detects") collide on this device; the skill text keeps the row.
- duplicate check: no open card in `docs/work/` names push.
- scope reach: `plugins/super-bootstrap/skills/session-close/SKILL.md` (:78, :98, :106, :131, § Output :122 "the line `push-state.sh state` printed" — a pushed-without-pick report would need a field); `plugins/super-bootstrap/skills/session-close/assets/push-state.sh` + `tests/push-state.test.sh` (only if the owner check goes into the script); `bench/session-close-push/` (RED surface per `.claude/rules/skill-authoring.md` — behavior-shaping prose; new scenario for owned vs. not-owned, arm vs. control); `plugins/super-bootstrap/README.md:12` and root `README.md:105` (session-close narration, re-read on change). Provenance: all plugin-source, native to this repo — no `.served` marker in the skill directory.
- attempted: static read of the skill, the script, the bench README, the ruling commits, decisions.md. Stopped: the fix shape is a product/risk call on a shipped skill (auto-push to a remote in consumer repos), not settled by any doc.

### Decision needed

- Should session-close push without a pick row, and on what authority — a plugin-built owner check, or the consumer's own standing instruction?
- options:
  - **A. Owner-gated auto-push in the plugin** (ccm's Prior) — `push-state.sh` (or the skill) resolves the remote owner and compares it to `gh api user --jq .login`; match → push after the pick's other moves, no row, reported in § Output; no match / `gh` absent / owner unresolved → row as today. Changes default behavior for every consumer with `gh` logged in; adds a `gh` + network dependency to a mechanical check; org-owned repos and forks need a rule.
  - **B. Yield to a standing push authorization** — the skill keeps the row by default, and drops it (push runs, reported in § Output) when the repo's or user's ambient instructions already authorize the close's push with no ask. No owner logic in the plugin; the plugin stays self-contained; on this device the existing `~/.claude/CLAUDE.md` rule (which already does the owner check itself) supplies the authority. Cost: the skill judges an ambient instruction, a softer trigger than a script, and needs its own RED.
  - **C. Keep the row** — the ruled behavior of `2303783` stands; the device rule is narrowed in claude-config-manager to accept the pick row as the closeout move (hand-over via `/send-note claude-config-manager …`, the author's move).
- recommendation: **B** — the authority for an outward push without a confirm belongs to the user's standing instruction, which this device already states with its own owner check; the plugin then stays self-contained and keeps today's default for consumers who have no such rule.
- settles by: preference + risk authority (the owner reverses or keeps the `2303783` ruling — the consequence of an unconfirmed push lands on the user). After the pick, the chosen shape's RED is a `phased build`: a new `bench/session-close-push` scenario pair (owned-authorized vs. not), control at HEAD vs. arm, headless per that bench's § Protocol.


## Design — 2026-11-26

Settled by the gateway's climb, no user ruling needed: option B. `docs/decisions.md` holds no push row; the shipped default stays the owner's ruling in `2303783` (a remote brings a push move into the pick); the author's own ambient instruction (`~/.claude/CLAUDE.md` § Ask Threshold, served by claude-config-manager `a69e98e`) already authorizes a no-confirm push for repos the user owns and carries its own owner check. So: keep the pick row by default; drop it when the repo's or the user's ambient instructions authorize a closeout push without a confirm, then take the push after the pick and report it in § Output. No owner logic in the plugin; `push-state.sh` unchanged. RED first on `bench/session-close-push/` (authorized vs unauthorized ambient instruction scenarios).
