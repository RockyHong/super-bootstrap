---
name: session-continue
description: "Use at session start to resume in-flight work — reads the root SESSION-STATE/ carry ledger and orients. Carries present → offer every live one, a single carry included, with its age and card state; the user picks resume, other work (→ /super-bootstrap:needs-me), or leave. A carry whose next step names `not before` a later date is held out of the offer and named with its date. Carries it judges dead — a gone pointer, a card whose latest Progress post-dates the carry, an older carry on a card a newer one also anchors — are offered for retire, deleted only on the user's pick. On resume, follow its Read first into the card it names and read the latest block of each type as the lead, reconstruct where work stopped + the next step, confirm before diving in. None, or no live carry → report no in-flight carry and hand off to /super-bootstrap:needs-me. Claims a carry only on the user's resume pick — renames it to this session's id so whoever resumes the work also owns closing it; deletes only the carries the user picks to retire; unpicked carries and every carry body stay untouched. No argument; reads current session state. Mirror of /super-bootstrap:session-close."
tags: [session, resume, carry, ledger, session-opener]
---

# Session Continue — Cold-Open Orientation

Mirror of `/super-bootstrap:session-close`: it lands the carry, this picks it up. The read side of the cold-pickup test — "can a cold session orient from files alone?" — run as a procedure. **Consumer** of the `SESSION-STATE/` ledger — reads every carry in it, claims the one the user picks, retires the ones the user picks to retire, leaves the rest as found. Naming, slots, and conflict handling follow session-close's § Ledger convention.

## Two entry states

| Detected state | Shape |
|---|---|
| Root `SESSION-STATE/` holds ≥1 live carry | **resume** — offer the live carries, name the held ones, offer the retire candidates; on a resume pick, claim and reconstruct that carry, confirm the next step |
| Folder absent or empty, OR no live carry | **cold-orient** — no in-flight carry to take; name the held carries, offer the retire candidates, hand off to `/super-bootstrap:needs-me` |

## Protocol

The gateway runs this inline — it reads the live session's root and docs in its own context, dispatches no subagent, pins no model.

### 1. Read the ledger

List root `SESSION-STATE/` with `ls` (or Read a concrete path) — an empty glob result is not evidence of absence, so gate on a listing that errors loudly. Any carry file → **resume**. Folder absent or empty → **cold-orient**.

Read every carry file. Each is one session's independent carry: an empty or conflict-marked file is dead on its own terms and leaves its siblings fully valid.

A root `SESSION-STATE.md` left by the single-file contract reads as one more carry — offer it alongside the rest.

### 2. Resume — offer the carries, act on the user's pick

The user's pick takes a carry — never the ledger's count. Every live carry is offered, a single carry included.

**Gather the offer — reads only.** Per carry, parse the convention's slots and test each pointer: a card ID or doc path that no longer resolves is a gone target (a deleted card = resolved), and a load-bearing pointer gone makes that carry stale. For each other carry, open each card its Read first names (`docs/work/{ID}.md`) and take the last `##` block at that card's end, of any type — its header date and type, plus the first non-empty line under the header as the state — and the header date of the card's latest `## Progress`. A carry that names no card shows `no card` there. Carry age is days since the carry's last commit (`git log -1 --format=%cs -- <file>`), or since its file mtime when the carry is untracked — a checkout resets mtime on a tracked file; that commit or mtime date is the carry's date. Today is `date +%F`. Ledger and cards stay as found until the pick.

**Sort each carry** — the first row that matches wins:

1. **stale** — a load-bearing pointer gone → retire candidate.
2. **passed** — a named card's latest `## Progress` header date is later than the carry's date → retire candidate; the card may already have done the carry's next step.
3. **superseded** — another carry anchors the same card and has a later carry date → retire candidate (the older one).
4. **held** — the carry's Next step, or the latest `## Progress` or `## Design` block of a card it names, holds `not before YYYY-MM-DD` with a date later than today → held until that date. Today ≥ that date → the marker is spent; the carry sorts as live.
5. **live** — none of the above.

