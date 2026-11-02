# DEBT-xs75 — volatile-ids lane leftovers: duplicated hunk parser, unrun cross-awk check, predicate contradiction

**Logged:** 2026-11-03 · **Source:** DEBT-5egy build and its cold audit
**Problem:**
- `VOLID_AWK` copies the 6-line hunk-range parse from `TERMUSE_AWK` in `doc-links.sh`, against the file's anti-drift convention of one shared fragment.
- The cross-awk Docker check did not run on the new mode: Docker was unavailable. Only gawk 5.3.2 exercised it.
- Regex side effect: a hyphen is a boundary, so prose like `OUT-of-band` reports `OUT-of`, and `BUG-abc-def` reports `BUG-abc`. No occurrence on this repo's surface.
- `check-docs-consistency/assets/dimension-predicate.md` route 4 ("Verification stamps stay") contradicts the dimension rule's route 4 ("When-checked → git"). Predates this work.
- The dimension rule read literally reaches standing index lines naming the tracker folder. An added exemption clause failed its bench 0 of 3 (`bench/volatile-id-citation/` Arm 3: runs cited it to point readers at the folder), so the rule carries none and the audit predicate does.
**Area:** `plugins/super-bootstrap/skills/commit/assets/doc-links.sh`; `plugins/super-bootstrap/skills/check-docs-consistency/assets/dimension-predicate.md`; `plugins/super-bootstrap/skills/harness-bootstrap/assets/rules-dimension-discipline-skeleton.md`
