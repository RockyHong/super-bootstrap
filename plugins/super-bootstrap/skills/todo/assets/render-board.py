#!/usr/bin/env python3
"""Mechanical half of /super-bootstrap:todo — classify + rank + render, zero model tokens.

Usage: python render-board.py <project-root> <mode> [--date YYYY-MM-DD]

Modes: needme | full | discuss | cloud | device | harness.

Executes shared/classify-actionable.md plus the todo agent's rank/render protocol
(agents/todo.md, assets/scaffolds.md) mechanically. Those three files are the SSOT —
an edit there propagates HERE and to the todo agent (the dispatch fallback); this
script never redefines a criterion, it only encodes one. Where the spec leaves a
judgment call, the encoding is the documented mechanical reading:

- Approval line   = a line starting "Approv…" inside the latest Design block.
- Ruled fork      = a `## Design` block is where a ruling on a `surface` Verdict
                    lands, so a Design or Plan anywhere on the card clears the
                    Decide row and the Design rules take over. Spec wording is
                    "after it"; the thread contract appends, so on-card reads it.
- Ungrounded card = no Verdict / Design / Plan block, whatever else it carries —
                    the `Triage:` row, same as origin-only.
- Wait override   = the spec's explicit keyword list only; the fuzzy "unresolved ?
                    directed at the user" arm is not encoded (fix the card text —
                    the mislabel doctrine in drain's eligibility.md). The external
                    arm demands a word after the phrase, so `blocked on {party}` in
                    prose about the vocabulary is a mention, not a wait; `blocked by
                    {ID}` stays the hard block below.
- Retired field   = `Actor:` is retired — the mover is the container, not a field
                    (§a "Outward-owned wall"). A card still carrying it classifies
                    by its thread state alone and draws a `# note:` naming it, so a
                    leftover is visible rather than silent.
- Hard block      = the explicit verb forms only (`blocked by {ID}` / `depends on
                    {ID}` / `after {ID} lands`); a bare ID mention is soft signal.
- Soft-coupling direction = the row declaring the shared path in a Design/Plan
                    block is upstream; both/neither → later stage; tie → newer.
                    Adjacency anchors at the upstream row's earned rank.
- Harness subgroup = `apply` only on an explicit bounded-fix marker in the origin
                    (typo / path fix / broken link / formatting / one-line),
                    else `deliberate` (the spec's careful-handle default).
- Venue lane      = with the scale module wired, the need-me partition reads each
                    row's venue off a built-in encoding of the shipped venue-map
                    skeleton (§ venue map below), never the placed file; a placed
                    map whose tables differ draws a stderr notice, not a different
                    board. Unwired, the partition is the intent axis, unchanged.
- Test-queue entry = `### {title}` under `## Pending`; `result:` / `source:`
                    read in the skeleton's bullet + bold-label form
                    (`- **result:** pending`), the bare-label form tolerated.
                    `## Pending` content holding no `### ` entry draws a stderr
                    `# note:`, not a different board.
- Outward entry   = `### OUT-### — {summary}` under `## Entries`; fields read by
                    their bold labels. `unblocks` = 1 when `Owning card:` names an
                    open card, else 0 — leverage signal only: an outward row's
                    Impact stays `quick-pop` (the repo moves nothing here), and its
                    Context cell renders the entry's repo tail. That same
                    `Owning card:` also walls the named card (§a "Outward-owned
                    wall") — the hard-block path: held out of the body in every
                    mode, counted in the footer's `pending unblock`. The group
                    splits on `Waiting on`: the word `author` (word-boundary,
                    case-folded) → `Outward — your move`, any other party →
                    `Outward — waiting on others`.
- Sheet columns   = every board table but Uncategorized carries an `ID` column
                    (card ID / `OUT-###` / `—` for a test-queue row) and its Action
                    cell is the spec's action string with that ID token lifted
                    out, cut to ACTION_WIDTH with `…` (scaffolds.md § Sheet
                    columns). Uncategorized: Action is the file name (or the
                    substrate condition label) cut the same way, its reason a
                    pointer within the same budget.

Exit codes: 0 board rendered · 2 usage · 4 substrate absent.
stdout carries the board only. stderr carries `# sources:` diagnostics plus any
`# note:` lines (venue-map divergence · unparseable `## Pending` content).
"""
import argparse
import datetime
import os
import re
import sys
from typing import NoReturn, Optional, Tuple

# UTF-8 + LF regardless of platform: callers diff this output against LF goldens,
# and Windows text mode would otherwise emit CRLF and mangle non-ASCII.
sys.stdout.reconfigure(encoding="utf-8", newline="\n")  # type: ignore[attr-defined]
sys.stderr.reconfigure(encoding="utf-8", newline="\n")  # type: ignore[attr-defined]

CARD_RE = re.compile(r"^(BUG|DEBT|GAP)-\d+\.md$")
BLOCK_RE = re.compile(r"^## (Amendment|Verdict|Design|Plan|Progress)\b(.*)$")
PATH_TOKEN_RE = re.compile(r"[\w.-]+(?:/[\w.*{}-]+)+/?|[\w-]+\.(?:md|ts|tsx|js|jsx|py|sh|json|css|rs|go)\b")
PATH_EXT_RE = re.compile(r"\.(?:md|ts|tsx|js|jsx|py|sh|json|css|rs|go)$")
UNCAT_REASON = "not a card — see docs/work/README.md § Routing"
WAIT_RE = re.compile(r"needs user|decision required|route\?|waiting on\s+\w|blocked on\s+\w", re.I)
OUT_HEAD_RE = re.compile(r"^(OUT-\d+) — (.+?)\s*$")
OUT_FIELD_RE = re.compile(
    r"^\*\*(Next move|Waiting on|Repo tail — fires on|Owning card):\*\*\s*(.+?)\s*$", re.M)
