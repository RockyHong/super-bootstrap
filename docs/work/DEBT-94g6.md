# DEBT-94g6 — The 8-doc scope ceiling trips on nearly every doc-touching commit

**Logged:** 2026-11-03 · **Source:** BUG-et1c replay probe
**Problem:** The commit door's default is warm-inline judgment with the cold `doc-sync-scan` as the overload valve. In a replay of 30 doc-touching commits, 28 crossed the 8-doc ceiling under current lanes (median scope 21; 13 of 15 here, 15 of 15 in `magnetized-remake`). The sample is recent and not independent, and it replayed whole commits as the session list. If it holds, the valve is the normal lane. Decide whether the ceiling, the lanes, or the stated default should change, or that it stands. Same replay: dropping changed-doc terms cuts `magnetized-remake`'s scope by a median of 8 docs and this repo's by 0, a scan-size saving that moved no crossing and was out of aim for the card that measured it.
**Area:** `plugins/super-bootstrap/skills/commit/SKILL.md` §3 scope ceiling, §4; `plugins/super-bootstrap/agents/doc-sync-scan.md`
