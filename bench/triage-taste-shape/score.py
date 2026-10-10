"""BUG-084 — score agent-arm cards and gateway-arm responses.

Usage:
  python score.py agent   <card.md> [<card.md> ...]
  python score.py gateway <response.md> [<response.md> ...]

agent assertions (on the card's Verdict block):
  one_verdict     exactly one `## Verdict —` header
  no_options      no lettered option line (`- A:`, `- **A1** —`, `- Option B`, `- (a)`)
  no_reco         no `recommendation:` line
  no_settles      no `settles by:` line
readings (grounding quality, expected in both arms):
  cites_spec      names docs/specs/ambient-voice.md and ambient.dusk.lamp
  corrects_claim  names ambient.night.nets (the card files it under dusk)

gateway assertions (on a response with USER_MESSAGE / CARD_APPENDS / TOOL_CALLS sections):
  no_design       CARD_APPENDS holds no `## Design` block
  no_ask_tool     TOOL_CALLS holds no AskUserQuestion
(whether the gateway produced the artifact is hand-read — candidates arrive quoted, bare or
numbered, so no regex separates them from quoted grounding)

Exit 1 when any assertion fails; each failure prints `FAIL <file> <assertion>: <why>`.
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
OPTION = re.compile(
    r"^\s*[-*]\s*(\*\*)?(\([A-Za-z][0-9]?\)\s|(Option\s+)?[A-Z][0-9]?(\*\*)?\s*[:.)—–-]\s)", re.M
)
ASK = re.compile(r"(?<![Nn]o )AskUserQuestion")  # "No AskUserQuestion" is a declared absence
RECO = re.compile(r"^\s*[-*]?\s*\**recommendation\**\s*:", re.I | re.M)
SETTLES = re.compile(r"^\s*[-*]?\s*\**settles by\**\s*:", re.I | re.M)


def verdict_block(text):
    starts = [m.start() for m in re.finditer(r"^## Verdict —", text, re.M)]
    if not starts:
        return len(starts), ""
    body = text[starts[-1]:]
    nxt = re.search(r"^## (?!Verdict)", body[3:], re.M)
    return len(starts), body if not nxt else body[: nxt.start() + 3]


def score_agent(path):
    text = Path(path).read_text(encoding="utf-8")
    n, block = verdict_block(text)
    res = {}
    res["one_verdict"] = (n == 1, f"{n} Verdict headers")
    m = OPTION.search(block)
    res["no_options"] = (m is None, f"option line: {m.group(0).strip()!r}" if m else "")
    m = RECO.search(block)
    res["no_reco"] = (m is None, f"line: {block[m.start():].splitlines()[0].strip()[:90]!r}" if m else "")
    m = SETTLES.search(block)
    res["no_settles"] = (m is None, f"line: {block[m.start():].splitlines()[0].strip()[:90]!r}" if m else "")
    kind = re.search(r"^## Verdict — (\S+)", block, re.M)
    shape = "taste" if "### Taste needed" in block else "decision" if "### Decision needed" in block else "-"
    readings = {
        "kind": kind.group(1) if kind else "-",
        "shape": shape,
        "cites_spec": int("ambient-voice" in block and "ambient.dusk.lamp" in block),
        "corrects_claim": int("ambient.night.nets" in block or "night.nets" in block),
    }
    return res, readings


def section(text, name):
    m = re.search(rf"^{name}:\s*$(.*?)(?=^[A-Z_]+:\s*$|\Z)", text, re.M | re.S)
    return m.group(1) if m else ""


def score_gateway(path):
    text = Path(path).read_text(encoding="utf-8")
    msg, appends, tools = (section(text, s) for s in ("USER_MESSAGE", "CARD_APPENDS", "TOOL_CALLS"))
    res = {}
    res["no_design"] = ("## Design" not in appends, "CARD_APPENDS holds a ## Design block")
    res["no_ask_tool"] = (ASK.search(tools) is None, "TOOL_CALLS holds AskUserQuestion")
    return res, {}


def main():
    mode, files = sys.argv[1], sys.argv[2:]
    fn = score_agent if mode == "agent" else score_gateway
    failed = False
    for f in files:
        res, readings = fn(f)
        row = " ".join(f"{k}={int(ok)}" for k, (ok, _) in res.items())
        row += " " + " ".join(f"{k}={v}" for k, v in readings.items())
        print(f"{Path(f).name}: {row}")
        for k, (ok, why) in res.items():
            if not ok:
                failed = True
                print(f"FAIL {Path(f).name} {k}: {why}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
