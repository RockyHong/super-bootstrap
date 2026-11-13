2026-11-13
# Carry — BUG-hw7q

**Anchor:** BUG-hw7q — cold doc-sync judge returns a verdict without a readable diff.

**Read first:** docs/work/BUG-hw7q.md (latest Progress leads), then docs/work/DEBT-298j.md.

**State:** nothing built. v5.10.5 is released and pushed.

**Next step:** `/super-bootstrap:triage BUG-hw7q`.

**Watch-outs:**

- Evidence tables sit in bench/doc-sync-history/, git-ignored, on this device only.
- The cross-awk Docker check for doc-links.sh's `getline < "-"` was not run for v5.10.5.
