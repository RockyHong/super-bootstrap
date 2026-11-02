# BUG-et1c — Commit door `terms` lane emits changed docs' basenames and inflates the doc-sync scan scope

**Logged:** 2026-11-03 · **Source:** device note from `magnetized-remake` (2026-10-30, super-bootstrap 5.7.0)
**Problem:** The grep-gate's `doc-links.sh terms` emits the basenames of the diff's own changed docs (seen: `lv60-spec`, `visual-guidelines`, `dev-harness`) as grep terms. `hits` then counts every doc that links any section of those docs, whole-file. That duplicates and widens the anchored `refs` lane, which already finds the citers of the changed sections at hunk grain (`anchors` → `refs <path>#<slug>`).

Seen: a 16-file diff (5 docs, 11 code/test files) produced a 29-doc scan scope. `hits --by-term`: visual-guidelines 26, lv60-spec 15, dev-harness 9, lv81-spec 8; code-path terms 2–6 each. With code-path terms only, the union (self + refs + code hits + link targets) is about 15. The cold `doc-sync-scan` judged every extra doc unrelated. The inflation also pushed the scope past the 8-doc ceiling and forced a cold dispatch.

Note's proposed fix: `terms` drops every path the `self` lane prints, because their citers belong to the `refs` lane at section grain; the hub-stem rule stays. Regression fixture: a diff touching one heavily linked doc in one section scopes only that section's citers.

Open at capture: the drop makes a doc that mentions a changed doc in backticks without linking it fall out of scope. [`docs/decisions.md`](../decisions.md) closed "swap the grep-gate's stage 1 for a pure reverse-link lookup" because link graphs err false-negative. The proposal is narrower than that row (one term class, code-path terms stay in grep), so it is logged rather than treated as a re-proposal; whether the row's error direction still bites here is unsettled.
**Area:** `plugins/super-bootstrap/skills/commit/assets/doc-links.sh` (`terms`, `self`, `hits`, `refs`), `plugins/super-bootstrap/skills/commit/SKILL.md` §3, `tests/doc-links.test.sh`
**Prior:** `terms` treats a changed doc like any other changed path; it predates the anchored `refs` lane covering the same citers.
