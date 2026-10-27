# BUG-g66v — commit door: a `terms` term holding a space shell-splits on its way to `hits`

**Logged:** 2026-10-27 · **Source:** device note from ComfyUI `workflows/agent` consumer (commit on 2026-10-27; 15-file diff, real doc closure 2 docs, gate enumerated 13 → forced cold `doc-sync-scan` over the 8-doc ceiling)
**Problem:** `doc-links.sh terms` can print a term containing spaces (a workflow file name such as `[Image t2i] Krea 2`). Commit SKILL.md §3 says "Pass the printed terms to `hits` verbatim" but shows no safe invocation; the consumer gateway ran `hits $T` unquoted, and the shell split the names into fragments (`Krea`, `2`, `H3`, `[Image`) that hit unrelated docs (`audio-grounding-*`, `video-gen-model-pick-*`) and inflated the scan scope.
**Area:** `plugins/super-bootstrap/skills/commit/assets/doc-links.sh` (`do_terms`, `do_hits`, argv-only term intake); `plugins/super-bootstrap/skills/commit/SKILL.md` §3 "Terms → grep hits"
**Prior:** `hits` takes terms only as argv — consumer suggests a stdin form (`terms … | hits -`, one term per line) or an explicit safe form in the skill text.
