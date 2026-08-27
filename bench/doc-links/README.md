# bench/doc-links — golden test for the commit door's mechanical doc-sync gate

Test surface for [`skills/commit/assets/doc-links.sh`](../../plugins/super-bootstrap/skills/commit/assets/doc-links.sh),
the enumeration the `/super-bootstrap:commit` gate ([`skills/commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) §3)
runs before it decides whether to dispatch the cold scan. An edit to the script or
to §3's mechanics re-runs this bench (`bash bench/doc-links/run.sh`).

- `fixture/` — a mini repo root. Doc surface: `README.md`, `plugins/x/README.md`,
  and `docs/**/*.md` (`anchors.md` — headings at pinned line numbers, one of them
  punctuated · three citers of `anchors.md`, two at one anchor each and one at both ·
  seven `docs/specs/` bodies, each carrying exactly one match shape). Off-surface
  props the `terms` cases name by path: a skill, an agent, a generic-basename asset,
  a `bench/` script, a `tests/expected/` golden, a `.gd` source.
- `expected/` — one golden per case, byte-compared; every case must also exit 0.

## Cases

**`terms` — changed paths → grep terms.**
`terms-skill` a skill path yields its directory name, not `SKILL` ·
`terms-agent` an agent path yields its basename ·
`terms-dropped` the whole exempt set yields nothing: `bench/`, `tests/expected/`,
`docs/work/`, `docs/outward.md`, `SESSION-STATE/`, an image extension, a generic
basename (`README`, `run`) and a basename under four characters (`ui`) ·
`terms-mixed` a mixed list yields the sorted-unique union ·
`terms-replay-bench` / `terms-replay-skill` the acceptance fixtures replayed as
file lists — a bench-only commit yields no term (nothing to dispatch on), a skill
commit yields the skill name plus its asset basename.

**`hits` — terms → doc-surface files, code shape only.**
`hits-level` the prose sentence "the level select strip" does not hit, while
`` `level.gd` `` (backticked whole word), `` `scripts/level.gd:7` `` (path segment
in a provenance pointer) and a bare `scripts/level.gd` (path segment outside
backticks) all do. Two files must stay out: `leveling` inside backticks is not the
whole word `level`, and a `level` sitting in the gap *between* two code spans is
not inside one — the case a backtick regex gets wrong and the script's paired-span
parse gets right ·
`hits-hyphen` a hyphenated term matches inside `` `/x:foo-bar` `` ·
`hits-multi` several terms yield the sorted-unique union ·
`hits-miss` an absent term yields nothing, still exit 0.

**`anchors` — hunk ranges → section slugs.**
`anchors-basic` two ranges under two different headings (one of them a `###`
nested under its parent) yield both slugs, sorted ·
`anchors-top` a range above the file's first heading yields `(top)`, the
whole-file-grain signal ·
`anchors-punct` a heading carrying parentheses and a hyphen slugs the same way
GitHub does ·
`anchors-noplus` the range accepts a bare line number as well as `+N`.

**`refs` — the multi-anchor extension.**
`refs-single` one anchored query, unchanged behavior · `refs-multi` two anchors of
one doc print the union, and the citer that cites both appears once. Both goldens
are sort-normalized: `refs` prints in doc-surface order, which is filesystem-order
dependent, so union and uniqueness are what these pin.

**`check`** — the fixture's own links all resolve, so the pre-existing mode stays
green beside the new ones.
