#!/usr/bin/env python3
"""Mechanical half of /super-bootstrap:help — extract + group + render, zero model tokens.

Usage: python render-menu.py <project-root>

Reads ~/.claude/plugins/installed_plugins.json (skip silently if absent),
<project>/.claude/settings.json enabledPlugins, then each enabled plugin's skills
plus <project>/.claude/skills. Skill-set resolution order, per source:

1. Manifest — a plugin's <installPath>/.claude-plugin/plugin.json `skills` array
   is an allowlist; when present, resolve exactly those paths and no others
   (folders absent from it are never loaded by Claude Code).
2. Walk — no manifest file, or no `skills` key (and always for project
   .claude/skills, which has no manifest): recurse for SKILL.md under the skills
   root. A skill directory is one that CONTAINS SKILL.md, at any depth — plugins
   may group skills into category subfolders (skills/<category>/<name>/SKILL.md).

Frontmatter (name, description, tags) comes from each resolved SKILL.md.

Emits every discovered skill as a candidate row:  category<TAB>command<TAB>description
The user-invoke FILTER is deliberately NOT here — it is the one judgment in the
pipeline and stays with the gateway (see SKILL.md). This script over-reports;
the gateway cuts.

stdout carries candidate rows only. stderr carries the source diagnostics:

    # sources: <source> (<n> skills); ...          always, one line
    # anomalies: <source> — declared <d>, emitted <n>; ...   only when short

An anomaly means a source came back SHORT of its own branch's expectation —
discovery failed there, so a zero or a low count is not the truth about what
that source ships. `declared` names the manifest-allowlist expectation,
`discovered` the walked-tree one.
"""
import json, os, re, sys

# Callers read these streams as UTF-8. Redirected output otherwise encodes with the
# platform's ANSI codepage, which mangles punctuation and raises on anything outside
# its repertoire — descriptions come from third-party plugin frontmatter.
sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
sys.stderr.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]

project = sys.argv[1] if len(sys.argv) > 1 else "."
home = os.path.expanduser("~")

CAT_MAP = {  # tag -> coarse category (mirrors SKILL.md's grouping contract)
    "git": "git", "commit": "git", "merge": "git", "release": "git",
    "docs": "docs", "sync": "docs", "scaffold": "docs", "consistency": "docs",
    "pipeline": "pipeline", "todo": "pipeline", "triage": "pipeline", "cards": "pipeline",
    "log": "pipeline", "help": "pipeline", "drain": "pipeline",
    "meta": "meta", "bootstrap": "meta", "harness": "meta", "resolve": "meta",
    "audit": "meta", "axioms": "meta", "canon": "meta",
    "dev": "dev", "debug": "dev", "test": "dev",
}
CAT_ORDER = ["meta", "pipeline", "git", "docs", "dev", "utils"]


def unquote(value):
    """Strip a scalar's matched outer quotes. `''` is the only escape YAML defines
    inside a single-quoted scalar; doubled inside a plain or double-quoted one it is
    literal, so the unescape rides the quote style — knowable only here."""
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
        inner = value[1:-1]
        return inner.replace("''", "'") if value[0] == "'" else inner
    return value


def frontmatter(path):
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read()
    except OSError:
        return None
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    if not m:
        return None
    fm = {}
    for line in m.group(1).splitlines():
        kv = re.match(r"^([\w-]+):\s*(.*)$", line)
        if kv:
            fm[kv.group(1)] = unquote(kv.group(2).strip())
    return fm


def declared_skill_dirs(install_path):
    """A plugin manifest's `skills` array is an ALLOWLIST — Claude Code loads exactly
    those paths, so a folder absent from it never loads and must never reach the menu.
    Returns None when the plugin declares no array; the caller then walks."""
    try:
        with open(os.path.join(install_path, ".claude-plugin/plugin.json"), encoding="utf-8") as f:
            declared = json.load(f).get("skills")
    except (OSError, ValueError):
        return None
    if not isinstance(declared, list):
        return None
    return [os.path.normpath(os.path.join(install_path, p)) for p in declared]