QUEUE_FIELD_RE = re.compile(
    r"^[ \t]*(?:[-*+][ \t]+)?\*{0,2}(result|source)\*{0,2}:\*{0,2}[ \t]*(.+?)\s*$", re.M)
QUEUE_PLACEHOLDER_RE = re.compile(r"^\*\(empty\b.*\)\*$")
OUT_LOGGED_RE = re.compile(r"\*\*Logged:\*\*\s*([^\n·]*)")
OUT_AUTHOR_RE = re.compile(r"\bauthor\b", re.I)        # `Waiting on` — the your-move arm
RETIRED_ACTOR_RE = re.compile(r"\*\*Actor:\*\*")   # anywhere in the origin — fact fields share a line
CARD_ID_RE = re.compile(r"(?:BUG|DEBT|GAP)-\d+")
SEVERITY_RE = re.compile(r"\b(critical|blocking|production-down|data-loss)\b", re.I)
APPLY_RE = re.compile(r"\b(typo|path fix|broken (?:link|path)|formatting|one-line)\b", re.I)
DEVICE_KEYWORD_RE = re.compile(r"manual test|visual|device|mobile|browser|screenshot", re.I)
DEVICE_PATH_RE = re.compile(r"(?:^|/)(components|app|pages|views)(?:/|$)|apps/(?:web|mobile)(?:/|$)")
LOGIC_PATH_RE = re.compile(r"(?:^|/)(lib|utils|core)(?:/|$)|(?:^|/)packages/[\w-]+(?:/|$)")
HARNESS_PATH_RE = re.compile(
    r"(?:^|/)CLAUDE\.md$|(?:^|/)\.claude/|(?:^|/)SKILL\.md$"
    r"|^plugins/[\w-]+/(?:skills|agents|shared|rules)/"
    r"|^(?:skills|agents|rules|hooks)/")
VERB_PRIORITY = ["Start execute", "Continue execute", "Review", "Manually verify",
                 "Approve design", "Decide", "Outward", "Implement", "Write plan",
                 "Settle design", "Deliberate", "Apply", "Triage"]
STAGE_ORDER = {"raw": 0, "triaged": 1, "aimed": 2, "executing": 3, "review": 4}

# ---------- venue map (scale module) ----------
#
# Built-in encoding of the scale module's phase → run-location map. Provenance: the
# shipped skeleton `skills/harness-bootstrap/assets/scale/rules-venue-map-skeleton.md`
# (§ Venues + § Derivation + § Modality overrides), transcribed once at authoring
# time — the placed `.claude/rules/venue-map.md` is never parsed. `venue()` encodes
# the derivation; VENUE_MAP_TABLES holds the same three tables and feeds the
# divergence notice only.
#
# Divergence normalization = table rows alone (a line whose stripped form opens
# with `|`), cells stripped, separator rows dropped — the table-vs-prose split the
# skeleton states for consumers in its § Consumer boundary; a table cell is what the
# encoding would have to follow, so a table cell edit is what the notice reports.
VENUE_MAP_TABLES = """Venue|Meaning|Cloud-run|Drainable
**T**|Tooling/headless — artifact via tooling alone|yes|yes, in-worktree
**S**|Stack-bound — needs a real runner (emulator/ports/browser), no human|no|via gateway merge-probe
**U**|User-walled — needs human eyes/decision|no|no — halts to user
**P**|Probe/stochastic — LLM-eval, cost-sensitive, non-deterministic|no|no — excluded
Stage|Next phase|Venue
`raw`|Triage|**T**
`triaged`|Implement|derive — § Modality overrides over the card's Verdict block
`aimed`|Execute|derive — § Modality overrides
`executing`|Execute|derive — § Modality overrides
`review`|Review|Test-feel present → § Modality overrides, an unlisted value → **T**; else `Stochastic: llm` → **P**; else **T**
Signal|Effect
`Stochastic: llm`|triage / build / `review` without Test-feel → **P**; plan-write / aim-settle / doc stay **T**
visual-taste acceptance|acting phase → **U** — who accepts this as done? the user's eyes → U (never keyword matching)
`Test-feel: e2e`|verify phase → **S**
`Test-feel: manual`|verify phase → **U**
"""
NEEDME_GROUPS = ("decide", "outward", "waiting", "device", "harness", "probe")
GROUP_HEADINGS = {"decide": "Decide / approve", "outward": "Outward — your move",
                  "waiting": "Outward — waiting on others", "device": "Device-bound",
                  "harness": "Harness", "probe": "Probe / grant"}


def map_tables(text):
    """The placed map's table rows, normalized for the divergence compare."""
    rows = []
    for ln in text.splitlines():
        s = ln.strip()
        if not s.startswith("|"):
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        if all(re.fullmatch(r":?-+:?", c) for c in cells):
            continue
        rows.append("|".join(cells))
    return "\n".join(rows) + "\n"


