# GAP-sggz — session-close's finished-card sweep misses a card whose next step was finished in another card's thread

**Logged:** 2026-11-26 · **Source:** mailbox note from `jowagoko` (tip, 2026-11-25)
**Problem:** All four signals (a–d) of `session-close` § 3's finished-card sweep key on the card ID: the card's own Progress, a hand-off to a deleted ID, a commit message naming the ID, this session's own text. In jowagoko, a card's next step ("run receipts after the vote closes, record the episode") was done entirely elsewhere — the vote result on the weekly-recording anchor card, the receipts in a commit, the pre-record check on another card — and none of those named the card's ID. The card stayed open 9 days across three sessions until the host noticed. (scope per the jowagoko note, unconfirmed)
**Area:** `plugins/super-bootstrap/skills/session-close/SKILL.md` § 3
**Prior:** Sender's proposal, shape open — a non-ID signal: match each open card's latest-block next-step topic words against this session's commit subjects and other cards' newly written blocks; a hit lists as a triage candidate, never an auto-resolve.