def walk_skill_dirs(skills_dir):
    """Identify a skill directory by CONTAINING SKILL.md, not by its depth — plugins
    may group skills into category subfolders. A skill owns its subtree, so stop
    descending at one (a nested SKILL.md is a skill's own asset, not a sibling skill)."""
    found = []
    for dirpath, dirnames, filenames in os.walk(skills_dir):
        if "SKILL.md" in filenames:
            found.append(dirpath)
            dirnames[:] = []
    return sorted(found)


def emit(rows, plugin_name, skills_dir, prefix=True, allowlist=None):
    """Returns (emitted, expected). `expected` is the branch's OWN expectation —
    the allowlist's length, or the count of SKILL.md dirs the walk found — carried
    out because this is the only place it is known; a caller comparing an emitted
    count against anything else (the tree behind an allowlist) false-flags."""
    targets = walk_skill_dirs(skills_dir) if allowlist is None else allowlist
    n = 0
    for skill_dir in targets:
        fm = frontmatter(os.path.join(skill_dir, "SKILL.md"))
        if not fm or "description" not in fm:  # unreadable path, or no description
            continue
        name = fm.get("name", os.path.basename(skill_dir))
        cmd = (f"/{plugin_name}:{name}" if prefix and plugin_name != name
               else f"/{plugin_name}" if prefix else f"/{name}")
        tags = re.findall(r"[\w-]+", fm.get("tags", ""))
        cat = next((CAT_MAP[t] for t in tags if t in CAT_MAP), "utils")
        desc = fm["description"].split(". ")[0][:120]
        rows.append((cat, cmd, desc))
        n += 1
    return n, len(targets)


def anomaly_note(source, n, expected, skills_dir, allowlist):
    """A source is anomalous when it comes back short of ITS OWN branch's
    expectation — never of the tree. Returns the stderr note, or None.

    Allowlist branch: a declared path that failed to resolve. A manifest that
    legitimately declares fewer skills than the tree holds is not short.
    Walk branch: the skills dir exists yet emitted less than it discovered — or
    emitted nothing at all, which a bare zero cannot distinguish from a plugin
    that genuinely ships no skills. An absent dir stays a truthful zero."""
    if allowlist is not None:
        return f"{source} — declared {expected}, emitted {n}" if n < expected else None
    if os.path.isdir(skills_dir) and (n == 0 or n < expected):
        return f"{source} — discovered {expected}, emitted {n}"
    return None


rows, sources, anomalies = [], [], []
reg_path = os.path.join(home, ".claude/plugins/installed_plugins.json")
enabled = {}
for scope in (os.path.join(home, ".claude/settings.json"),          # user scope first,
              os.path.join(project, ".claude/settings.json")):      # project overrides on conflict
    if os.path.isfile(scope):
        enabled.update(json.load(open(scope, encoding="utf-8")).get("enabledPlugins", {}))
if os.path.isfile(reg_path):
    registry = json.load(open(reg_path, encoding="utf-8"))
    for plugin_key, installs in registry.get("plugins", {}).items():
        if not enabled.get(plugin_key):
            continue
        plugin_name = plugin_key.split("@")[0]
        install_path = installs[0]["installPath"]
        skills_dir = os.path.join(install_path, "skills")
        allowlist = declared_skill_dirs(install_path)
        n, expected = emit(rows, plugin_name, skills_dir, allowlist=allowlist)
        sources.append(f"{plugin_key} ({n} skills)")
        note = anomaly_note(plugin_key, n, expected, skills_dir, allowlist)
        if note:
            anomalies.append(note)

# An existing project skills dir is listed at any count — a zero it emitted is
# itself the signal the anomaly predicate reads; only an absent dir is silent.
proj_skills = os.path.join(project, ".claude/skills")
n, expected = emit(rows, "", proj_skills, prefix=False)
if os.path.isdir(proj_skills):
    sources.append(f"project .claude/skills ({n} skills)")
    note = anomaly_note("project .claude/skills", n, expected, proj_skills, None)
    if note:
        anomalies.append(note)

for cat in CAT_ORDER:
    for c, cmd, desc in rows:
        if c == cat:
            print(f"{c}\t{cmd}\t{desc}")
print(f"# sources: {'; '.join(sources)}", file=sys.stderr)
if anomalies:
    print(f"# anomalies: {'; '.join(anomalies)}", file=sys.stderr)