def die(code, msg) -> NoReturn:
    print(msg, file=sys.stderr)
    sys.exit(code)


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def date_key(s, fallback="0000-00-00"):
    m = re.search(r"\d{4}-\d{2}-\d{2}", s or "")
    return m.group(0) if m else fallback


# ---------- parse ----------

class Block:
    def __init__(self, kind, header, body):
        self.kind = kind                       # Amendment | Verdict | Design | Plan | Progress
        self.header = header                   # text after "## Kind"
        self.body = body
        self.date = date_key(header)

    @property
    def verdict_kind(self):                    # auto-fix | surface | None
        m = re.search(r"\b(auto-fix|surface)\b", self.header)
        return m.group(1) if m else None


class Card:
    def __init__(self, path, text):
        self.path = path
        self.id = os.path.basename(path)[:-3]
        lines = text.splitlines()
        self.title = ""
        for ln in lines:
            m = re.match(r"^# [\w-]+ — (.+)$", ln)
            if m:
                self.title = m.group(1).strip()
                break
        self.blocks = []
        origin_lines, cur = [], None
        for ln in lines:
            m = BLOCK_RE.match(ln)
            if m:
                cur = Block(m.group(1), m.group(2).strip(" —·"), [])
                self.blocks.append(cur)
            elif cur is not None:
                cur.body.append(ln)
            else:
                origin_lines.append(ln)
        for b in self.blocks:
            b.body = "\n".join(b.body)
        self.origin = "\n".join(origin_lines)
        self.fields = {}
        for m in re.finditer(r"\*\*(Logged|Source|Problem|Area|Prior|Test-feel|Stochastic):\*\*\s*([^\n·]*)", self.origin):
            self.fields[m.group(1)] = m.group(2).strip()
        self.text = text

    def latest(self, kind):
        found = [b for b in self.blocks if b.kind == kind]
        return found[-1] if found else None

    def after(self, anchor, kinds):
        """Blocks of the given kinds appended after `anchor`."""
        idx = self.blocks.index(anchor)
        return [b for b in self.blocks[idx + 1:] if b.kind in kinds]

    @property
    def recency(self):
        dates = [b.date for b in self.blocks if b.date != "0000-00-00"]
        return max(dates) if dates else date_key(self.fields.get("Logged", ""))


class Row:
    def __init__(self, action, intent, stage, card=None, verb=None):
        self.action = action
        self.intent = intent                   # Discuss | Cloud | Device | Harness
        self.stage = stage
        self.card = card
        self.verb = verb or action.split(":")[0]
        self.subgroup: Optional[str] = None    # Harness rows: deliberate | apply
        self.outward = False                   # docs/outward.md entry (§c)
        self.owning_card: Optional[str] = None  # outward rows: the open card it walls
        self.waiting_on_author = False         # outward rows: `Waiting on` names the author
        self.context: Optional[str] = None     # Context cell override (outward: repo tail)
        self.progress: Optional[Tuple[int, int]] = None
        self.modality = ("", "")               # (Test-feel, Stochastic) — venue signals
        self.impact = "quick-pop"
        self.blast = "local"
        self.fanout = 0
        self.hard_blocked = False
        self.soft_upstream_of = []             # rows this row shapes
        self.blast_paths = []
        self.recency = "0000-00-00"

    @property
    def blocker(self):
        return "user" if self.intent == "Discuss" else "none"


# ---------- classification (shared/classify-actionable.md) ----------

def paths_in(text):
    """Path-shaped tokens only: a word pair like `NFC/NFD` or `skip/back` in prose
    is not a path — demand a code extension, a trailing slash, or depth ≥ 2."""
    out = []
    for p in PATH_TOKEN_RE.findall(text or ""):
        if PATH_EXT_RE.search(p) or p.endswith("/") or p.count("/") >= 2:
            out.append(p.rstrip("/"))
    return out


def declared_paths(card):
    """Area field + Verdict Files + Plan step paths — the pre-filter's read surface."""
    out = paths_in(card.fields.get("Area", ""))
    v = card.latest("Verdict")
    if v and v.verdict_kind == "auto-fix":
        m = re.search(r"^Files:\s*(.*)$", v.body, re.M)
        if m:
            out += paths_in(m.group(1))
    p = card.latest("Plan")
    if p:
        out += paths_in(p.body)
    return out


def is_harness(card):
    ps = declared_paths(card)
    if not ps:
        return False
    n = sum(1 for p in ps if HARNESS_PATH_RE.search(p))
    return n > 0 and n >= len(ps) - n          # dominant surface; tie → careful-handle


def cloud_safe(row_kind, plan_text, design_text, files_paths):
    """The cloud-safe criterion over a derive row. row_kind: implement|execute|review."""
    if row_kind == "review" and design_text and re.search(r"manual verification|visual check", design_text, re.I):
        return "Device"
    text = plan_text or ""
    if row_kind == "implement":
        ps = files_paths
    else:
        if DEVICE_KEYWORD_RE.search(text):
            return "Device"
        ps = paths_in(text) or files_paths
    if ps:
        if any(DEVICE_PATH_RE.search(p) for p in ps):
            return "Device"
        if all(LOGIC_PATH_RE.search(p) for p in ps):
            return "Cloud"
    # defaults
    if row_kind == "review":
        return "Cloud"
    if row_kind == "execute" and any(DEVICE_PATH_RE.search(p) for p in ps):
        return "Device"
    return "Cloud"


