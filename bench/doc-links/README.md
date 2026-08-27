# bench/doc-links — golden test for the commit door's mechanical doc-sync gate

Test surface for [`skills/commit/assets/doc-links.sh`](../../plugins/super-bootstrap/skills/commit/assets/doc-links.sh),
the enumeration the `/super-bootstrap:commit` gate ([`skills/commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) §3)
runs before it decides whether to dispatch the cold scan. An edit to the script or
to §3's mechanics re-runs this bench (`bash bench/doc-links/run.sh`).

- `fixture/` — a mini repo root. Doc surface: `README.md`, `plugins/x/README.md`,
  and `docs/**/*.md` (`anchors.md` — headings at pinned line numbers, one of them
  punctuated · three citers of `anchors.md`, two at one anchor each and one at both ·
  a hub doc (`overview.md`) · nine `docs/specs/` bodies, each carrying exactly one match shape · a
  `dimension: history` pair — `chronicle.md` declaring it in frontmatter,
  `body-mention.md` carrying the same string as body prose). Off-surface
  props the `terms` cases name by path: a skill, an agent, a generic-basename asset,
  a `bench/` script, a `tests/expected/` golden, a `.gd` source.
- `fixture-history-broken/` — a second mini root holding one history-dimension doc
  with a dangling link, for the case that pins history docs inside link integrity.
- `fixture-consumed-card/` — a third mini root for the consumed-provenance exemption:
  a card thread citing a deleted sibling card (the exempt class) beside two controls —
  a card citing an absent spec, and a non-card doc citing an absent card.
- `fixture-consumed-card-clean/` — a fourth mini root holding the exempt class alone,
  so the silent-and-uncounted half of the exemption is pinned on its own.
- `expected/` — one golden per case, byte-compared; every case must also exit 0
  except `check-history-broken` and `check-consumed-card`, which pin exit 1.

## Cases

**`terms` — changed paths → grep terms.**
`terms-skill` a skill path yields its directory name, not `SKILL` ·
`terms-agent` an agent path yields its basename ·
`terms-dropped` the whole exempt set yields nothing: `bench/`, `tests/expected/`,
`docs/work/`, `docs/outward.md`, `SESSION-STATE/`, an image extension, a generic
basename (`README`, `run`) and a basename under four characters (`ui`) ·
`terms-machine-state` the `.claude/` runway receipt and a `templates/` file yield nothing ·
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
`hits-miss` an absent term yields nothing, still exit 0 ·
`hits-hub` harness-seeded hub stems (`overview`, `techstack`) count only as a bare token
in a code span — a link target, a backticked path, a bare filename and a bare path all stay out
(`hub-path.md`) while the doc naming the artifact hits (`hub-bare.md`) ·
`hits-history` a frontmatter `dimension: history` declaration drops the doc from the
hit set, while the doc carrying the same string in its body still hits — the
declaration is the carrier, not the string. `terms-history` the same declaration on a
changed path yields no term — a history doc neither triggers the gate nor joins its scope.

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
dependent, so union and uniqueness are what these pin. Both also pin the history
exclusion, since `chronicle.md` cites `anchors.md#alpha` and stays out ·
`refs-history` the sole citer of `docs/specs/thing.md` is that history doc, so the
citer lane comes back empty.

**`check`** — the fixture's own links all resolve, so the pre-existing mode stays
green beside the new ones · `check-history-broken` a dangling link inside a
history-dimension doc is reported and exits 1: the declaration leaves the staleness
scope, never link integrity ·
`check-consumed-card` a card thread's link to an absent card ID is skipped uncounted
(consumed provenance), while both controls still fail and hold the exit at 1 — a card's
link to an absent *spec*, and a non-card doc's link to an absent card, since the
exemption needs both endpoints card-shaped ·
`check-consumed-card-clean` the exempt class alone prints nothing and exits 0.
