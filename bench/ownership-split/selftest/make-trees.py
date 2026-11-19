#!/usr/bin/env python3
"""DEBT-ymdg — hand-made result trees for score.py's bite check.

Usage: python3 make-trees.py <outdir>
Writes <outdir>/asset/harness.md (the "shipped asset" the trees are scored
against), one result tree per case under <outdir>/trees/, and
<outdir>/expected.tsv: `name<TAB>valid<TAB>pass<TAB>substring the reason must carry`.

Each walk has one conforming tree (pass 1) and at least one violating tree per
expected property (pass 0, reason names the property). The trees are built at
selftest time rather than committed: one of them carries CRLF bytes, and this
repo's `* text=auto eol=lf` would normalise a committed copy to LF.
"""
import io
import json
import os
import sys

OUT = sys.argv[1]
OWNED = ".claude/rules/harness.md"
RECEIPT = ".claude/super-bootstrap-runway.json"
PLUGIN_DIR = "D:/dev/super-bootstrap/plugins/super-bootstrap"

ASSET = "## Development Workflow\n\nWork enters by picking up a card.\n\n## Git Notes\n\n- Atomic commits.\n"
OLDER = "## Development Workflow\n\nWork enters by picking up a card.\n"
FORK = OLDER + "\n## Local Additions\n\n- Hand edit by the consumer.\n"

CLAUDE_SPLIT = ("# decimate\n\n## Rules (auto-load on file match)\n\nrules index\n\n## Tech Stack\n\nPython 3.\n\n"
                "## Monorepo — Cross-Package Build Pre-flight\n\npnpm.\n\n"
                "## Commands\n\n```bash\n## not a heading: inside a fence\npython3 run_tests.py\n```\n\n## Planning\n\n- docs\n")
CLAUDE_LEGACY = "# decimate\n\n## Development Workflow\n\nWork enters by a card.\n\n" + CLAUDE_SPLIT.split("\n\n", 1)[1]
COVERED_SPLIT = [u"CLAUDE.md \u00a7 Rules", u"CLAUDE.md \u00a7 Planning", u"docs/overview.md \u00a7 Problem", OWNED]

FRESH_DONE = "**Generic runway installed.** CLAUDE.md drives workflow."
LEGACY_STOP = ("Stopped, nothing written. This repo is in the pre-split shape: `CLAUDE.md` still holds "
               "plugin-owned sections and `.claude/rules/harness.md` is absent.")
STALE_DONE = ("| .claude/rules/harness.md | \u26a0 drifted | updated (stale) |\n\n"
              "**Pipeline synced.** 1 items updated, 22 already current.")
FORK_ASK = ("Found: `.claude/rules/harness.md` (sha 46049fbd) carries content this pipeline did not place.\n"
            "Expected: the file as the last sync placed it (2869c871).\n"
            "Pick: `overwrite` re-places the asset verbatim; `keep` leaves the file as it stands "
            "(holds for this sync only).")
FORK_DONE_T2 = "`.claude/rules/harness.md` \u26a0 drifted \u2192 updated (fork, overwritten). **Pipeline synced.**"
SECTION_PROMPT = (".claude/rules/harness.md sync \u2014 drift detected:\n\n  [Git Notes] section drifted from current "
                  "template:\n  - old line\n  + new line\n\n  Update? (y / n \u2014 {reason} / show full diff)")
UNRELATED_PROMPT = (STALE_DONE + "\n\n" + ("Per-section comparison rows follow for the other files.\n" * 20)
                    + "\ndocs/work/README.md sync \u2014 drift detected:\n\n  [ID shape] section drifted.\n\n"
                      "  Update? (y / n \u2014 {reason} / show full diff)")

# --- prompt-block cases: the owned file must be named INSIDE the prompt's own block ---
# The shape of a real `stale` run that the old proximity window (800 chars back)
# failed: the run's summary names the owned file, and a separate prompt, a few
# lines below, is about another doc.
SUMMARY_NAMES_OWNED = (
    "**Done:**\n"
    "- `.claude/rules/harness.md` was stale and untouched since placement, so I re-copied it.\n"
    "- I updated the `.claude/super-bootstrap-runway.json` `placed` hash for `harness.md`.\n\n")
TECHSTACK_PROMPT_BODY = (
    "docs/techstack.md sync — pipeline-owned section absent:\n\n"
    "  [Framework] in the current skeleton, missing here:\n"
    "  ## Framework\n\n  none\n\n"
    "  Insert at the skeleton's position (after § Runtime, before § Key Dependencies)? (y / n — {reason})\n")