def modality(card):
    """The venue signals a card carries — `(Test-feel, Stochastic)`, case-folded.

    Two surfaces hold them: the origin block's scale-module fact fields
    (`harness-bootstrap/assets/scale/card-fact-fields.md`) and the triage Verdict
    block's `### Test Strategy:` line. The origin field wins — it is the
    capture-time fact, the Verdict a per-phase strategy. An unfilled Verdict
    template value (`unit | e2e`) reads as absent.
    """
    if card is None:
        return "", ""
    tf = card.fields.get("Test-feel", "").strip().lower()
    st = card.fields.get("Stochastic", "").strip().lower()
    if not tf:
        v = card.latest("Verdict")
        m = re.search(r"^#*\s*Test Strategy:\s*(.+?)\s*$", v.body, re.M) if v else None
        if m and "|" not in m.group(1):
            tf = m.group(1).strip().lower()
    return tf, st


def classify_card(card):
    """Thread-state derivation §a — first rule that matches."""
    label = f"{card.id} {card.title}"
    verdict = card.latest("Verdict")
    design = card.latest("Design")
    plan = card.latest("Plan")
    files_paths = []
    if verdict and verdict.verdict_kind == "auto-fix":
        m = re.search(r"^Files:\s*(.*)$", verdict.body, re.M)
        files_paths = paths_in(m.group(1)) if m else []
    design_text = design.body if design else ""

    if not (verdict or design or plan):
        row = Row(f"Triage: {label}", "Cloud", "raw", card, "Triage")
    elif verdict and verdict.verdict_kind == "surface" and not (design or plan):
        row = Row(f"Decide: {label} — triage verdict", "Discuss", "raw", card, "Decide")
    elif verdict and verdict.verdict_kind == "auto-fix" and not card.after(verdict, ("Design", "Plan")):
        intent = cloud_safe("implement", None, design_text, files_paths)
        row = Row(f"Implement: {label}", intent, "triaged", card, "Implement")
    elif design and not re.search(r"^\s*\*{0,2}Approv", design.body, re.M | re.I):
        row = Row(f"Approve design: {label}", "Discuss", "aimed", card, "Approve design")
    elif design and not card.after(design, ("Plan",)):
        verb = "Continue execute" if card.after(design, ("Progress",)) else "Start execute"
        intent = cloud_safe("execute", None, design_text, files_paths)
        row = Row(f"{verb}: {label}", intent, "aimed", card, verb)
    else:
        progress = [b for b in card.after(plan, ("Progress",))] if plan else []
        steps = re.findall(r"^\d+\.\s+(.*)$", plan.body, re.M) if plan else []
        if not progress:
            intent = cloud_safe("execute", plan.body, design_text, files_paths)
            row = Row(f"Start execute: {label}", intent, "executing", card, "Start execute")
        else:
            done = sum(1 for i, s in enumerate(steps, 1)
                       if re.search(rf"\bstep {i}\b|\b{i} and \d|\b\d and {i}\b", progress[-1].body, re.I)
                       or key_phrase_done(s, progress[-1].body))
            if done >= len(steps) and steps:
                intent = cloud_safe("review", plan.body, design_text, files_paths)
                row = Row(f"Review: {label}", intent, "review", card, "Review")
            else:
                intent = cloud_safe("execute", plan.body, design_text, files_paths)
                row = Row(f"Continue execute: {label} ({done}/{len(steps)})", intent,
                          "executing", card, "Continue execute")
                row.progress = (done, len(steps))

    # wait override — the user or a named external party (keyword arm; an unruled
    # surface Verdict already carries the Decide shape)
    if row.verb != "Decide":
        lead = card.blocks[-1].body if card.blocks else card.origin
        m = WAIT_RE.search(card.origin) or WAIT_RE.search(lead)
        if m:
            src = m.string
            clause = re.split(r"[.\n]", src[m.start():], 1)[0].strip()
            row = Row(f"Decide: {label} — {clause}", "Discuss", row.stage, card, "Decide")

    # harness pre-filter wins intent AND action whatever the verb/state
    # (spec §Harness pre-filter: Action: `Deliberate: {topic}` / `Apply: {rule} → {site}`)
    if is_harness(card):
        origin_probe = (card.fields.get("Problem", "") + " " + card.fields.get("Prior", ""))
        subgroup = "apply" if APPLY_RE.search(origin_probe) else "deliberate"
        verb = "Apply" if subgroup == "apply" else "Deliberate"
        hrow = Row(f"{verb}: {card.title}", "Harness", row.stage, card, verb)
        hrow.subgroup, hrow.progress = subgroup, row.progress
        row = hrow
    row.recency = card.recency
    row.modality = modality(card)
    return row


def key_phrase_done(step, progress_text):
    """A Progress names a step by its lead phrase — match the step's first 3+ significant words."""
    words = [w for w in re.findall(r"[a-z]{3,}", step.lower()) if w not in ("the", "and", "for")]
    if len(words) < 2:
        return False
    hits = sum(1 for w in words[:4] if w in progress_text.lower())
    return hits >= min(3, len(words[:4]))


