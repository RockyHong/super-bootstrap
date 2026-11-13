# DEBT-298j — the warm doc-sync lane leaves no record that shows it read every scope doc

**Logged:** 2026-11-13 · **Source:** 30-day transcript history of the commit door (160 warm commit windows), gathered under the since-closed `GAP-by73`; tables kept on the author's device in `bench/doc-sync-history/` (git-ignored)
**Problem:** `commit/SKILL.md` §4 warm-inline says every scope doc gets an outcome — a stale candidate or read-and-confirmed-unchanged. Of 160 warm windows in the history, 109 show no outcome text, and 37 show a path count over the 8-doc ceiling, which is either the miner over-counting or a ceiling not followed — undetermined. Of 24 warm windows judged, 16 held a real catch, so the lane does work; what is missing is the trace. After the fact, a warm judgment that read all its scope docs and one that skimmed them look the same.
**Area:** `plugins/super-bootstrap/skills/commit/SKILL.md` §3 scope ceiling, §4 warm-inline
**Prior:** A fixed-shape outcome line per scope doc, printed before the commit — decidable by count against the scope list — rather than more prose asking for it.
**Blast:** pkg