QUESTION_LABEL = "**Question that needs your answer (nothing written for it):**\n\n"
SUMMARY_THEN_FENCED_PROMPT = (SUMMARY_NAMES_OWNED + QUESTION_LABEL + "```\n" + TECHSTACK_PROMPT_BODY + "```\n\n"
                              "My recommendation is `y`.")
# the same, unfenced: the skill's prompt format (file-naming header line, indented body)
SUMMARY_THEN_PLAIN_PROMPT = SUMMARY_NAMES_OWNED + TECHSTACK_PROMPT_BODY
# the same question as plain prose under its own label line
SUMMARY_THEN_LABELLED_PROSE = (SUMMARY_NAMES_OWNED + QUESTION_LABEL
                               + "`docs/techstack.md` has no `## Framework` section. Insert it? (y / n)\n")
FENCED_OWNED_PROMPT = "Everything else is current.\n\n```\n" + SECTION_PROMPT + "\n```\n"
# the shape of a real `fork` run: a label line names the file, the pick sits paragraphs below
FORK_LABELLED = (
    "**Checked and left unchanged:**\n- The three hook scripts match the shipped assets.\n\n"
    "**Question 1: `%s` is a fork.**\n"
    "Found: its sha256 (CR removed) is `a4aeba58`. The shipped asset's is `cadfd63a`.\n\n"
    "Expected: the copy the last sync placed, `712493a1`.\n\n"
    "Pick:\n- `overwrite` re-places the asset and drops the local line.\n"
    "- `keep` leaves the file as it is for this sync only.\n\n"
    "**Question 2: `docs/techstack.md` has no `## Framework` section.**\nInsert? (y / n — {reason})\n")
FORK_LABELLED_OWNED = FORK_LABELLED % OWNED
# an overwrite-or-keep pick about ANOTHER file, with the owned file named in the summary above it
FORK_LABELLED_OTHER = SUMMARY_NAMES_OWNED.replace("was stale and untouched since placement, so I re-copied it",
                                                  "is current") + FORK_LABELLED % ".claude/hooks/commit-channel.sh"