def classify_queue(queue_text, cards_by_id):
    rows, suppressed = [], set()
    pending = re.split(r"^## ", queue_text, flags=re.M)
    for section in pending:
        if not section.startswith("Pending"):
            continue
        for entry in re.split(r"^### ", section, flags=re.M)[1:]:
            lines = entry.splitlines()
            title = lines[0].strip()
            body = "\n".join(lines[1:])
            fields = {}
            for label, value in QUEUE_FIELD_RE.findall(body):
                fields.setdefault(label.lower(), value)
            if not fields.get("result", "").lower().startswith("pending"):
                continue
            row = Row(f"Manually verify: {title}", "Device", "review", None, "Manually verify")
            m = re.match(r"(?:BUG|DEBT|GAP)-\d+", fields.get("source", ""))
            if m:
                suppressed.add(m.group(0))
                src = cards_by_id.get(m.group(0))
                if src:
                    row.blast_paths = paths_in(src.fields.get("Area", ""))
                    row.modality = modality(src)
            rows.append(row)
    return rows, suppressed


def pending_unparseable(queue_text):
    """True when `## Pending` holds content (not blanks, not the skeleton placeholder)
    but no `### ` entry heading — the shape the parser cannot read at all."""
    m = re.search(r"^## Pending\s*$", queue_text, re.M)
    if not m:
        return False
    tail = queue_text[m.end():]
    nxt = re.search(r"^## ", tail, re.M)
    if nxt:
        tail = tail[:nxt.start()]
    lines = [l.strip() for l in tail.splitlines()]
    content = [l for l in lines if l and not QUEUE_PLACEHOLDER_RE.match(l)]
    return bool(content) and not any(l.startswith("### ") for l in content)


def classify_outward(text, cards_by_id):
    """Thread-state derivation §c — outward entries under `## Entries`."""
    rows = []
    m = re.search(r"^## Entries\s*$", text, re.M)
    if not m:
        return rows
    tail = text[m.end():]
    nxt = re.search(r"^## ", tail, re.M)
    if nxt:
        tail = tail[:nxt.start()]
    for chunk in re.split(r"^### ", tail, flags=re.M)[1:]:
        head, _, body = chunk.partition("\n")
        h = OUT_HEAD_RE.match(head)
        if not h:
            continue
        f = dict(OUT_FIELD_RE.findall(body))
        row = Row(f"Outward: {h.group(1)} {h.group(2)} — {f.get('Next move', '—')}"
                  f" · waiting on {f.get('Waiting on', '—')}", "Discuss", "raw", None, "Outward")
        row.outward = True
        row.context = f.get("Repo tail — fires on")
        owner = CARD_ID_RE.search(f.get("Owning card", ""))
        row.owning_card = owner.group(0) if owner and owner.group(0) in cards_by_id else None
        row.fanout = 1 if row.owning_card else 0
        row.waiting_on_author = bool(OUT_AUTHOR_RE.search(f.get("Waiting on", "")))
        lg = OUT_LOGGED_RE.search(body)
        row.recency = date_key(lg.group(1) if lg else "")
        rows.append(row)
    return rows


# ---------- impact / blast / coupling (agents/todo.md §3–§4) ----------

def module_root(p):
    parts = p.strip("/").split("/")
    return "/".join(parts[:2]) if len(parts) > 1 else parts[0]


def compute_blast(row):
    if row.intent == "Harness":
        row.blast = "repo"
        return
    if row.intent == "Discuss":                # Discuss rows omit Blast (agent §3)
        row.blast = "—"
        return
    ps = row.blast_paths or (declared_paths(row.card) + paths_in(
        "\n".join(b.body for b in row.card.blocks)) if row.card else [])
    ps = [p for p in ps if "/" in p or "." in p]
    pkgs = {m.group(0) for p in ps for m in [re.match(r"(?:packages|apps)/[\w-]+", p)] if m}
    roots = {module_root(p) for p in ps}
    if any(HARNESS_PATH_RE.search(p) for p in ps):
        row.blast = "repo"
    elif len(pkgs) >= 2:
        row.blast = "cross-pkg"
    elif len(roots) >= 2:
        row.blast = "pkg"
    else:
        row.blast = "local"


def compute_impact(row):
    if row.outward:            # fan-out is leverage signal only; the repo moves nothing here
        row.impact = "quick-pop"
        return
    card = row.card
    imp = False
    if row.soft_upstream_of or row.fanout:
        imp = True
    if row.verb in ("Approve design", "Write plan", "Settle design") and card and card.id.startswith("GAP"):
        imp = True
    if row.verb in ("Start execute", "Continue execute") and row.progress and \
            row.progress[1] - row.progress[0] >= 3:
        imp = True
    if row.blast in ("cross-pkg", "repo") and row.intent != "Harness" and row.verb != "Triage":
        imp = True
    if card and SEVERITY_RE.search(card.origin):
        imp = True
    if row.verb == "Deliberate":
        imp = True
    if row.verb == "Implement" and card:
        v = card.latest("Verdict")
        if v and re.search(r"^Execution:\s*full", v.body, re.M):
            imp = True
    row.impact = "impactful" if imp else "quick-pop"


def wall_owned_cards(rows):
    """§a "Outward-owned wall" — an outward entry whose `Owning card:` names an open
    card walls that card: the hard-block path, so the card row is held out of the
    body in every mode and counted in the footer's `pending unblock` until the entry
    closes. The entry's own `unblocks` fanout is untouched — that stays the leverage
    signal (§c), not a second wall. Runs before `couple()`, so a walled card is out
    of the soft-coupling pass exactly like any other hard-blocked row."""
    by_id = {r.card.id: r for r in rows if r.card}
    for r in rows:
        if not (r.outward and r.owning_card):
            continue
        owned = by_id.get(r.owning_card)
        if owned is not None:
            owned.hard_blocked = True


