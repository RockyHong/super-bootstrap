# DEBT-079 — triage's blast collection reads the shipping surface, not the serving surface

**Logged:** 2026-08-25 · **Source:** BUG-041 implement phase — the miss surfaced only when the gateway byte-compared the file against its upstream
**Problem:** Asked whether a harness file under `.claude/` is this repo's to edit, both the capture door and the cold `triage` agent answered from the *outbound* direction only — does `harness-bootstrap` stage it into a consumer repo, does anything else reference it — and concluded "dogfood-only, no propagation". Neither asked the *inbound* question: is this file itself a copy served here from another repo? For `.claude/hooks/agent-model-pretool.sh` the answer was yes (claude-config-manager `templates/`), which inverts the routing — [`.claude/rules/repo-boundary.md`](../../.claude/rules/repo-boundary.md) § Finding lanes makes it read-only here and sends the fix to `/contribute`. A verdict that clears an imported artifact for in-place editing sends the implementer at the wrong repo, and the next `/resolve-claude-config` sync silently reverts the work.
**Area:** [`plugins/super-bootstrap/agents/triage.md`](../../plugins/super-bootstrap/agents/triage.md) (blast collection); possibly [`plugins/super-bootstrap/skills/log/SKILL.md`](../../plugins/super-bootstrap/skills/log/SKILL.md) (the `Area:` ownership claim is written at capture)
**Prior:** The check is mechanical and cheap — a served copy is byte-identical to its template, and the serve source is already named by the `serve-freshness` SessionStart line. A blast step that byte-compares any touched `.claude/**` path against the serving repo's templates would have caught it. Note the boundary rule's `paths:` frontmatter fires on `.claude/rules/**` and `.claude/guidelines/**` but not `.claude/hooks/**`, so the rule body never loaded during the edit either — worth weighing as part of the same fix.

## Amendment — 2026-08-25 · gateway (the miss cost duplicate work)

The inbound-ownership question has a second half the origin block did not name:
**is the serving repo's local clone current?** Acting on the first half alone, this
session opened `/d/Git/claude-config-manager` and implemented the fix there — in a
clone 11 commits behind its remote. The identical defect had already been carded
upstream as `BUG-038` and fixed two days earlier, rewritten in awk to close both
GNU-isms at once. The session's sed rewrite was therefore duplicate work; it also
consumed a `BUG-035` id already taken upstream, and its `;}` half-fix addressed the
POSIX requirement (a `;` *before* `}`) while leaving intact the `};` sequence that
`BUG-038` records BSD as actually rejecting — so the duplicate was very likely not
even a working fix. Discarded in favour of upstream (`ac81d95`, kept on branch
`bug041-sed-attempt-discarded`); the served copy here was re-synced to the awk version.

The `/contribute` door is what makes the freshness question moot — it hands the
*finding* to `inbox/` and lets repo-side `/digest-inbox` triage it against live state,
where the `BUG-038` duplicate surfaces immediately. Editing a local clone skips that
dedup entirely. So the routing rule in [`.claude/rules/repo-boundary.md`](../../.claude/rules/repo-boundary.md)
§ Finding lanes is not merely about write-permission hygiene: the handoff is the
dedup step. A fix for this card should carry both halves — is the file served here,
and if the finding routes out, does it route through the door rather than a clone.
