# GAP-s54t — no sanctioned consumer-extension slot exempt from harness-bootstrap's whole-file drift check

**Logged:** 2026-10-27 · **Source:** device note from `jowagoko` (2026-10-25, re-sync 4.1.0 → 5.3.0, consumer commit `98d955a`)
**Problem:** jowagoko adds a hook-read field — `**Due（選用）：** YYYY-MM-DD` in the `docs/work/README.md` thread contract and `**Due:**` on `docs/parked.md` entries, read by its SessionStart hook `scripts/due_today.py`. The extension is legitimate, but every sync's whole-file drift check must re-judge it section by section as a superset, because the skeleton offers no place for consumer additions.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` (whole-file drift / sync); skeleton assets for `docs/work/README.md` and `docs/parked.md`
**Prior:** sender's options — (a) skeleton adopts `Due` as an optional fact field; (b) a sanctioned `<!-- consumer: … -->` marker block excluded from drift comparison, like the scale-module fact-fields block.
