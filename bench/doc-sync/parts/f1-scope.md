Today's date: 2026-08-08.

## Scan scope

- `docs/decisions.md`
- `docs/overview.md`
- `docs/techstack.md`
- `docs/specs/harness-architecture.md`
- `docs/specs/mattpocock-coexistence.md`

How the gate produced it (mechanical, no judgment):

- **Grep lane** — `doc-links.sh terms` on the changed doc paths printed `harness-architecture` and `mattpocock-coexistence`; `doc-links.sh hits` on those terms returned `docs/decisions.md`, `docs/overview.md`, `docs/techstack.md` (changed files excluded).
- **Citer lane** — changed post-image hunk ranges resolved to anchors `#4-the-seam-runtime-orthogonal-setup-time-composed` and `#change-a-is-complete-change-b-is-resolved` on `docs/specs/harness-architecture.md`, and whole-file grain on the new `docs/specs/mattpocock-coexistence.md`. `doc-links.sh refs` on those returned `docs/specs/mattpocock-coexistence.md` (itself a changed file).
- **Link-target lane** — markdown `.md` targets on added lines resolved to `docs/specs/harness-architecture.md` and `docs/specs/mattpocock-coexistence.md`. A target that is itself a changed file still joins the scope: its unchanged sections are exactly where a same-commit contradiction hides.
- **Exempt** — `docs/work/GAP-038.md` (deleted) is card-lifecycle, frozen provenance; it yields no term and joins no lane.
- Scope = citers ∪ grep hits ∪ link-targets = 5 docs, under the 8-doc ceiling.

The repository tree you are judging against is the working directory. Read the scope docs from disk.