def couple(rows):
    """Hard blocks (explicit verb forms) + soft coupling (shared declared paths)."""
    by_id = {r.card.id: r for r in rows if r.card}
    for r in rows:
        if not r.card:
            continue
        # one (blocker, blocked) pair counts once however many times the thread restates it
        blockers = {m.group(1).upper() for m in re.finditer(
            r"(?:blocked by|depends on|after)\s+((?:BUG|DEBT|GAP)-\d+)(?:\s+lands)?", r.card.text, re.I)}
        for bid in sorted(blockers):
            target = by_id.get(bid)
            if target and target is not r:
                r.hard_blocked = True
                target.fanout += 1
    for a in rows:
        if not a.card or a.hard_blocked:
            continue
        a_declared = {p for b in a.card.blocks if b.kind in ("Design", "Plan")
                      for p in paths_in(b.body)}
        if not a_declared:
            continue
        for b in rows:
            if b is a or not b.card or b.hard_blocked:
                continue
            b_surface = set(paths_in(b.card.fields.get("Area", "")))
            shared = {p for p in a_declared for q in b_surface if p == q or p in q or q in p}
            if shared and not any(  # direction: declarer is upstream unless b also declares it
                    p in {x for blk in b.card.blocks if blk.kind in ("Design", "Plan")
                          for x in paths_in(blk.body)} for p in shared):
                a.soft_upstream_of.append(b)
                a.fanout += 1


# ---------- rank / render ----------

def verb_rank(v):
    return VERB_PRIORITY.index(v) if v in VERB_PRIORITY else len(VERB_PRIORITY)


def sort_rows(rows, with_fanout):
    def key(r):
        prog = (r.progress[0] / r.progress[1]) if r.progress and r.progress[1] else -1
        k = [0 if r.impact == "impactful" else 1, -prog, verb_rank(r.verb), r.recency]
        k[-1] = "".join(chr(255 - ord(c)) for c in r.recency)      # recency desc
        if with_fanout:
            k.insert(0, -r.fanout)
        return k
    ranked = sorted(rows, key=key)
    for up in [r for r in ranked if r.soft_upstream_of]:           # adjacency: downstream
        for down in up.soft_upstream_of:                            # directly beneath upstream
            if down in ranked:
                ranked.remove(down)
                ranked.insert(ranked.index(up) + 1, down)
    return ranked


def table(headers, rows_cells):
    out = ["| " + " | ".join(headers) + " |",
           "| " + " | ".join("--" for _ in headers) + " |"]
    for cells in rows_cells:
        out.append("| " + " | ".join(cells) + " |")
    return "\n".join(out)


def prog_cell(r):
    return f"{r.progress[0]}/{r.progress[1]}" if r.progress else "—"


ACTION_WIDTH = 60          # Action cell budget — keeps a row inside one terminal line
ID_TOKEN_RE = re.compile(r"\b(?:BUG|DEBT|GAP|OUT)-\d+\b")


def id_cell(r):
    if r.card:
        return r.card.id
    m = ID_TOKEN_RE.search(r.action)
    return m.group(0) if m else "—"


def cut(s):
    """Hard-cut a cell to ACTION_WIDTH, the last char `…` (no word-boundary
    search) — scaffolds.md § Sheet columns."""
    return s if len(s) <= ACTION_WIDTH else s[:ACTION_WIDTH - 1] + "…"


def action_cell(r):
    """The spec's action string with its ID token lifted into the ID column,
    cut to ACTION_WIDTH — the ID column plus the card hold the rest."""
    rid = id_cell(r)
    s = r.action.replace(f"{rid} ", "", 1) if rid != "—" else r.action
    return cut(s)


def context_cell(r):
    sent = r.context or re.split(
        r"(?<=\.)\s", (r.card.fields.get("Problem", "") if r.card else ""))[0].strip()
    if len(sent) > 80:
        sent = sent[:77] + "…"
    return f"{sent} (unblocks {r.fanout})" if r.fanout else (sent or "—")


def venue(row):
    """The row's next-phase venue — § Derivation over its stage, downgraded by
    § Modality overrides (VENUE_MAP_TABLES). Judgment the tables leave open, and
    the mechanical reading taken here:

    - visual-taste acceptance is explicitly "never keyword matching" and no fact
      field carries it, so it is not encoded — a card that wants the **U** lane
      declares `Test-feel: manual`.
    - a modality field gates only its own phase: `Test-feel` gates verify, so a
      build phase (`triaged` / `aimed` / `executing`) is never downgraded by it.
    - at the verify phase `Test-feel` decides when the card carries one, so a
      modality the overrides table does not list (`unit` / `doc-only`) stays **T**;
      with no `Test-feel`, `Stochastic: llm` downgrades the phase to **P**, the
      same signal the triage / build phases read from § Modality overrides.
    - a `Manually verify` row IS the review row's manual-verification arm,
      whatever fields its back-pointed card carries.
    """
    tf, st = row.modality
    if row.verb == "Manually verify":
        return "S" if tf == "e2e" else "U"
    if row.stage == "review":
        if tf == "manual":
            return "U"
        if tf == "e2e":
            return "S"
        if tf:
            return "T"
        return "P" if st == "llm" else "T"
    return "P" if st == "llm" else "T"