**Offer.** Show per live carry: label, anchor, carry age, and each named card's latest-block date + state. Name each held carry with "held until YYYY-MM-DD", outside the resume options. Show each retire candidate with its evidence: stale → the gone pointer; passed → the carry's Next step beside that Progress block's date and first line, so the user judges "already done"; superseded → the newer carry's label and age. A carry whose owning session is long gone reads as a normal carry — its age in the offer is the signal. Ask through one AskUserQuestion call in the session's language:

- **The pick**, single-select: one **resume `<label>`** option per live carry, plus **other work** and **leave**; more options than the tool's cap (4) → offer the youngest carries by carry age as resume options and name the rest in the question text; a free-text answer naming a carry's label — a held carry or a retire candidate included — is a resume pick of that carry.
- **Retire**, multi-select, asked only when a retire candidate exists: one **retire `<label>`** option per candidate; more than the cap → the oldest by carry age as options, the rest named in the question text, where a free-text answer naming a label picks it. No option picked → nothing retired.

Then act on the answers:

- **retire `<label>`** → delete that carry file (`rm SESSION-STATE/<file>`); unpicked candidates stay as found. Runs beside any pick below, leave included.
- **resume `<label>`** → claim it (below), reconstruct it, go to § 4.
- **other work** → claim nothing; hand off to `/super-bootstrap:needs-me`.
- **leave** → claim nothing; end the turn with every unretired carry as found.

No live carry → **cold-orient**, after the held names and the retire question.

**Claim on the resume pick** — rename the picked carry `<label>-<this-session-id>.md`: label kept, id replaced, content untouched. The pick is the gate: a carry the user did not pick keeps its author's id, and a live session's carry is only claimable when the user — who alone knows what else is running — hands it over.

The carry holds the volatile delta + pointers; the card holds the durable state. Reconstruct the picked carry:

- **Follow Read first** — read the card's cold-reader read set `docs/work/README.md` § Thread contract names as the lead, the latest `## Progress` as the resume point (done step, next step, binding watch-outs). Then any other doc the carry names. The picture is the card's current truth, not the carry's echo.

### 3. Cold-orient — no carry

No carries, or no live one → report "no in-flight carry" and hand off to `/super-bootstrap:needs-me`. `docs/work/` absent → "No runway installed. Run `/super-bootstrap:setup`." instead.

### 4. Surface + confirm

After a resume pick, surface the reconstructed picture: where work stopped, the next step, the watch-outs — card first, carry delta beside it. Then **confirm the next step before executing** — this skill orients and hands back; it does not auto-dive. A confirmed card resumes as pickup — framing line + route per the harness doctrine (`.claude/rules/harness.md`; `CLAUDE.md` in a repo not yet split).

## Output

- The shape taken (resume / cold-orient), each held carry as "held until YYYY-MM-DD", and each retire candidate with its evidence.
- Resume, before the pick: the offer per § 2 — one resume option per live carry, plus other work and leave, and the retire question when a candidate exists; nothing claimed or deleted yet.
- After the answers: each retired filename. After a resume pick: the claimed filename, the reconstructed picture (anchor, card lead, next step, watch-outs), and the next step echoed for confirmation. Other work: no claim, the needs-me handoff. Leave: no claim, the ledger as found apart from the retired carries.
- Cold-orient: that no carry was in flight, and the needs-me handoff.

## Rules

- **Write only on the user's pick, bodies read-only.** The § 2 claim rename and the user-picked retirements are this skill's only writes. Bodies stay as authored (rewrite is session-close's park), and every carry the user did not pick stays as found — a concurrent session's live carry included.
- **Orient, don't dive.** Reconstruct the picture and confirm the next step; the user launches the work.
- **Card leads, carry trails.** Read the card's per-type lead blocks before trusting the carry's State; where they disagree, the card wins.
- **Stale carry falls back.** A load-bearing pointer to a gone target invalidates **that** carry — it leaves the resume options for the retire question, its live siblings are offered, and none live → cold-orient. Name the gone pointer; never resume onto a dangling reference.
- **Held carry waits.** A `not before` date later than today keeps the carry out of the resume options and names it with its date; the date's arrival returns it to the offer, with no write.
- **One dead carry leaves the rest alive.** Staleness, emptiness, and conflict markers are per-carry verdicts, never grounds to discard the ledger.
- **Inline procedure.** No argument, no subagent, no model pin.
