# mattpocock-adapt — what to watch when the waves close

**Produced:** 2026-07-26 · **Producer:** side session (read-only assessment; no edits made)
**Question asked:** does `mattpocock/skills` supersede super-bootstrap, and if it is orthogonal,
which slots can super-bootstrap *vacate* rather than build?
**Answer:** no supersession — different layers. The vacate list is below, but the load-bearing
content of this report is §3: what bites when the de-routing waves report complete.

**Grounding:** [`docs/specs/harness-architecture.md`](../docs/specs/harness-architecture.md)
§2 (slot map), §4 (seam), §6 (decided vs open), §8 (downstream migration).
This report adds nothing to that doc's analysis; it holds the open cards against it and
lists the failure shapes at wave close.

**Evidence grade: B for every mattpocock claim below except the README-level skill index (A).**
`GAP-041` is the card that would raise this. Read it before treating any "he already covers
this" line as settled.

---

## 1. The doctrine the vacate list must not break

Vacating a slot means **naming the discipline and shipping nothing**. It does not mean
re-pointing a routing line from one foreign harness to another — that rebuilds the coupling
change A paid to remove (§6). The seam stays **runtime-orthogonal, setup-time-composed**:
`plugins/super-bootstrap/**` names zero foreign skills (grep-verifiable, §4), and composition
happens through the other set's own setup socket.

Corollary for the waves: a card whose fix reads "point at X instead" is mis-shaped whatever X is.

## 2. Vacate list — slots the other set already occupies

| Card | Slot | Vacate shape | Cascade |
| --- | --- | --- | --- |
| `DEBT-026` | per-feature work order (`docs/superpowers/specs\|plans/`) | **drop the slot, do not rename** — `to-tickets` owns it at `.scratch/<feature>/issues/NN-slug.md`, and his setup already asks where docs live | largest of the four; see §3 W4 |
| `DEBT-028` | drain phase escalation | already correct as carded — dispatch the repo's declared entry, name nothing | none |
| `DEBT-032` | ambient law bodies | `test-first` body is his `/tdd` → vacate. `verify before claiming` plausibly compresses. **`Review received, not absorbed` has no counterpart in his set** → card narrows from three laws to one | narrows the card |
| `GAP-042` | `CODING_STANDARDS.md` | *strengthens* — his `code-review` reads that exact file and a repo-declared standard overrides his Fowler baseline, so the socket gains a concrete consumer | see §3 W9 |