def outward_group(row):
    """§ Lane split, outward arm: `Waiting on` naming the author is the author's own
    move, every other party is a wait — one axis, two groups."""
    return "outward" if row.waiting_on_author else "waiting"


def wired_lane(row):
    """§ Lane split, venue-map-wired arm: venue → lane, with `intent: Harness`,
    `intent: Discuss`, and an outward source each winning over the venue."""
    if row.intent == "Harness":
        return "need-me", "harness"
    if row.outward:
        return "need-me", outward_group(row)
    if row.intent == "Discuss":
        return "need-me", "decide"
    v = venue(row)
    if v in ("T", "S"):
        return "drainable", None
    if v == "P":
        return "need-me", "probe"
    device = row.modality[0] == "manual" or row.verb == "Manually verify"
    return "need-me", ("device" if device else "decide")


def unwired_lane(row):
    """§ Lane split, venue-map-absent arm: the intent axis (no `probe` group —
    **P** folds into the cloud-safe axis, **S** into Device)."""
    if row.intent == "Cloud":
        return "drainable", None
    if row.outward:
        return "need-me", outward_group(row)
    if row.intent == "Discuss":
        return "need-me", "decide"
    if row.intent == "Device":
        return "need-me", "device"
    return "need-me", "harness"


def partition(rows, wired):
    """Drainable rows + the need-me groups in the scaffold's fixed order."""
    drainable, by_group = [], {g: [] for g in NEEDME_GROUPS}
    for r in rows:
        lane, group = wired_lane(r) if wired else unwired_lane(r)
        (drainable if lane == "drainable" else by_group[group]).append(r)
    return drainable, [(GROUP_HEADINGS[g], by_group[g]) for g in NEEDME_GROUPS]


def render(mode, rows, uncat, held_count, date, wired=False):
    body_rows = [r for r in rows if not r.hard_blocked]
    counts = {k: sum(1 for r in body_rows if r.intent == k) for k in ("Discuss", "Cloud", "Device", "Harness")}
    total = sum(counts.values())
    macro = (f"Macro: Discuss {counts['Discuss']} · Cloud {counts['Cloud']} · "
             f"Device {counts['Device']} · Harness {counts['Harness']} · Full {total}")
    out = []
    uncat_section = ""
    if uncat:
        uncat_section = "\n\n## Uncategorized\n\n" + table(
            ["#", "Action", "Why ambiguous"],
            [[str(i + 1), cut(name), reason] for i, (name, reason) in enumerate(uncat)])

    if mode == "needme":
        drainable, grouped = partition(body_rows, wired)
        needme = [r for _, grp in grouped for r in grp]
        if not needme and not drainable and not uncat and not held_count:
            return f"# To-Do — {date}\n\nNo active work. Ground something with /super-bootstrap:log or give me a task."
        out.append(f"# To-Do — {date}")
        out.append(f"Drainable: {len(drainable)}  →  /super-bootstrap:drain\n")
        if needme:
            out.append("▸ Need me")
            for heading, grp in grouped:
                if not grp:
                    continue
                ranked = sort_rows(grp, with_fanout=True)
                out.append(f"\n## {heading}\n\n" + table(
                    ["#", "ID", "Action", "unblocks", "Impact", "Blast"],
                    [[str(i + 1), id_cell(r), action_cell(r), str(r.fanout), r.impact, r.blast]
                     for i, r in enumerate(ranked)]))
        else:
            out.append("Nothing needs you right now — the board is all auto-runnable.")
        if uncat_section:
            out.append(uncat_section.strip("\n"))
        footer = []
        if held_count:
            footer.append(f"pending unblock: {held_count}")
        footer.append("flat list: /super-bootstrap:todo full · drainable detail: /super-bootstrap:todo cloud"
                      if needme else "flat list: /super-bootstrap:todo full")
        footer.append("more: /super-bootstrap:help")
        out.append("\n".join(footer))
        return "\n\n".join(s for s in out if s).replace("\n\n\n", "\n\n")

    if mode == "full":
        if not body_rows and not uncat:
            return f"# To-Do — {date}\n\nNo active work. Ground something with /super-bootstrap:log or give me a task."
        ranked = sort_rows(body_rows, with_fanout=False)
        out.append(f"# To-Do — {date}")
        out.append(table(["#", "ID", "Action", "Stage", "Progress", "Blocker", "Impact", "Blast"],
                         [[str(i + 1), id_cell(r), action_cell(r), r.stage, prog_cell(r), r.blocker,
                           r.impact, r.blast] for i, r in enumerate(ranked)]))
        if uncat_section:
            out.append(uncat_section.strip("\n"))
        footer = []
        if held_count:
            footer.append(f"pending unblock: {held_count}")
        if total >= 6:
            footer.append("filter: /super-bootstrap:todo cloud (headless) · /super-bootstrap:todo device "
                          "(needs screen) · /super-bootstrap:todo discuss (decisions) · /super-bootstrap:todo harness (engine)")
        footer.append("more: /super-bootstrap:help")
        out.append("\n".join(footer))
        return "\n\n".join(out)

    # sub-verb modes
    intent = {"discuss": "Discuss", "cloud": "Cloud", "device": "Device", "harness": "Harness"}[mode]
    kept = sort_rows([r for r in body_rows if r.intent == intent], with_fanout=False)
    out.append(f"# To-Do ({intent}) — {date}")
    out.append(macro)
    if not kept:
        empty_line = {"discuss": "Nothing to decide.", "cloud": "Nothing cloud-runnable.",
                      "device": "Nothing device-only.", "harness": "Nothing harness-pending."}[mode]
        out.append(empty_line)
        priors = []
        for other in ("Discuss", "Cloud", "Device", "Harness"):
            if other == intent:
                continue
            top = sort_rows([r for r in body_rows if r.intent == other], with_fanout=False)[:3]
            cell = "; ".join(f"{r.card.id if r.card else r.action}: {context_cell(r)}" for r in top) or "0"
            priors.append(f"- {other}: {cell}")
        out.append("Macro priors (no recommendation):\n" + "\n".join(priors))
        others = [m for m in ("discuss", "cloud", "device", "harness") if m != mode]
        out.append("Next mode: yours. " + " · ".join(f"/super-bootstrap:todo {m}" for m in others)
                   + " · /super-bootstrap:todo (full board)")
    elif mode == "discuss":
        out.append(table(["#", "ID", "Action", "Impact", "Context"],
                         [[str(i + 1), id_cell(r), action_cell(r), r.impact, context_cell(r)]
                          for i, r in enumerate(kept)]))
    elif mode == "harness":
        out.append("Engine surface — careful handle. Ground in git log + the repo's rules "
                   "before editing; harness edits carry a verify pass.")
        for sub in ("deliberate", "apply"):
            grp = [r for r in kept if r.subgroup == sub]
            if grp:
                out.append(f"## {sub.capitalize()}\n\n" + table(
                    ["#", "ID", "Action", "Progress", "Impact", "Blast"],
                    [[str(i + 1), id_cell(r), action_cell(r), prog_cell(r), r.impact, r.blast]
                     for i, r in enumerate(grp)]))
    else:
        out.append(table(["#", "ID", "Action", "Progress", "Impact", "Blast"],
                         [[str(i + 1), id_cell(r), action_cell(r), prog_cell(r), r.impact, r.blast]
                          for i, r in enumerate(kept)]))
    if uncat_section:
        out.append(uncat_section.strip("\n"))
    footer = []
    if held_count:
        footer.append(f"pending unblock: {held_count}")
    footer.append("more: /super-bootstrap:help")
    out.append("\n".join(footer))
    return "\n\n".join(out)


