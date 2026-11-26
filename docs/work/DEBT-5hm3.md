# DEBT-5hm3 — session-close still asks for push in its pick when the repo is the user's own

**Logged:** 2026-11-26 · **Source:** mailbox note from `claude-config-manager` (handoff, 2026-11-25, its finding 2, against 7.1.3)
**Problem:** `session-close` lists push as a row in its confirm-pick (`skills/session-close/SKILL.md` around :78, :98, :131), so a push still costs the user a confirm. The device push rule (claude-config-manager `a69e98e`, `templates/device-claude.md` § Ask Threshold) makes a push to a user-owned repo the session's own closeout move with no ask, taken through the closeout skill's mechanical push check. The public plugin has to stand alone without that device rule. (scope per the ccm note, unconfirmed)
**Area:** `plugins/super-bootstrap/skills/session-close/SKILL.md`, `plugins/super-bootstrap/skills/session-close/assets/push-state.sh`
**Prior:** ccm's proposal — when `push-state.sh` detects a pushable branch and the repo owner matches the `gh` login, push without a pick row and report it; keep the pick row for any repo whose owner does not resolve to the user.