def put(path, data, raw=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with io.open(path, "wb") as fh:
        fh.write(data if raw else data.encode("utf-8"))


def stream(texts, error=False, result=True, plugins="dev"):
    evs = []
    plist = [{"name": "cc-plugin-privacy", "path": "builtin"}]
    if plugins == "dev":
        plist.append({"name": "super-bootstrap", "path": PLUGIN_DIR})
    elif plugins == "cache":
        plist.append({"name": "super-bootstrap", "path": "C:/Users/x/.claude/plugins/cache/super-bootstrap/6.0.1"})
    evs.append({"type": "system", "subtype": "init", "session_id": "s1", "plugins": plist})
    for t in texts:
        evs.append({"type": "assistant", "parent_tool_use_id": None,
                    "message": {"role": "assistant", "content": [{"type": "text", "text": t}]}})
    if result:
        evs.append({"type": "result", "subtype": "error_during_execution" if error else "success",
                    "is_error": bool(error), "permission_denials": [], "result": texts[-1] if texts else ""})
    return "".join(json.dumps(e, ensure_ascii=False) + "\n" for e in evs)


CASES = []   # (name, valid, pass, reason-substring)


def tree(name, valid, pas, reason, files=None, texts=None, meta=None, stream_kw=None, t2=None, no_stream=False):
    d = os.path.join(OUT, "trees", name)
    os.makedirs(os.path.join(d, "repo"), exist_ok=True)
    for rel, data in (files or {}).items():
        put(os.path.join(d, "repo", rel), data, raw=isinstance(data, bytes))
    m = {"plugin-dir.txt": PLUGIN_DIR + "\n"}
    m.update(meta or {})
    for rel, data in m.items():
        if data is not None:
            put(os.path.join(d, "meta", rel), data)
    if not no_stream:
        put(os.path.join(d, "stream.jsonl"), stream(texts or [], **(stream_kw or {})))
    if t2 is not None:
        put(os.path.join(d, "stream.t2.jsonl"), stream(t2))
    CASES.append((name, valid, pas, reason))


def receipt(covered):
    return json.dumps({"version": "6.0.1", "covered": covered, "declined": [], "placed": {}},
                      indent=2, ensure_ascii=False) + "\n"


# --- fresh -------------------------------------------------------------------------
def fresh(**over):
    f = {OWNED: ASSET, "CLAUDE.md": CLAUDE_SPLIT, RECEIPT: receipt(COVERED_SPLIT)}
    f.update(over)
    return {k: v for k, v in f.items() if v is not None}


tree("fresh-ok", "1", "1", "ok", fresh(), [FRESH_DONE])
tree("fresh-ok-crlf", "1", "1", "ok", fresh(**{OWNED: ASSET.replace("\n", "\r\n").encode("utf-8")}), [FRESH_DONE])
tree("fresh-no-owned-file", "1", "0", "owned file missing", fresh(**{OWNED: None}), [FRESH_DONE])
tree("fresh-owned-differs", "1", "0", "owned file differs from the shipped asset",
     fresh(**{OWNED: ASSET.replace("Atomic", "atomic")}), [FRESH_DONE])
tree("fresh-no-claudemd", "1", "0", "CLAUDE.md missing", fresh(**{"CLAUDE.md": None}), [FRESH_DONE])
tree("fresh-doctrine-heading", "1", "0", "CLAUDE.md holds non-project heading(s): Development Workflow",
     fresh(**{"CLAUDE.md": CLAUDE_LEGACY}), [FRESH_DONE])
tree("fresh-covered-doctrine-row", "1", "0", "receipt `covered` holds doctrine row(s)",
     fresh(**{RECEIPT: receipt(COVERED_SPLIT + [u"CLAUDE.md \u00a7 Doc Sync"])}), [FRESH_DONE])
tree("fresh-covered-no-owned-row", "1", "0", "receipt `covered` lacks the .claude/rules/harness.md row",
     fresh(**{RECEIPT: receipt(COVERED_SPLIT[:-1])}), [FRESH_DONE])
tree("fresh-no-receipt", "1", "0", "receipt missing", fresh(**{RECEIPT: None}), [FRESH_DONE])
# today's shape, all three properties red at once (what the control is expected to read)
tree("fresh-control-shape", "1", "0", "owned file missing",
     {"CLAUDE.md": CLAUDE_LEGACY, RECEIPT: receipt([u"CLAUDE.md \u00a7 Development Workflow", u"CLAUDE.md \u00a7 Rules"])},
     [FRESH_DONE])

# --- legacy ------------------------------------------------------------------------
LM = {"start-head.txt": "aaaa1111\n", "end-head.txt": "aaaa1111\n", "git-status.txt": ""}


def lmeta(**over):
    m = dict(LM)
    m.update(over)
    return m


LFILES = {"CLAUDE.md": CLAUDE_LEGACY}
tree("legacy-ok", "1", "1", "ok", LFILES, ["Reading the repo.", LEGACY_STOP], lmeta())
tree("legacy-dirty-tree", "1", "0", "working tree not clean", LFILES, [LEGACY_STOP],
     lmeta(**{"git-status.txt": "?? .claude/bootstrap-sync-report.md\n M .claude/super-bootstrap-runway.json\n"}))
tree("legacy-head-moved", "1", "0", "HEAD moved", LFILES, [LEGACY_STOP], lmeta(**{"end-head.txt": "bbbb2222\n"}))
tree("legacy-no-file-name", "1", "0", "stop message does not name .claude/rules/harness.md", LFILES,
     ["Stopped, nothing written: this repo is in the pre-split shape."], lmeta())
tree("legacy-no-shape", "1", "0", "stop message does not state the pre-split shape", LFILES,
     ["Stopped. `.claude/rules/harness.md` is absent."], lmeta())
tree("legacy-did-not-stop", "1", "0", "stop message does not name", LFILES,
     ["**Pipeline synced.** 0 items updated, 23 already current."], lmeta())
tree("legacy-no-status-meta", "0", "-", "meta/git-status.txt missing", LFILES, [LEGACY_STOP],
     lmeta(**{"git-status.txt": None}))

# --- stale -------------------------------------------------------------------------
SM = {"harness.before.md": OLDER}
tree("stale-ok", "1", "1", "ok", {OWNED: ASSET}, [STALE_DONE], SM)
tree("stale-ok-unrelated-prompt", "1", "1", "ok", {OWNED: ASSET}, [UNRELATED_PROMPT], SM)
tree("stale-not-updated", "1", "0", "owned file differs from the shipped asset (still the older bytes)",
     {OWNED: OLDER}, ["**Pipeline synced.**"], SM)
tree("stale-prompted", "1", "0", "approval prompt for the owned file", {OWNED: ASSET}, [SECTION_PROMPT, STALE_DONE], SM)
tree("stale-fork-prompted", "1", "0", "approval prompt for the owned file", {OWNED: ASSET}, [FORK_ASK, STALE_DONE], SM)
# prompt-block scoping: a summary naming the owned file is not a prompt about it ...
tree("stale-ok-summary-fenced-prompt", "1", "1", "ok", {OWNED: ASSET}, [SUMMARY_THEN_FENCED_PROMPT], SM)
tree("stale-ok-summary-plain-prompt", "1", "1", "ok", {OWNED: ASSET}, [SUMMARY_THEN_PLAIN_PROMPT], SM)
tree("stale-ok-summary-labelled-prose", "1", "1", "ok", {OWNED: ASSET}, [SUMMARY_THEN_LABELLED_PROSE], SM)
# ... and a prompt that names it inside its own block still fails, fenced or under a label line
tree("stale-prompted-fenced", "1", "0", "approval prompt for the owned file", {OWNED: ASSET}, [FENCED_OWNED_PROMPT], SM)
tree("stale-fork-prompted-labelled", "1", "0", "approval prompt for the owned file", {OWNED: ASSET},
     [FORK_LABELLED_OWNED], SM)

# --- fork --------------------------------------------------------------------------
KM = {"harness.before.md": FORK}
tree("fork-ok", "1", "1", "ok", {OWNED: FORK}, [FORK_ASK], KM)
tree("fork-no-prompt", "1", "0", "no overwrite-or-keep choice naming .claude/rules/harness.md",
     {OWNED: FORK}, ["**Pipeline synced.** 0 items updated."], KM)
tree("fork-ok-labelled", "1", "1", "ok", {OWNED: FORK}, [FORK_LABELLED_OWNED], KM)
tree("fork-prompt-for-other-file", "1", "0", "no overwrite-or-keep choice naming .claude/rules/harness.md",
     {OWNED: FORK}, [FORK_LABELLED_OTHER], KM)
tree("fork-overwritten-untold", "1", "0", "owned file changed without an overwrite answer",
     {OWNED: ASSET}, [FORK_ASK], KM)
tree("fork-overwrite-ok", "1", "1", "ok", {OWNED: ASSET}, [FORK_ASK],
     dict(KM, **{"answer.txt": "overwrite\n"}), t2=[FORK_DONE_T2])
tree("fork-overwrite-not-applied", "1", "0", "told to overwrite, owned file differs from the shipped asset",
     {OWNED: FORK}, [FORK_ASK], dict(KM, **{"answer.txt": "overwrite\n"}), t2=[FORK_DONE_T2])
tree("fork-keep-ok", "1", "1", "ok", {OWNED: FORK}, [FORK_ASK],
     dict(KM, **{"answer.txt": "keep\n"}), t2=["`.claude/rules/harness.md` kept (fork)."])
tree("fork-keep-but-changed", "1", "0", "owned file changed without an overwrite answer (answer: keep)",
     {OWNED: ASSET}, [FORK_ASK], dict(KM, **{"answer.txt": "keep\n"}), t2=["kept (fork)."])

# --- invalid: never a pass, never a fail ---------------------------------------------
tree("fresh-errored", "0", "-", "run errored", fresh(), [FRESH_DONE], stream_kw={"error": True})
tree("fresh-no-result", "0", "-", "no result event", fresh(), [FRESH_DONE], stream_kw={"result": False})
tree("legacy-no-text", "0", "-", "no assistant text", LFILES, [], lmeta())
tree("stale-no-stream", "0", "-", "no stream", {OWNED: ASSET}, None, SM, no_stream=True)
tree("fresh-plugin-not-loaded", "0", "-", "dev plugin not loaded", fresh(), [FRESH_DONE], stream_kw={"plugins": "none"})
tree("fresh-plugin-from-cache", "0", "-", "not the dev copy", fresh(), [FRESH_DONE], stream_kw={"plugins": "cache"})

put(os.path.join(OUT, "asset", "harness.md"), ASSET)
put(os.path.join(OUT, "expected.tsv"), "".join("\t".join(c) + "\n" for c in sorted(CASES)))
print("%d trees -> %s" % (len(CASES), os.path.join(OUT, "trees")))