# ---------- main ----------

def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("root")
    ap.add_argument("mode", choices=["needme", "full", "discuss", "cloud", "device", "harness"])
    ap.add_argument("--date", default=datetime.date.today().isoformat())
    try:
        args = ap.parse_args()
    except SystemExit:
        die(2, "usage: render-board.py <project-root> <mode> [--date YYYY-MM-DD]")

    placed_map = os.path.join(args.root, ".claude/rules/venue-map.md")
    wired = os.path.isfile(placed_map)
    if wired and map_tables(read(placed_map)) != VENUE_MAP_TABLES:
        print("# note: local venue-map edits are not honored by the script lane "
              "(map differs from the shipped skeleton)", file=sys.stderr)
    work = os.path.join(args.root, "docs/work")
    if not os.path.isdir(work):
        die(4, "# defer: docs/work absent — skip-gate should have caught this")

    uncat, rows = [], []
    readme = os.path.join(work, "README.md")
    if not os.path.isfile(readme) or "ID high-water mark" not in read(readme):
        uncat.append(("docs/work/ substrate",
                      "substrate missing — run /super-bootstrap:harness-bootstrap"))

    cards = {}
    for name in sorted(os.listdir(work)):
        if name in ("README.md", "TEMPLATE.md") or not name.endswith(".md"):
            continue
        if CARD_RE.match(name):
            cards[name[:-3]] = Card(os.path.join(work, name), read(os.path.join(work, name)))
        else:
            uncat.append((name, UNCAT_REASON))

    for cid, card in cards.items():          # sorted — the listdir order above
        if RETIRED_ACTOR_RE.search(card.origin):
            print(f"# note: {cid} carries the retired Actor: field — move the item "
                  "to docs/outward.md", file=sys.stderr)

    queue_rows, suppressed = [], set()
    queue_path = os.path.join(args.root, "docs/test-queue.md")
    if os.path.isfile(queue_path):
        queue_text = read(queue_path)
        queue_rows, suppressed = classify_queue(queue_text, cards)
        if pending_unparseable(queue_text):
            print("# note: docs/test-queue.md `## Pending` holds content but no "
                  "`### ` entries — reshape them to its `## Entry shape` "
                  "(`### {title}` + `- **result:** pending`)", file=sys.stderr)

    outward_rows = []
    outward_path = os.path.join(args.root, "docs/outward.md")
    if os.path.isfile(outward_path):
        outward_rows = classify_outward(read(outward_path), cards)

    for cid, card in cards.items():
        if cid in suppressed:
            continue
        rows.append(classify_card(card))
    rows += queue_rows
    rows += outward_rows

    wall_owned_cards(rows)
    couple(rows)
    for r in rows:
        compute_blast(r)
    for r in rows:
        compute_impact(r)
    held = sum(1 for r in rows if r.hard_blocked)

    print(render(args.mode, rows, uncat, held, args.date, wired))
    print(f"# sources: docs/work ({len(cards)} cards); test-queue ({len(queue_rows)} entries); "
          f"outward ({len(outward_rows)} entries); held {held}", file=sys.stderr)


if __name__ == "__main__":
    main()