**Not vacatable** (§2 uncontested + the repo's own pillars): `/log` + `docs/backlog.md`,
doc-sync + the commit gate, drain's parallelism, `.claude/rules/` path-scoped wiring,
`harness-bootstrap`, `resolve-plugins`, `triage-report`.

**Do not vacate by mistake:**

- **`todo` board** — §2 records that he defers to a real tracker. A board over our own backlog
  is our home, not an overlap.
- **`/super-bootstrap:merge`** — it aborts on conflict and hands the file list out. His
  `resolving-merge-conflicts` is the natural receiver, and the current wording already routes
  harness-neutrally. Leave it; naming him here would be the §1 violation.

**Uncarded observation.** The triage lane's investigation doctrine was *restated inline*
(commits `2a96af5`, `cf9035f`) rather than cut. Under the vacate doctrine the doctrine body is
his `diagnosing-bugs`; what is ours is the container (card → read-only verdict artifact →
`{ID}-scope.md` / `{ID}-notes.md`). Same judgement class as `DEBT-032`, no card covers it.

---

## 3. Watch-outs at wave close

### W1 — Zero grep hits is necessary, not sufficient

§4's `rg` pattern verifies foreign **names** are gone. It cannot see foreign **shapes**.
drain's stage chain `raw→triage→plan→execute→review` passes a rename to harness-neutral words
while remaining superpowers' phase decomposition. When `DEBT-028` lands, check the stage set is
derived from something the repo declares — not the same five stages with new labels.

### W2 — An empty slot is only "vacated" if something composes into it

Vacating assumes the operator installs the other set. A repo bootstrapped with super-bootstrap
alone gets the one-line discipline and nothing behind it. `DEBT-032` is this failure in
miniature; at wave close it generalizes to every vacated slot at once.

**Decide and state a posture before the last wave lands:** does `resolve-plugins` recommend a
process harness at setup time (setup-time composition, per §4), or does the runway ship
genuinely bare and say so? Today §6 permits superpowers to stay installed, `harness-bootstrap`
no longer pins it, and no replacement recommendation exists — which is the bare branch by
default, not by decision.

### W3 — `DEBT-026` is the only cut adopt mode cannot migrate

§8: folders have two states, missing or present; there is no removal path. Retiring
`docs/superpowers/specs|plans/` orphans those directories in every already-bootstrapped repo,
where `/super-bootstrap:todo` and `drain` still scan them. The card must land **with** its
migration mechanism or **with** an explicit accept-the-orphan note. Silent landing is the
failure mode.

### W4 — `DEBT-026` / `027` / `022` / `BUG-019` are one change wearing four cards

- `DEBT-027`'s cheapest test shape (verb-map-only intent) is designed against a per-row
  **plan-body content read**. `DEBT-026` deletes the plan files that read consumes.
- `BUG-019` (empty `todo full` table) exists because spec/plan rows are the Full scaffold's
  only row source. Drop the folder and the bug's cause is gone; the fix collapses to "render
  backlog rows".
- `DEBT-022`'s classify pass shrinks to backlog-only scanning for the same reason.

**Order: `DEBT-026` first, then re-aim the other three against what remains.** Executing them
as independent cards in independent commits builds work that the next card deletes.

### W5 — drain's admission predicate spans that same set

`DEBT-027` states the constraint explicitly: any retirement must replace drain's admission
predicate in the same change, because without the venue map `intent == Cloud` is drain's whole
gate. `DEBT-026` changes drain's input surface too. Three cards, one same-change constraint —
verify it holds across all three, not just inside `DEBT-027`.

### W6 — Vacating is close to irreversible; the evidence is grade B

Downstream, a removed folder has no path back (W3). Every "he already covers this" claim in §2
above, and in spec §7's external table, is model-summarized fetch — not read source.
`GAP-041` is the card that fixes this and it is currently sequenced behind the cuts.
Recommend raising it **before** the last irreversible cut, not after.

### W7 — "waves complete" ≠ "the harness story is settled"

§6 lists **change A (de-routing) as decided** and **change B (harness swap) as open**.
`GAP-038` is explicitly blocked on change B and explicitly not executable as titled. When the
last wave closes, report change A complete — not de-routing-and-adoption complete. `GAP-038`
and the §4 "known weakness" (his setup has no lookup path to a seed another plugin ships;
whether it skips an existing `docs/agents/issue-tracker.md` is **unread**) both survive wave
close untouched.

### W8 — The commit-string detector is a two-step migration if split

§4 records that `chore: scaffold|sync superpowers pipeline` doubles as the mature-repo
bootstrap detector, and that the strings are deliberately **not** renamed separately from the
folder. If a wave splits them, repos committed between the two steps are undetectable by
either string. Keep folder rename and detector-string rename in one change.

### W9 — `GAP-042` lands a file whose only reader is currently external

Seeding a headings-only `CODING_STANDARDS.md` is right, but in a repo without his set installed
nothing reads it. That is fine as a socket; it is not fine to close the card as "the standard is
now visible to any reviewer" — the visibility depends on W2's unmade decision.

### W10 — The grounding spec is itself a dimension trap at wave close

`docs/specs/harness-architecture.md` §4 carries a dated snapshot table ("Where it stands
(2026-07-26, after the skeleton cut)") inside a **state** doc, and §3's dissolve table carries
per-row `landed` / `open` status. `.claude/rules/dimension-discipline.md` fires on this exact
path. At wave close these must be overwritten to truth-now (or the chronicle dropped to git),
not appended to — otherwise the doc that grounds the de-routing becomes the mixed-dimension
artifact the rule warns is a trap for the next editor.

---

## 4. Checklist — what should be true when the last wave reports done

- [ ] `rg 'superpowers|systematic-debugging|brainstorm|writing-plans|write-plan|execute-plan'` over `plugins/super-bootstrap/` returns zero — **and** a shape check per W1
- [ ] `DEBT-026` landed with a stated downstream position (migrate or accept-orphan), W3
- [ ] `DEBT-026` → `027` → `022` / `BUG-019` executed in that order, W4; drain's admission predicate verified across the set, W5
- [ ] `DEBT-028`'s stage set derived from a declared interface, not renamed superpowers phases, W1
- [ ] `DEBT-032` narrowed to `Review received, not absorbed` and answered, §2
- [ ] Folder rename and detector-string rename shipped in one change, W8
- [ ] W2's posture decided and written into `docs/specs/harness-architecture.md` §6 or `docs/decisions.md`
- [ ] Spec §3/§4 status tables overwritten to truth-now, W10
- [ ] Close-out states **change A complete, change B open**; `GAP-038` + `GAP-041` still open, W7
