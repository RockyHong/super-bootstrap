---
name: session-continue
description: "Use at session start to resume in-flight work — reads the root SESSION-STATE/ carry ledger and orients. Carries present → offer every live one, a single carry included, with its age and card state; the user picks resume, other work (→ /super-bootstrap:needs-me), or leave. On resume, follow its Read first into the card it names and read the latest block of each type as the lead, reconstruct where work stopped + the next step, confirm before diving in. None, or every carry pointing at gone targets → report no in-flight carry and hand off to /super-bootstrap:needs-me. Claims a carry only on the user's resume pick — renames it to this session's id so whoever resumes the work also owns closing it; unpicked carries and every carry body stay untouched. No argument; reads current session state. Mirror of /super-bootstrap:session-close."
tags: [session, resume, carry, ledger, session-opener]
---

# Session Continue — Cold-Open Orientation

Mirror of `/super-bootstrap:session-close`: it lands the carry, this picks it up. The read side of the cold-pickup test — "can a cold session orient from files alone?" — run as a procedure. **Consumer** of the `SESSION-STATE/` ledger — reads every carry in it, claims the one the user picks, leaves the rest as found. Naming, slots, and conflict handling follow session-close's § Ledger convention.

## Two entry states

| Detected state | Shape |
|---|---|
| Root `SESSION-STATE/` holds ≥1 carry whose pointers resolve | **resume** — offer the live carries; on a resume pick, claim and reconstruct that carry, confirm the next step |
| Folder absent or empty, OR every carry names gone targets | **cold-orient** — no in-flight carry to take; hand off to `/super-bootstrap:needs-me` |

## Protocol

The gateway runs this inline — it reads the live session's root and docs in its own context, dispatches no subagent, pins no model.

### 1. Read the ledger

List root `SESSION-STATE/` with `ls` (or Read a concrete path) — an empty glob result is not evidence of absence, so gate on a listing that errors loudly. Any carry file → **resume**. Folder absent or empty → **cold-orient**.

Read every carry file. Each is one session's independent carry: an empty or conflict-marked file is dead on its own terms and leaves its siblings fully valid.

A root `SESSION-STATE.md` left by the single-file contract reads as one more carry — offer it alongside the rest.

### 2. Resume — offer the carries, claim on the user's pick

The user's pick takes a carry — never the ledger's count. Every live carry is offered, a single carry included.

**Gather the offer — reads only.** Per carry, parse the convention's slots and test each pointer: a card ID or doc path that no longer resolves is a gone target (a deleted card = resolved), and a load-bearing pointer gone makes that carry stale. For each live carry, open each card its Read first names (`docs/work/{ID}.md`) and take the last `##` block at that card's end, of any type — its header date and type, plus the first non-empty line under the header as the state. A carry that names no card shows `no card` there. Carry age is days since the carry's last commit (`git log -1 --format=%cs -- <file>`), or since its file mtime when the carry is untracked — a checkout resets mtime on a tracked file. Ledger and cards stay as found until the pick.

**Offer.** Show per live carry: label, anchor, carry age, and each named card's latest-block date + state; name each stale carry with its gone pointer, outside the offer. A carry whose owning session is long gone reads as a normal carry — its age in the offer is the signal. Ask the pick through AskUserQuestion in the session's language, single-select: one **resume `<label>`** option per live carry, plus **other work** and **leave**; more options than the tool's cap (4) → offer the youngest carries by carry age as resume options and name the rest in the question text; a free-text answer naming a carry's label is a resume pick of that carry.

- **resume `<label>`** → claim it (below), reconstruct it, go to § 4.
- **other work** → claim nothing; hand off to `/super-bootstrap:needs-me`.
- **leave** → claim nothing; end the turn with the ledger as found.

Every carry stale → **cold-orient**.

**Claim on the resume pick** — rename the picked carry `<label>-<this-session-id>.md`: label kept, id replaced, content untouched. The pick is the gate: a carry the user did not pick keeps its author's id, and a live session's carry is only claimable when the user — who alone knows what else is running — hands it over.

The carry holds the volatile delta + pointers; the card holds the durable state. Reconstruct the picked carry:

- **Follow Read first** — read the card's cold-reader read set `docs/work/README.md` § Thread contract names as the lead, the latest `## Progress` as the resume point (done step, next step, binding watch-outs). Then any other doc the carry names. The picture is the card's current truth, not the carry's echo.

### 3. Cold-orient — no carry

No carries, or every one stale → report "no in-flight carry" and hand off to `/super-bootstrap:needs-me`. `docs/work/` absent → "No runway installed. Run `/super-bootstrap:setup`." instead.

### 4. Surface + confirm

After a resume pick, surface the reconstructed picture: where work stopped, the next step, the watch-outs — card first, carry delta beside it. Then **confirm the next step before executing** — this skill orients and hands back; it does not auto-dive. A confirmed card resumes as pickup — framing line + route per `CLAUDE.md`.

## Output

- The shape taken (resume / cold-orient) and any gone pointers that forced a fallback.
- Resume, before the pick: the offer per § 2 — one resume option per live carry, plus other work and leave; nothing claimed yet.
- After a resume pick: the claimed filename, the reconstructed picture (anchor, card lead, next step, watch-outs), and the next step echoed for confirmation. Other work: no claim, the needs-me handoff. Leave: no claim, the ledger as found.
- Cold-orient: that no carry was in flight, and the needs-me handoff.

## Rules

- **Claim on the resume pick, bodies read-only.** The § 2 rename is this skill's one write. Bodies stay as authored (rewrite is session-close's park, delete its done-close), and unpicked carries stay as found.
- **Orient, don't dive.** Reconstruct the picture and confirm the next step; the user launches the work.
- **Card leads, carry trails.** Read the card's per-type lead blocks before trusting the carry's State; where they disagree, the card wins.
- **Stale carry falls back.** A load-bearing pointer to a gone target invalidates **that** carry — it stays out of the offer, its live siblings are offered, and none live → cold-orient. Name the gone pointer; never resume onto a dangling reference.
- **One dead carry leaves the rest alive.** Staleness, emptiness, and conflict markers are per-carry verdicts, never grounds to discard the ledger.
- **Inline procedure.** No argument, no subagent, no model pin.
