#!/usr/bin/env python3
"""Mechanical half of /super-bootstrap:help — extract + group + render, zero model tokens.

Usage: python render-menu.py <project-root>

Reads ~/.claude/plugins/installed_plugins.json (skip silently if absent),
<project>/.claude/settings.json enabledPlugins, each enabled plugin's
skills/*/SKILL.md frontmatter, and <project>/.claude/skills/*/SKILL.md.

Emits every discovered skill as a candidate row:  category<TAB>command<TAB>description
The user-invoke FILTER is deliberately NOT here — it is the one judgment in the
pipeline and stays with the gateway (see SKILL.md). This script over-reports;
the gateway cuts.
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
            fm[kv.group(1)] = kv.group(2).strip().strip('"')
    return fm


def emit(rows, plugin_name, skills_dir, prefix=True):
    n = 0
    if not os.path.isdir(skills_dir):
        return 0
    for skill in sorted(os.listdir(skills_dir)):
        fm = frontmatter(os.path.join(skills_dir, skill, "SKILL.md"))
        if not fm or "description" not in fm:
            continue
        name = fm.get("name", skill)
        cmd = (f"/{plugin_name}:{name}" if prefix and plugin_name != name
               else f"/{plugin_name}" if prefix else f"/{name}")
        tags = re.findall(r"[\w-]+", fm.get("tags", ""))
        cat = next((CAT_MAP[t] for t in tags if t in CAT_MAP), "utils")
        desc = fm["description"].split(". ")[0][:120].strip("'\"")
        rows.append((cat, cmd, desc))
        n += 1
    return n


rows, sources = [], []
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
        n = emit(rows, plugin_name, os.path.join(installs[0]["installPath"], "skills"))
        sources.append(f"{plugin_key} ({n} skills)")

n = emit(rows, "", os.path.join(project, ".claude/skills"), prefix=False)
if n:
    sources.append(f"project .claude/skills ({n} skills)")

for cat in CAT_ORDER:
    for c, cmd, desc in rows:
        if c == cat:
            print(f"{c}\t{cmd}\t{desc}")
print(f"# sources: {'; '.join(sources)}", file=sys.stderr)
