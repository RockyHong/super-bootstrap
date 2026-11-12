# Carry — BUG-q2jy

**Anchor:** BUG-q2jy — commit door grep lane over-scope; widened mid-session into GAP-by73 (doc-sync layering).

**Read first:** docs/work/BUG-q2jy.md (latest Progress leads: built, held, next steps a–c), then docs/work/GAP-by73.md.

**State:** 8ddf6e8 holds both cards and the scope-replay measurement. Uncommitted and held: plugins/super-bootstrap/skills/commit/assets/doc-links.sh, tests/doc-links.test.sh (the grep-scope mode). Untracked: bench/doc-sync-history/.

**Next step:** two author rulings open — (1) run BUG-q2jy Progress step (a), the pre-fix replay of the history's grep-hit catches, before ship / change / drop; (2) bench/doc-sync-history/: commit, keep local, or delete.

**Watch-outs:**

- bench/doc-sync-history/ holds transcript excerpts and this repo is public.
- The replay trees lived in a session scratchpad and may be gone: `arms.sh all` rebuilds them in about 15 minutes, `arms.sh parity <script>` takes about 16.
- magnetized-remake has uncommitted work: read its git objects only.
- The gateway's mid-session claim that doc-sync "almost never produces" was wrong; GAP-by73's Amendment holds the measured record.
- The held doc-links.sh edit is a shipped skill asset: it owes `audit-harness-edits` before any commit.
